/**
 * Livestream routes — industry-grade Mux integration
 *
 * POST   /api/livestreams              — create Mux stream, save to DB
 * GET    /api/livestreams              — list active streams
 * GET    /api/livestreams/:id          — single stream
 * DELETE /api/livestreams/:id          — end stream
 * GET    /api/livestreams/replays/:uid — user's past streams (VOD)
 * POST   /api/mux-webhook             — Mux event webhook
 */

const express = require('express');
const Mux = require('@mux/mux-node');
const pool = require('../db');

const router = express.Router();

// ── Mux client ───────────────────────────────────────────────────
const muxClient = new Mux({
    tokenId: process.env.MUX_TOKEN_ID,
    tokenSecret: process.env.MUX_TOKEN_SECRET,
});

const RTMP_BASE_URL = 'rtmps://global-live.mux.com:443/app';

// Mux HLS playback base
const hlsUrl = (playbackId) =>
    `https://stream.mux.com/${playbackId}.m3u8`;

// ── POST /api/livestreams ────────────────────────────────────────
router.post('/', async (req, res) => {
    try {
        const { userId, title } = req.body;
        if (!userId || !title) {
            return res.status(400).json({ error: 'userId and title are required' });
        }

        // 1. Create Mux Live Stream
        const liveStream = await muxClient.video.liveStreams.create({
            playbackPolicy: ['public'],
            reducedLatency: true,          // Low-latency HLS (~2–3 s)
            reconnectWindow: 60,           // Allow 60s reconnect before ending
            newAssetSettings: {
                playbackPolicy: ['public'], // Auto-save replay as public VOD
            },
        });

        const muxStreamId = liveStream.id;
        const muxPlaybackId = liveStream.playbackIds?.[0]?.id || '';
        const streamKey = liveStream.streamKey;
        const playbackUrl = muxPlaybackId ? hlsUrl(muxPlaybackId) : '';

        // 2. Save to DB
        const result = await pool.query(
            `INSERT INTO livestreams
        (host_id, title, mux_stream_id, mux_playback_id, stream_key, playback_url, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'idle')
       RETURNING *`,
            [userId, title, muxStreamId, muxPlaybackId, streamKey, playbackUrl]
        );

        const row = result.rows[0];

        res.status(201).json({
            id: row.id,
            title: row.title,
            hostId: userId,
            muxStreamId,
            muxPlaybackId,
            streamKey,
            rtmpUrl: RTMP_BASE_URL,
            playbackUrl,
            status: row.status,
        });
    } catch (err) {
        console.error('Create livestream error:', err.message);
        res.status(500).json({ error: 'Failed to create stream', detail: err.message });
    }
});

// ── GET /api/livestreams ─────────────────────────────────────────
router.get('/', async (_req, res) => {
    try {
        const result = await pool.query(
            `SELECT l.*, u.username AS host_username, u.display_name AS host_display_name,
              u.photo_url AS host_photo_url
       FROM livestreams l
       JOIN users u ON u.id = l.host_id
       WHERE l.status = 'active'
       ORDER BY l.started_at DESC`
        );
        res.json(result.rows.map(mapLivestream));
    } catch (err) {
        console.error('List livestreams error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// ── GET /api/livestreams/:id ─────────────────────────────────────
router.get('/:id', async (req, res) => {
    // Avoid matching '/replays/:uid' route — handled separately above
    if (req.params.id === 'replays') return res.status(404).end();

    try {
        const result = await pool.query(
            `SELECT l.*, u.username AS host_username, u.display_name AS host_display_name,
              u.photo_url AS host_photo_url
       FROM livestreams l
       JOIN users u ON u.id = l.host_id
       WHERE l.id = $1`,
            [req.params.id]
        );
        if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
        res.json(mapLivestream(result.rows[0]));
    } catch (err) {
        res.status(500).json({ error: 'Server error' });
    }
});

// ── GET /api/livestreams/replays/:userId ─────────────────────────
router.get('/replays/:userId', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT l.*, u.username AS host_username, u.photo_url AS host_photo_url
       FROM livestreams l
       JOIN users u ON u.id = l.host_id
       WHERE l.host_id = $1 AND l.status = 'ended'
       ORDER BY l.started_at DESC
       LIMIT 30`,
            [req.params.userId]
        );
        res.json(result.rows.map(mapLivestream));
    } catch (err) {
        res.status(500).json({ error: 'Server error' });
    }
});

// ── DELETE /api/livestreams/:id  (End stream) ────────────────────
router.delete('/:id', async (req, res) => {
    try {
        // Get the mux_stream_id
        const row = await pool.query(
            'SELECT mux_stream_id FROM livestreams WHERE id = $1',
            [req.params.id]
        );
        if (row.rows.length === 0) return res.status(404).json({ error: 'Not found' });

        const muxStreamId = row.rows[0].mux_stream_id;

        // Disable Mux stream
        if (muxStreamId) {
            try {
                await muxClient.video.liveStreams.disable(muxStreamId);
            } catch (muxErr) {
                console.warn('Mux disable error (non-fatal):', muxErr.message);
            }
        }

        // Update DB
        await pool.query(
            `UPDATE livestreams
       SET status = 'ended', ended_at = NOW()
       WHERE id = $1`,
            [req.params.id]
        );

        res.json({ success: true });
    } catch (err) {
        console.error('End livestream error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// ── POST /api/mux-webhook ────────────────────────────────────────
// Mux calls this when stream goes live / ends / replay is ready.
// Set up in Mux dashboard: https://dashboard.mux.com/settings/webhooks
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
    try {
        const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
        const { type, data } = body;

        console.log('📡 Mux webhook:', type);

        switch (type) {
            case 'video.live_stream.active':
                // Stream went live — mark active, update viewer count
                await pool.query(
                    `UPDATE livestreams SET status = 'active', started_at = COALESCE(started_at, NOW())
           WHERE mux_stream_id = $1`,
                    [data.id]
                );
                break;

            case 'video.live_stream.idle':
                // Stream paused / reconnecting
                await pool.query(
                    `UPDATE livestreams SET status = 'idle'
           WHERE mux_stream_id = $1`,
                    [data.id]
                );
                break;

            case 'video.live_stream.disconnected':
                // Broadcaster disconnected
                await pool.query(
                    `UPDATE livestreams SET status = 'ended', ended_at = NOW()
           WHERE mux_stream_id = $1`,
                    [data.id]
                );
                break;

            case 'video.asset.ready': {
                // Replay VOD is ready — attach playback URL to the stream record
                const assetPlaybackId = data.playback_ids?.[0]?.id;
                if (assetPlaybackId && data.live_stream_id) {
                    await pool.query(
                        `UPDATE livestreams
             SET replay_playback_url = $1
             WHERE mux_stream_id = $2`,
                        [`https://stream.mux.com/${assetPlaybackId}.m3u8`, data.live_stream_id]
                    );
                }
                break;
            }
        }

        res.sendStatus(200);
    } catch (err) {
        console.error('Webhook error:', err.message);
        res.sendStatus(500);
    }
});

// ── Mapper ───────────────────────────────────────────────────────
function mapLivestream(row) {
    return {
        id: row.id,
        hostId: row.host_id,
        hostUsername: row.host_username || '',
        hostPhotoUrl: row.host_photo_url || '',
        title: row.title,
        muxStreamId: row.mux_stream_id || '',
        muxPlaybackId: row.mux_playback_id || '',
        streamKey: row.stream_key || '',
        rtmpUrl: RTMP_BASE_URL,
        playbackUrl: row.playback_url || '',
        replayPlaybackUrl: row.replay_playback_url || '',
        status: row.status || 'idle',
        viewerCount: row.viewer_count || 0,
        peakViewers: row.peak_viewers || 0,
        startedAt: row.started_at,
        endedAt: row.ended_at || null,
    };
}

module.exports = router;
module.exports.muxClient = muxClient;

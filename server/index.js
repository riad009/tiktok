require('dotenv').config(); // MUST be first — env vars needed by Mux client in routes
const express = require('express');
const http = require('http');
const path = require('path');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const { v4: uuid } = require('uuid');
const { Server: SocketServer } = require('socket.io');
const Redis = require('ioredis');
const pool = require('./db');
const livestreamRouter = require('./routes/livestream');

const app = express();
const httpServer = http.createServer(app);

// ── CORS ─────────────────────────────────────────────────────────
app.use(cors({ origin: '*', methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'] }));
app.use(express.json({ limit: '50mb' }));

// ── Redis (viewer counts & pub/sub) ──────────────────────────────
const redis = process.env.REDIS_URL
    ? new Redis(process.env.REDIS_URL)
    : new Redis({ host: '127.0.0.1', port: 6379, lazyConnect: true });
redis.on('error', (e) => console.warn('Redis unavailable (non-fatal):', e.message));

// ── Socket.io ────────────────────────────────────────────────────
const io = new SocketServer(httpServer, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
    transports: ['websocket', 'polling'],
});
app.set('io', io); // expose to routes via req.app.get('io')

io.on('connection', (socket) => {
    // join a stream room
    socket.on('join_stream', async ({ streamId, username }) => {
        socket.join(streamId);
        socket.data.streamId = streamId;
        socket.data.username = username;
        // Increment viewer count in Redis
        const count = await redis.incr(`viewers:${streamId}`).catch(() => 0);
        io.to(streamId).emit('viewer_count', count);
        // Also persist to DB (non-blocking)
        pool.query(
            'UPDATE livestreams SET viewer_count = $1, peak_viewers = GREATEST(peak_viewers, $1) WHERE id = $2',
            [count, streamId]
        ).catch(() => { });
    });

    socket.on('leave_stream', async () => {
        const { streamId } = socket.data;
        if (!streamId) return;
        const count = Math.max(0, await redis.decr(`viewers:${streamId}`).catch(() => 0));
        io.to(streamId).emit('viewer_count', count);
        pool.query(
            'UPDATE livestreams SET viewer_count = $1 WHERE id = $2',
            [count, streamId]
        ).catch(() => { });
        socket.leave(streamId);
    });

    socket.on('disconnect', async () => {
        const { streamId, username } = socket.data;
        if (!streamId) return;
        const count = Math.max(0, await redis.decr(`viewers:${streamId}`).catch(() => 0));
        io.to(streamId).emit('viewer_count', count);
        pool.query(
            'UPDATE livestreams SET viewer_count = $1 WHERE id = $2',
            [count, streamId]
        ).catch(() => { });
    });

    // Live chat message broadcast
    socket.on('chat_message', ({ streamId, username, text, photoUrl }) => {
        io.to(streamId).emit('chat_message', {
            id: uuid(),
            username,
            text,
            photoUrl: photoUrl || '',
            timestamp: new Date().toISOString(),
        });
    });

    // Emoji reaction
    socket.on('reaction', ({ streamId, emoji, username }) => {
        io.to(streamId).emit('reaction', { emoji, username });
    });
});

// ── Livestream routes ─────────────────────────────────────────────
// Webhook needs raw body, must come before json middleware for that path
app.post('/api/mux-webhook', express.raw({ type: 'application/json' }), (req, res, next) => {
    req.body = req.body.toString();
    next();
}, (req, res) => {
    const router = require('./routes/livestream');
    // Forward to webhook handler in router
    require('./routes/livestream').handle?.(req, res);
});
app.use('/api/livestreams', livestreamRouter);

// ─── Health check ────────────────────────────────────────────────
app.get('/api/health', (_, res) => res.json({ status: 'ok', socketIo: true }));

// ─── MUSIC SEARCH (Deezer proxy to avoid CORS) ──────────────────
app.get('/api/music/search', async (req, res) => {
    try {
        const q = req.query.q || '';
        if (!q.trim()) return res.json({ data: [] });
        const url = `https://api.deezer.com/search?q=${encodeURIComponent(q.trim())}&limit=30`;
        const response = await fetch(url);
        const data = await response.json();
        res.json(data);
    } catch (err) {
        console.error('Music search error:', err.message);
        res.status(500).json({ error: 'Music search failed', data: [] });
    }
});

// ─── AUTH ────────────────────────────────────────────────────────

// POST /api/auth/signup
app.post('/api/auth/signup', async (req, res) => {
    try {
        const { username, displayName, email, password } = req.body;
        if (!username || !email || !password) {
            return res.status(400).json({ error: 'username, email, and password are required' });
        }

        const dup = await pool.query(
            'SELECT id FROM users WHERE email = $1 OR username = $2', [email, username.toLowerCase()]
        );
        if (dup.rows.length > 0) {
            return res.status(409).json({ error: 'Email or username already taken' });
        }

        const id = uuid();
        const hash = await bcrypt.hash(password, 10);
        const result = await pool.query(
            `INSERT INTO users (id, username, display_name, email, password_hash, photo_url)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, username, display_name, email, photo_url, bio, role, is_verified,
                 followers_count, following_count, posts_count, created_at`,
            [id, username.toLowerCase(), displayName || username, email, hash,
                `https://i.pravatar.cc/150?u=${username}`]
        );

        res.status(201).json(mapUser(result.rows[0]));
    } catch (err) {
        console.error('Signup error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// POST /api/auth/login
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ error: 'email and password are required' });
        }

        const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const user = result.rows[0];
        const valid = await bcrypt.compare(password, user.password_hash);
        if (!valid) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        res.json(mapUser(user));
    } catch (err) {
        console.error('Login error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// ─── USERS ───────────────────────────────────────────────────────

app.get('/api/users', async (_, res) => {
    try {
        const result = await pool.query(
            `SELECT id, username, display_name, email, photo_url, bio, role, is_verified,
              followers_count, following_count, posts_count, created_at
       FROM users ORDER BY created_at DESC`
        );
        res.json(result.rows.map(mapUser));
    } catch (err) {
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/users/:id', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, username, display_name, email, photo_url, bio, role, is_verified,
              followers_count, following_count, posts_count, created_at
       FROM users WHERE id = $1`, [req.params.id]
        );
        if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
        res.json(mapUser(result.rows[0]));
    } catch (err) {
        res.status(500).json({ error: 'Server error' });
    }
});

// ─── FEED / POSTS ────────────────────────────────────────────────

// GET /api/feed
app.get('/api/feed', async (_, res) => {
    try {
        const result = await pool.query(
            `SELECT p.*, u.username, u.display_name, u.photo_url AS user_photo_url
       FROM posts p JOIN users u ON p.user_id = u.id
       ORDER BY p.created_at DESC LIMIT 50`
        );
        res.json(result.rows.map(mapPost));
    } catch (err) {
        console.error('Feed error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// POST /api/posts
app.post('/api/posts', async (req, res) => {
    try {
        const { userId, caption, videoUrl, thumbnailUrl, imageUrl, hashtags, musicTitle, musicArtist, musicCoverUrl, musicPreviewUrl } = req.body;
        if (!userId) return res.status(400).json({ error: 'userId is required' });

        const id = uuid();
        const result = await pool.query(
            `INSERT INTO posts (id, user_id, caption, video_url, thumbnail_url, image_url, hashtags, music_title, music_artist, music_cover_url, music_preview_url)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING *`,
            [id, userId, caption || '', videoUrl || '', thumbnailUrl || '', imageUrl || '', hashtags || [], musicTitle || '', musicArtist || '', musicCoverUrl || '', musicPreviewUrl || '']
        );

        // increment user's post count
        await pool.query('UPDATE users SET posts_count = posts_count + 1 WHERE id = $1', [userId]);

        // fetch with user info
        const full = await pool.query(
            `SELECT p.*, u.username, u.display_name, u.photo_url AS user_photo_url
       FROM posts p JOIN users u ON p.user_id = u.id WHERE p.id = $1`, [id]
        );
        res.status(201).json(mapPost(full.rows[0]));
    } catch (err) {
        console.error('Create post error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// ─── COMMENTS ────────────────────────────────────────────────────

// GET /api/comments/:postId
app.get('/api/comments/:postId', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT c.*, u.username, u.photo_url AS user_photo_url
       FROM comments c JOIN users u ON c.user_id = u.id
       WHERE c.post_id = $1 ORDER BY c.created_at ASC`,
            [req.params.postId]
        );
        res.json(result.rows.map(mapComment));
    } catch (err) {
        console.error('Comments error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// POST /api/comments
app.post('/api/comments', async (req, res) => {
    try {
        const { postId, userId, text } = req.body;
        if (!postId || !userId || !text) {
            return res.status(400).json({ error: 'postId, userId, and text are required' });
        }

        const id = uuid();
        await pool.query(
            'INSERT INTO comments (id, post_id, user_id, text) VALUES ($1, $2, $3, $4)',
            [id, postId, userId, text]
        );

        // increment post comment count
        await pool.query('UPDATE posts SET comments_count = comments_count + 1 WHERE id = $1', [postId]);

        const result = await pool.query(
            `SELECT c.*, u.username, u.photo_url AS user_photo_url
       FROM comments c JOIN users u ON c.user_id = u.id WHERE c.id = $1`, [id]
        );
        res.status(201).json(mapComment(result.rows[0]));
    } catch (err) {
        console.error('Add comment error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// ─── LIKES ───────────────────────────────────────────────────────

// POST /api/likes
app.post('/api/likes', async (req, res) => {
    try {
        const { postId, userId } = req.body;
        if (!postId || !userId) return res.status(400).json({ error: 'postId and userId required' });

        // Check if already liked
        const existing = await pool.query(
            'SELECT id FROM likes WHERE post_id = $1 AND user_id = $2', [postId, userId]
        );
        if (existing.rows.length > 0) {
            return res.json({ liked: true });
        }

        const id = uuid();
        await pool.query('INSERT INTO likes (id, post_id, user_id) VALUES ($1, $2, $3)', [id, postId, userId]);
        await pool.query('UPDATE posts SET likes_count = likes_count + 1 WHERE id = $1', [postId]);
        res.status(201).json({ liked: true });
    } catch (err) {
        console.error('Like error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// DELETE /api/likes
app.delete('/api/likes', async (req, res) => {
    try {
        const { postId, userId } = req.body;
        if (!postId || !userId) return res.status(400).json({ error: 'postId and userId required' });

        const result = await pool.query(
            'DELETE FROM likes WHERE post_id = $1 AND user_id = $2 RETURNING id', [postId, userId]
        );
        if (result.rows.length > 0) {
            await pool.query('UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = $1', [postId]);
        }
        res.json({ liked: false });
    } catch (err) {
        console.error('Unlike error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/likes/check/:postId/:userId
app.get('/api/likes/check/:postId/:userId', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT id FROM likes WHERE post_id = $1 AND user_id = $2',
            [req.params.postId, req.params.userId]
        );
        res.json({ liked: result.rows.length > 0 });
    } catch (err) {
        res.status(500).json({ error: 'Server error' });
    }
});

// ─── CONVERSATIONS ───────────────────────────────────────────────

app.get('/api/conversations/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const isGroup = req.query.group === 'true';

        if (isGroup) {
            // Return group conversations
            const result = await pool.query(
                `SELECT c.*
           FROM conversations c
           JOIN conversation_participants cp ON c.id = cp.conversation_id AND cp.user_id = $1
           WHERE c.is_group = true
           ORDER BY c.last_message_time DESC`,
                [userId]
            );
            // For each group, fetch participants
            const groups = [];
            for (const row of result.rows) {
                const pResult = await pool.query(
                    `SELECT u.id, u.username, u.display_name, u.photo_url
               FROM conversation_participants cp
               JOIN users u ON cp.user_id = u.id
               WHERE cp.conversation_id = $1`,
                    [row.id]
                );
                groups.push(mapGroupConversation(row, pResult.rows));
            }
            return res.json(groups);
        }

        // Return direct (1:1) conversations
        const result = await pool.query(
            `SELECT c.*, cp2.user_id AS other_user_id,
              u.username AS other_username, u.display_name AS other_display_name,
              u.photo_url AS other_photo_url
       FROM conversations c
       JOIN conversation_participants cp1 ON c.id = cp1.conversation_id AND cp1.user_id = $1
       JOIN conversation_participants cp2 ON c.id = cp2.conversation_id AND cp2.user_id != $1
       JOIN users u ON cp2.user_id = u.id
       WHERE (c.is_group = false OR c.is_group IS NULL)
       ORDER BY c.last_message_time DESC`,
            [userId]
        );
        res.json(result.rows.map(mapConversation));
    } catch (err) {
        console.error('Conversations error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// Create 1:1 conversation
app.post('/api/conversations', async (req, res) => {
    try {
        const { userId1, userId2 } = req.body;
        if (!userId1 || !userId2) return res.status(400).json({ error: 'userId1 and userId2 are required' });

        // Only check non-group conversations
        const existing = await pool.query(
            `SELECT cp1.conversation_id FROM conversation_participants cp1
       JOIN conversation_participants cp2 ON cp1.conversation_id = cp2.conversation_id
       JOIN conversations c ON c.id = cp1.conversation_id
       WHERE cp1.user_id = $1 AND cp2.user_id = $2 AND (c.is_group = false OR c.is_group IS NULL)`,
            [userId1, userId2]
        );

        if (existing.rows.length > 0) {
            const convoId = existing.rows[0].conversation_id;
            const conv = await pool.query(
                `SELECT c.*, cp2.user_id AS other_user_id,
                u.username AS other_username, u.display_name AS other_display_name,
                u.photo_url AS other_photo_url
         FROM conversations c
         JOIN conversation_participants cp1 ON c.id = cp1.conversation_id AND cp1.user_id = $1
         JOIN conversation_participants cp2 ON c.id = cp2.conversation_id AND cp2.user_id != $1
         JOIN users u ON cp2.user_id = u.id
         WHERE c.id = $2`,
                [userId1, convoId]
            );
            return res.json(mapConversation(conv.rows[0]));
        }

        const convoId = uuid();
        await pool.query('INSERT INTO conversations (id, is_group) VALUES ($1, false)', [convoId]);
        await pool.query(
            'INSERT INTO conversation_participants (conversation_id, user_id) VALUES ($1, $2), ($1, $3)',
            [convoId, userId1, userId2]
        );

        const conv = await pool.query(
            `SELECT c.*, cp2.user_id AS other_user_id,
              u.username AS other_username, u.display_name AS other_display_name,
              u.photo_url AS other_photo_url
       FROM conversations c
       JOIN conversation_participants cp1 ON c.id = cp1.conversation_id AND cp1.user_id = $1
       JOIN conversation_participants cp2 ON c.id = cp2.conversation_id AND cp2.user_id != $1
       JOIN users u ON cp2.user_id = u.id
       WHERE c.id = $2`,
            [userId1, convoId]
        );
        res.status(201).json(mapConversation(conv.rows[0]));
    } catch (err) {
        console.error('Create conversation error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// Create group conversation
app.post('/api/conversations/group', async (req, res) => {
    try {
        const { creatorId, groupName, memberIds } = req.body;
        if (!creatorId || !memberIds || !Array.isArray(memberIds) || memberIds.length === 0) {
            return res.status(400).json({ error: 'creatorId and memberIds[] are required' });
        }

        const convoId = uuid();
        const name = (groupName || '').trim() || 'New Group';

        await pool.query(
            `INSERT INTO conversations (id, is_group, group_name, created_by)
       VALUES ($1, true, $2, $3)`,
            [convoId, name, creatorId]
        );

        // Add creator + all selected members
        const allMembers = [creatorId, ...memberIds.filter(id => id !== creatorId)];
        for (const memberId of allMembers) {
            await pool.query(
                'INSERT INTO conversation_participants (conversation_id, user_id) VALUES ($1, $2)',
                [convoId, memberId]
            );
        }

        // Fetch the group with participants
        const convRow = await pool.query('SELECT * FROM conversations WHERE id = $1', [convoId]);
        const pResult = await pool.query(
            `SELECT u.id, u.username, u.display_name, u.photo_url
       FROM conversation_participants cp
       JOIN users u ON cp.user_id = u.id
       WHERE cp.conversation_id = $1`,
            [convoId]
        );

        res.status(201).json(mapGroupConversation(convRow.rows[0], pResult.rows));
    } catch (err) {
        console.error('Create group error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// ─── MESSAGES ────────────────────────────────────────────────────

app.get('/api/messages/:conversationId', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT m.*, u.username AS sender_username
       FROM messages m JOIN users u ON m.sender_id = u.id
       WHERE m.conversation_id = $1 ORDER BY m.created_at ASC`,
            [req.params.conversationId]
        );
        res.json(result.rows.map(mapMessage));
    } catch (err) {
        console.error('Messages error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

app.post('/api/messages', async (req, res) => {
    try {
        const { conversationId, senderId, text } = req.body;
        if (!conversationId || !senderId || !text) {
            return res.status(400).json({ error: 'conversationId, senderId, and text are required' });
        }

        const id = uuid();
        await pool.query(
            'INSERT INTO messages (id, conversation_id, sender_id, text) VALUES ($1, $2, $3, $4)',
            [id, conversationId, senderId, text]
        );

        await pool.query(
            'UPDATE conversations SET last_message = $1, last_message_time = NOW() WHERE id = $2',
            [text, conversationId]
        );

        const result = await pool.query(
            `SELECT m.*, u.username AS sender_username
       FROM messages m JOIN users u ON m.sender_id = u.id WHERE m.id = $1`, [id]
        );
        res.status(201).json(mapMessage(result.rows[0]));
    } catch (err) {
        console.error('Send message error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// ─── ADMIN ───────────────────────────────────────────────────────

// GET /api/admin/stats
app.get('/api/admin/stats', async (req, res) => {
    try {
        const users = await pool.query('SELECT COUNT(*) FROM users');
        const posts = await pool.query('SELECT COUNT(*) FROM posts');
        const pendingReports = await pool.query("SELECT COUNT(*) FROM reports WHERE status = 'pending'");
        let livestreams = { rows: [{ count: '0' }] };
        try { livestreams = await pool.query('SELECT COUNT(*) FROM livestreams'); } catch (_) { }
        res.json({
            totalUsers: parseInt(users.rows[0].count),
            totalVideos: parseInt(posts.rows[0].count),
            totalLivestreams: parseInt(livestreams.rows[0].count),
            pendingReports: parseInt(pendingReports.rows[0].count),
        });
    } catch (err) {
        console.error('Admin stats error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// PUT /api/admin/users/:id/ban
app.put('/api/admin/users/:id/ban', async (req, res) => {
    try {
        const { banned } = req.body;
        await pool.query('UPDATE users SET is_banned = $1 WHERE id = $2', [banned, req.params.id]);
        res.json({ success: true });
    } catch (err) {
        console.error('Ban user error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// PUT /api/admin/users/:id/verify
app.put('/api/admin/users/:id/verify', async (req, res) => {
    try {
        const { verified } = req.body;
        await pool.query('UPDATE users SET is_verified = $1 WHERE id = $2', [verified, req.params.id]);
        res.json({ success: true });
    } catch (err) {
        console.error('Verify user error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// PUT /api/admin/users/:id/role
app.put('/api/admin/users/:id/role', async (req, res) => {
    try {
        const { role } = req.body;
        await pool.query('UPDATE users SET role = $1 WHERE id = $2', [role, req.params.id]);
        res.json({ success: true });
    } catch (err) {
        console.error('Update role error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// DELETE /api/admin/posts/:id
app.delete('/api/admin/posts/:id', async (req, res) => {
    try {
        const postId = req.params.id;
        const post = await pool.query('SELECT user_id FROM posts WHERE id = $1', [postId]);
        if (post.rows.length > 0) {
            await pool.query('UPDATE users SET posts_count = GREATEST(posts_count - 1, 0) WHERE id = $1', [post.rows[0].user_id]);
        }
        await pool.query('DELETE FROM posts WHERE id = $1', [postId]);
        res.json({ success: true });
    } catch (err) {
        console.error('Delete post error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/admin/reports
app.get('/api/admin/reports', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT r.*, u.username AS reporter_uname
       FROM reports r LEFT JOIN users u ON r.reporter_id = u.id
       ORDER BY r.created_at DESC`
        );
        res.json(result.rows.map(mapReport));
    } catch (err) {
        console.error('Get reports error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// POST /api/admin/reports
app.post('/api/admin/reports', async (req, res) => {
    try {
        const { reporterId, targetId, targetType, reason, details } = req.body;
        if (!reporterId || !targetId || !reason) {
            return res.status(400).json({ error: 'reporterId, targetId, and reason are required' });
        }
        const id = uuid();
        await pool.query(
            `INSERT INTO reports (id, reporter_id, target_id, target_type, reason, details)
       VALUES ($1, $2, $3, $4, $5, $6)`,
            [id, reporterId, targetId, targetType || 'user', reason, details || '']
        );
        res.status(201).json({ id, success: true });
    } catch (err) {
        console.error('Create report error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// PUT /api/admin/reports/:id
app.put('/api/admin/reports/:id', async (req, res) => {
    try {
        const { status, resolvedBy } = req.body;
        await pool.query(
            `UPDATE reports SET status = $1, resolved_at = NOW(), resolved_by = $2 WHERE id = $3`,
            [status, resolvedBy || '', req.params.id]
        );
        res.json({ success: true });
    } catch (err) {
        console.error('Resolve report error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// ─── MAPPERS ─────────────────────────────────────────────────────

function mapReport(row) {
    return {
        id: row.id,
        reporterId: row.reporter_id,
        reporterUsername: row.reporter_uname || row.reporter_username || '',
        targetId: row.target_id,
        targetType: row.target_type || 'user',
        reason: row.reason || '',
        details: row.details || '',
        status: row.status || 'pending',
        createdAt: row.created_at,
        resolvedAt: row.resolved_at,
        resolvedBy: row.resolved_by,
    };
}

function mapUser(row) {
    return {
        uid: row.id,
        username: row.username,
        displayName: row.display_name,
        email: row.email,
        photoUrl: row.photo_url || '',
        bio: row.bio || '',
        role: row.role || 'user',
        isVerified: row.is_verified || false,
        isBanned: row.is_banned || false,
        followersCount: row.followers_count || 0,
        followingCount: row.following_count || 0,
        postsCount: row.posts_count || 0,
        createdAt: row.created_at,
    };
}

function mapPost(row) {
    return {
        id: row.id,
        userId: row.user_id,
        username: row.username,
        userPhotoUrl: row.user_photo_url || '',
        caption: row.caption || '',
        videoUrl: row.video_url || '',
        thumbnailUrl: row.thumbnail_url || '',
        imageUrl: row.image_url || '',
        hashtags: row.hashtags || [],
        likesCount: row.likes_count || 0,
        commentsCount: row.comments_count || 0,
        viewsCount: row.views_count || 0,
        musicTitle: row.music_title || '',
        musicArtist: row.music_artist || '',
        musicCoverUrl: row.music_cover_url || '',
        musicPreviewUrl: row.music_preview_url || '',
        createdAt: row.created_at,
    };
}

function mapComment(row) {
    return {
        id: row.id,
        postId: row.post_id,
        userId: row.user_id,
        username: row.username,
        userPhotoUrl: row.user_photo_url || '',
        text: row.text,
        createdAt: row.created_at,
    };
}

function mapConversation(row) {
    return {
        id: row.id,
        isGroup: false,
        lastMessage: row.last_message || '',
        lastMessageTime: row.last_message_time,
        otherUserId: row.other_user_id,
        otherUsername: row.other_username,
        otherDisplayName: row.other_display_name,
        otherPhotoUrl: row.other_photo_url || '',
    };
}

function mapGroupConversation(row, participantRows) {
    const participants = participantRows.map(p => p.id);
    const participantNames = {};
    const participantPhotos = {};
    for (const p of participantRows) {
        participantNames[p.id] = p.display_name || p.username;
        participantPhotos[p.id] = p.photo_url || '';
    }
    return {
        id: row.id,
        isGroup: true,
        groupName: row.group_name || 'Group',
        createdBy: row.created_by || '',
        lastMessage: row.last_message || '',
        lastMessageTime: row.last_message_time,
        participants,
        participantNames,
        participantPhotos,
    };
}

function mapMessage(row) {
    return {
        id: row.id,
        conversationId: row.conversation_id,
        senderId: row.sender_id,
        senderUsername: row.sender_username || '',
        text: row.text,
        isRead: row.is_read || false,
        createdAt: row.created_at,
    };
}

// ─── START ───────────────────────────────────────────────────────
// ── Auto-migrate ────────────────────────────────────────────────
async function autoMigrate() {
    // ── Ensure all tables exist (safe to run repeatedly) ────────
    try {
        await pool.query(`CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            username TEXT UNIQUE NOT NULL,
            display_name TEXT DEFAULT '',
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            photo_url TEXT DEFAULT '',
            bio TEXT DEFAULT '',
            role TEXT DEFAULT 'user',
            is_verified BOOLEAN DEFAULT false,
            is_banned BOOLEAN DEFAULT false,
            followers_count INTEGER DEFAULT 0,
            following_count INTEGER DEFAULT 0,
            posts_count INTEGER DEFAULT 0,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )`);
        await pool.query(`CREATE TABLE IF NOT EXISTS posts (
            id TEXT PRIMARY KEY,
            user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
            caption TEXT DEFAULT '',
            video_url TEXT DEFAULT '',
            thumbnail_url TEXT DEFAULT '',
            image_url TEXT DEFAULT '',
            hashtags TEXT[] DEFAULT '{}',
            likes_count INTEGER DEFAULT 0,
            comments_count INTEGER DEFAULT 0,
            views_count INTEGER DEFAULT 0,
            music_title TEXT DEFAULT '',
            music_artist TEXT DEFAULT '',
            music_cover_url TEXT DEFAULT '',
            music_preview_url TEXT DEFAULT '',
            created_at TIMESTAMPTZ DEFAULT NOW()
        )`);
        await pool.query(`CREATE TABLE IF NOT EXISTS comments (
            id TEXT PRIMARY KEY,
            post_id TEXT REFERENCES posts(id) ON DELETE CASCADE,
            user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
            text TEXT NOT NULL DEFAULT '',
            created_at TIMESTAMPTZ DEFAULT NOW()
        )`);
        await pool.query(`CREATE TABLE IF NOT EXISTS likes (
            id TEXT PRIMARY KEY,
            post_id TEXT REFERENCES posts(id) ON DELETE CASCADE,
            user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE(post_id, user_id)
        )`);
        await pool.query(`CREATE TABLE IF NOT EXISTS follows (
            follower_id TEXT REFERENCES users(id) ON DELETE CASCADE,
            following_id TEXT REFERENCES users(id) ON DELETE CASCADE,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            PRIMARY KEY (follower_id, following_id)
        )`);
        await pool.query(`CREATE TABLE IF NOT EXISTS conversations (
            id TEXT PRIMARY KEY,
            is_group BOOLEAN DEFAULT false,
            group_name TEXT DEFAULT '',
            created_by TEXT DEFAULT '',
            last_message TEXT DEFAULT '',
            last_message_time TIMESTAMPTZ DEFAULT NOW(),
            created_at TIMESTAMPTZ DEFAULT NOW()
        )`);
        await pool.query(`CREATE TABLE IF NOT EXISTS conversation_participants (
            conversation_id TEXT REFERENCES conversations(id) ON DELETE CASCADE,
            user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
            PRIMARY KEY (conversation_id, user_id)
        )`);
        await pool.query(`CREATE TABLE IF NOT EXISTS messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT REFERENCES conversations(id) ON DELETE CASCADE,
            sender_id TEXT REFERENCES users(id) ON DELETE CASCADE,
            text TEXT DEFAULT '',
            media_url TEXT DEFAULT '',
            media_type TEXT DEFAULT '',
            is_read BOOLEAN DEFAULT false,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )`);
        await pool.query(`CREATE TABLE IF NOT EXISTS reports (
            id TEXT PRIMARY KEY,
            reporter_id TEXT,
            reporter_username TEXT DEFAULT '',
            target_id TEXT NOT NULL,
            target_type TEXT NOT NULL DEFAULT 'user',
            reason TEXT NOT NULL DEFAULT '',
            details TEXT DEFAULT '',
            status TEXT DEFAULT 'pending',
            created_at TIMESTAMPTZ DEFAULT NOW(),
            resolved_at TIMESTAMPTZ,
            resolved_by TEXT
        )`);
        await pool.query(`CREATE TABLE IF NOT EXISTS livestreams (
            id TEXT PRIMARY KEY,
            host_id TEXT REFERENCES users(id) ON DELETE CASCADE,
            title TEXT DEFAULT '',
            status TEXT DEFAULT 'active',
            viewer_count INTEGER DEFAULT 0,
            peak_viewers INTEGER DEFAULT 0,
            stream_key TEXT DEFAULT '',
            playback_id TEXT DEFAULT '',
            mux_stream_id TEXT DEFAULT '',
            started_at TIMESTAMPTZ DEFAULT NOW(),
            ended_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )`);
        console.log('✅ All tables ensured');
    } catch (e) {
        console.error('Table creation error:', e.message);
    }

    // ── Add columns that may be missing on older schemas ────────
    try {
        await pool.query(`ALTER TABLE conversations ADD COLUMN IF NOT EXISTS is_group BOOLEAN DEFAULT false`);
        await pool.query(`ALTER TABLE conversations ADD COLUMN IF NOT EXISTS group_name TEXT DEFAULT ''`);
        await pool.query(`ALTER TABLE conversations ADD COLUMN IF NOT EXISTS created_by TEXT DEFAULT ''`);
        await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT false`);
        await pool.query(`ALTER TABLE posts ADD COLUMN IF NOT EXISTS music_title TEXT DEFAULT ''`);
        await pool.query(`ALTER TABLE posts ADD COLUMN IF NOT EXISTS music_artist TEXT DEFAULT ''`);
        await pool.query(`ALTER TABLE posts ADD COLUMN IF NOT EXISTS music_cover_url TEXT DEFAULT ''`);
        await pool.query(`ALTER TABLE posts ADD COLUMN IF NOT EXISTS music_preview_url TEXT DEFAULT ''`);
        // Indexes
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_posts_user ON posts(user_id, created_at DESC)`);
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_comments_post ON comments(post_id, created_at)`);
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_likes_post_user ON likes(post_id, user_id)`);
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_messages_convo ON messages(conversation_id, created_at)`);
        console.log('✅ All columns & indexes migrated');
    } catch (e) {
        console.warn('Migration note:', e.message);
    }

    // Seed admin user
    try {
        const existing = await pool.query("SELECT id FROM users WHERE email = 'admin@gmail.com'");
        if (existing.rows.length === 0) {
            const adminId = uuid();
            const hash = await bcrypt.hash('123456', 10);
            await pool.query(
                `INSERT INTO users (id, username, display_name, email, password_hash, photo_url, role, is_verified)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
                [adminId, 'admin', 'Admin', 'admin@gmail.com', hash,
                    'https://i.pravatar.cc/150?u=admin', 'admin', true]
            );
            console.log('✅ Admin user seeded (admin@gmail.com / 123456)');
        } else {
            // Ensure existing admin has correct role and password
            const hash = await bcrypt.hash('123456', 10);
            await pool.query(
                "UPDATE users SET role = 'admin', is_verified = true, password_hash = $1 WHERE email = 'admin@gmail.com'",
                [hash]
            );
        }
    } catch (e) {
        console.warn('Admin seed note:', e.message);
    }
}

const PORT = process.env.PORT || 650;

// ── Serve Flutter web build (universal port — API + UI on same origin) ───
const webBuildPath = path.join(__dirname, '..', 'build', 'web');
app.use(express.static(webBuildPath));
// SPA fallback: serve index.html for any non-API route so Flutter routing works
app.get(/^(?!\/api).*/, (req, res) => {
    res.sendFile(path.join(webBuildPath, 'index.html'));
});

autoMigrate().then(() => {
    httpServer.listen(PORT, () => {
        console.log(`🚀 Artistcase API  →  http://localhost:${PORT}`);
        console.log(`🔌 Socket.io ready →  ws://localhost:${PORT}`);
    });
});

// Export io for use in routes if needed
module.exports.io = io;

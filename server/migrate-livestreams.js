/**
 * Migration: Create livestreams table
 * Run: node server/migrate-livestreams.js
 */
const pool = require('./db');

async function migrate() {
    const client = await pool.connect();
    try {
        // Note: users.id is TEXT (not UUID) so host_id must also be TEXT
        await client.query(`
      CREATE TABLE IF NOT EXISTS livestreams (
        id                  TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
        host_id             TEXT        REFERENCES users(id) ON DELETE CASCADE,
        title               TEXT        NOT NULL DEFAULT 'Untitled Stream',
        mux_stream_id       TEXT,
        mux_playback_id     TEXT,
        stream_key          TEXT,
        playback_url        TEXT        DEFAULT '',
        replay_playback_url TEXT        DEFAULT '',
        status              TEXT        DEFAULT 'idle',
        viewer_count        INT         DEFAULT 0,
        peak_viewers        INT         DEFAULT 0,
        total_reactions     INT         DEFAULT 0,
        started_at          TIMESTAMPTZ DEFAULT NOW(),
        ended_at            TIMESTAMPTZ,
        created_at          TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE INDEX IF NOT EXISTS idx_livestreams_status     ON livestreams(status);
      CREATE INDEX IF NOT EXISTS idx_livestreams_host_id    ON livestreams(host_id);
      CREATE INDEX IF NOT EXISTS idx_livestreams_mux_stream ON livestreams(mux_stream_id);
    `);
        console.log('✅ livestreams table created (or already exists)');
    } finally {
        client.release();
        await pool.end();
    }
}

migrate().catch((e) => { console.error('Migration failed:', e.message); process.exit(1); });

const pool = require('./db');

async function init() {
    try {
        // ── Users ──
        await pool.query(`
            CREATE TABLE IF NOT EXISTS users (
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
            )
        `);
        console.log('✅ users table ready');

        // ── Posts ──
        await pool.query(`
            CREATE TABLE IF NOT EXISTS posts (
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
            )
        `);
        console.log('✅ posts table ready');

        // ── Comments ──
        await pool.query(`
            CREATE TABLE IF NOT EXISTS comments (
                id TEXT PRIMARY KEY,
                post_id TEXT REFERENCES posts(id) ON DELETE CASCADE,
                user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
                text TEXT NOT NULL DEFAULT '',
                created_at TIMESTAMPTZ DEFAULT NOW()
            )
        `);
        console.log('✅ comments table ready');

        // ── Likes ──
        await pool.query(`
            CREATE TABLE IF NOT EXISTS likes (
                id TEXT PRIMARY KEY,
                post_id TEXT REFERENCES posts(id) ON DELETE CASCADE,
                user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
                created_at TIMESTAMPTZ DEFAULT NOW(),
                UNIQUE(post_id, user_id)
            )
        `);
        console.log('✅ likes table ready');

        // ── Follows ──
        await pool.query(`
            CREATE TABLE IF NOT EXISTS follows (
                follower_id TEXT REFERENCES users(id) ON DELETE CASCADE,
                following_id TEXT REFERENCES users(id) ON DELETE CASCADE,
                created_at TIMESTAMPTZ DEFAULT NOW(),
                PRIMARY KEY (follower_id, following_id)
            )
        `);
        console.log('✅ follows table ready');

        // ── Conversations ──
        await pool.query(`
            CREATE TABLE IF NOT EXISTS conversations (
                id TEXT PRIMARY KEY,
                is_group BOOLEAN DEFAULT false,
                group_name TEXT DEFAULT '',
                created_by TEXT DEFAULT '',
                last_message TEXT DEFAULT '',
                last_message_time TIMESTAMPTZ DEFAULT NOW(),
                created_at TIMESTAMPTZ DEFAULT NOW()
            )
        `);
        console.log('✅ conversations table ready');

        // ── Conversation Participants ──
        await pool.query(`
            CREATE TABLE IF NOT EXISTS conversation_participants (
                conversation_id TEXT REFERENCES conversations(id) ON DELETE CASCADE,
                user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
                PRIMARY KEY (conversation_id, user_id)
            )
        `);
        console.log('✅ conversation_participants table ready');

        // ── Messages ──
        await pool.query(`
            CREATE TABLE IF NOT EXISTS messages (
                id TEXT PRIMARY KEY,
                conversation_id TEXT REFERENCES conversations(id) ON DELETE CASCADE,
                sender_id TEXT REFERENCES users(id) ON DELETE CASCADE,
                text TEXT DEFAULT '',
                media_url TEXT DEFAULT '',
                media_type TEXT DEFAULT '',
                is_read BOOLEAN DEFAULT false,
                created_at TIMESTAMPTZ DEFAULT NOW()
            )
        `);
        console.log('✅ messages table ready');

        // ── Reports ──
        await pool.query(`
            CREATE TABLE IF NOT EXISTS reports (
                id TEXT PRIMARY KEY,
                reporter_id TEXT REFERENCES users(id) ON DELETE CASCADE,
                target_id TEXT NOT NULL,
                target_type TEXT DEFAULT 'user',
                reason TEXT DEFAULT '',
                details TEXT DEFAULT '',
                status TEXT DEFAULT 'pending',
                resolved_at TIMESTAMPTZ,
                resolved_by TEXT DEFAULT '',
                created_at TIMESTAMPTZ DEFAULT NOW()
            )
        `);
        console.log('✅ reports table ready');

        // ── Livestreams ──
        await pool.query(`
            CREATE TABLE IF NOT EXISTS livestreams (
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
            )
        `);
        console.log('✅ livestreams table ready');

        // ── Indexes ──
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_posts_user ON posts(user_id, created_at DESC)`);
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_comments_post ON comments(post_id, created_at)`);
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_likes_post_user ON likes(post_id, user_id)`);
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_messages_convo ON messages(conversation_id, created_at)`);
        console.log('✅ indexes ready');

        // ── Seed admin user ──
        const bcrypt = require('bcryptjs');
        const { v4: uuid } = require('uuid');
        const existing = await pool.query("SELECT id FROM users WHERE email = 'admin@gmail.com'");
        if (existing.rows.length === 0) {
            const hash = await bcrypt.hash('123456', 10);
            await pool.query(
                `INSERT INTO users (id, username, display_name, email, password_hash, photo_url, role, is_verified)
                 VALUES ($1, 'admin', 'Admin', 'admin@gmail.com', $2, 'https://i.pravatar.cc/150?u=admin', 'admin', true)`,
                [uuid(), hash]
            );
            console.log('✅ admin user seeded (admin@gmail.com / 123456)');
        } else {
            const hash = await bcrypt.hash('123456', 10);
            await pool.query(
                "UPDATE users SET role = 'admin', is_verified = true, password_hash = $1 WHERE email = 'admin@gmail.com'",
                [hash]
            );
            console.log('✅ admin user updated');
        }

        console.log('\n🎉 Database initialization complete!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Init error:', err.message);
        process.exit(1);
    }
}

init();

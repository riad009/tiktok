// Database setup script — run once to create tables
const fs = require('fs');
const path = require('path');
const pool = require('./db');

async function setup() {
    try {
        const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
        await pool.query(schema);
        console.log('✅ Database schema created successfully!');

        // Seed a default post so the feed isn't empty
        const { v4: uuid } = require('uuid');
        const bcrypt = require('bcryptjs');

        // Create a demo user if not exists
        const demoId = 'demo-user-001';
        const existing = await pool.query('SELECT id FROM users WHERE id = $1', [demoId]);
        if (existing.rows.length === 0) {
            const hash = await bcrypt.hash('demo123', 10);
            await pool.query(
                `INSERT INTO users (id, username, display_name, email, password_hash, bio, photo_url)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
                [demoId, 'demo_creator', 'Demo Creator', 'demo@artistcase.app', hash,
                    '🎨 Welcome to Artistcase!', 'https://i.pravatar.cc/150?img=3']
            );
            console.log('  → Created demo user: demo@artistcase.app / demo123');
        }

        // Create a seed post
        const postCheck = await pool.query('SELECT id FROM posts WHERE user_id = $1 LIMIT 1', [demoId]);
        if (postCheck.rows.length === 0) {
            await pool.query(
                `INSERT INTO posts (id, user_id, caption, video_url, thumbnail_url, hashtags, likes_count, views_count)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
                [uuid(), demoId, 'Welcome to Artistcase! 🚀 The future of creative social media',
                    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
                    'https://picsum.photos/seed/welcome/360/640',
                    '{welcome,artistcase,creative}', 42, 1200]
            );
            console.log('  → Created seed post');
        }

        process.exit(0);
    } catch (err) {
        console.error('❌ Setup failed:', err.message);
        process.exit(1);
    }
}

setup();

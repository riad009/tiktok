const pool = require('./db');

async function migrate() {
    try {
        // Add image_url column to posts
        await pool.query(`ALTER TABLE posts ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT ''`);
        console.log('Added image_url column to posts');

        // Create comments table
        await pool.query(`
      CREATE TABLE IF NOT EXISTS comments (
        id TEXT PRIMARY KEY,
        post_id TEXT REFERENCES posts(id) ON DELETE CASCADE,
        user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
        text TEXT NOT NULL DEFAULT '',
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);
        console.log('Created comments table');

        // Create likes table
        await pool.query(`
      CREATE TABLE IF NOT EXISTS likes (
        id TEXT PRIMARY KEY,
        post_id TEXT REFERENCES posts(id) ON DELETE CASCADE,
        user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE(post_id, user_id)
      )
    `);
        console.log('Created likes table');

        // Create indexes
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_comments_post ON comments(post_id, created_at)`);
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_likes_post_user ON likes(post_id, user_id)`);
        console.log('Created indexes');

        console.log('Migration complete!');
        process.exit(0);
    } catch (err) {
        console.error('Migration error:', err);
        process.exit(1);
    }
}

migrate();

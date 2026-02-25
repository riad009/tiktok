const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const { v4: uuid } = require('uuid');
const pool = require('./db');

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));

// ─── Health check ────────────────────────────────────────────────
app.get('/api/health', (_, res) => res.json({ status: 'ok' }));

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
        const { userId, caption, videoUrl, thumbnailUrl, imageUrl, hashtags } = req.body;
        if (!userId) return res.status(400).json({ error: 'userId is required' });

        const id = uuid();
        const result = await pool.query(
            `INSERT INTO posts (id, user_id, caption, video_url, thumbnail_url, image_url, hashtags)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
            [id, userId, caption || '', videoUrl || '', thumbnailUrl || '', imageUrl || '', hashtags || []]
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
        const result = await pool.query(
            `SELECT c.*, cp2.user_id AS other_user_id,
              u.username AS other_username, u.display_name AS other_display_name,
              u.photo_url AS other_photo_url
       FROM conversations c
       JOIN conversation_participants cp1 ON c.id = cp1.conversation_id AND cp1.user_id = $1
       JOIN conversation_participants cp2 ON c.id = cp2.conversation_id AND cp2.user_id != $1
       JOIN users u ON cp2.user_id = u.id
       ORDER BY c.last_message_time DESC`,
            [userId]
        );
        res.json(result.rows.map(mapConversation));
    } catch (err) {
        console.error('Conversations error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

app.post('/api/conversations', async (req, res) => {
    try {
        const { userId1, userId2 } = req.body;
        if (!userId1 || !userId2) return res.status(400).json({ error: 'userId1 and userId2 are required' });

        const existing = await pool.query(
            `SELECT cp1.conversation_id FROM conversation_participants cp1
       JOIN conversation_participants cp2 ON cp1.conversation_id = cp2.conversation_id
       WHERE cp1.user_id = $1 AND cp2.user_id = $2`,
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
        await pool.query('INSERT INTO conversations (id) VALUES ($1)', [convoId]);
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

// ─── MAPPERS ─────────────────────────────────────────────────────

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
        lastMessage: row.last_message || '',
        lastMessageTime: row.last_message_time,
        otherUserId: row.other_user_id,
        otherUsername: row.other_username,
        otherDisplayName: row.other_display_name,
        otherPhotoUrl: row.other_photo_url || '',
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
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`🚀 Artistcase API running on http://localhost:${PORT}`);
});

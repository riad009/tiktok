/**
 * seed-demo.js — Populate the database with realistic demo content
 *
 * Creates 5 demo users, 5 image posts, comments, likes, and 1 active livestream.
 * Safe to run multiple times (skips if demo data already exists).
 *
 * Usage:  node server/seed-demo.js
 */

const pool = require('./db');
const bcrypt = require('bcryptjs');
const { v4: uuid } = require('uuid');

// ── Demo Users ───────────────────────────────────────────────────
const demoUsers = [
  {
    username: 'sofia.dance',
    displayName: 'Sofia Rivera 💃',
    email: 'sofia@demo.com',
    bio: '✨ Professional dancer | NYC 🗽 | DM for collabs',
    photoUrl: 'https://i.pravatar.cc/300?img=47',
  },
  {
    username: 'chef.marcus',
    displayName: 'Marcus Chen 🍳',
    email: 'marcus@demo.com',
    bio: '🔥 Chef life | Food creator | 500K family ❤️',
    photoUrl: 'https://i.pravatar.cc/300?img=12',
  },
  {
    username: 'travel.maya',
    displayName: 'Maya Patel 🌍',
    email: 'maya@demo.com',
    bio: '🧳 30 countries & counting | Full-time traveler',
    photoUrl: 'https://i.pravatar.cc/300?img=32',
  },
  {
    username: 'alex.beats',
    displayName: 'Alex Moreno 🎵',
    email: 'alex@demo.com',
    bio: '🎧 Music producer | Beatmaker | New EP out now 🔊',
    photoUrl: 'https://i.pravatar.cc/300?img=68',
  },
  {
    username: 'luna.art',
    displayName: 'Luna Kim 🎨',
    email: 'luna@demo.com',
    bio: '🎨 Digital artist | Commissions open | she/her',
    photoUrl: 'https://i.pravatar.cc/300?img=9',
  },
];

// ── Demo Posts (image-based) ─────────────────────────────────────
// Using picsum.photos and Lorem Picsum for high-quality free stock images
const demoPosts = [
  {
    userIndex: 0, // sofia.dance
    caption: 'golden hour vibes at the studio ✨🩰 new choreo dropping tomorrow! #dance #goldenhour #studio #newchoreo',
    imageUrl: 'https://images.unsplash.com/photo-1518834107812-67b0b7c58434?w=600&h=900&fit=crop',
    thumbnailUrl: 'https://images.unsplash.com/photo-1518834107812-67b0b7c58434?w=300&h=450&fit=crop',
    hashtags: ['dance', 'goldenhour', 'studio', 'newchoreo'],
    likesCount: 2847,
    commentsCount: 3,
    viewsCount: 18420,
    musicTitle: 'Levitating',
    musicArtist: 'Dua Lipa',
  },
  {
    userIndex: 1, // chef.marcus
    caption: 'homemade ramen from scratch 🍜 took 12 hours but SO worth it. Recipe in bio! #foodie #ramen #homemade #cheflife',
    imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&h=900&fit=crop',
    thumbnailUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=300&h=450&fit=crop',
    hashtags: ['foodie', 'ramen', 'homemade', 'cheflife'],
    likesCount: 5632,
    commentsCount: 3,
    viewsCount: 42100,
    musicTitle: 'Lo-fi Cooking',
    musicArtist: 'Chill Beats',
  },
  {
    userIndex: 2, // travel.maya
    caption: 'sunrise at Santorini 🌅 this view is unreal. No filter needed! #travel #santorini #greece #wanderlust #sunrise',
    imageUrl: 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=600&h=900&fit=crop',
    thumbnailUrl: 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=300&h=450&fit=crop',
    hashtags: ['travel', 'santorini', 'greece', 'wanderlust', 'sunrise'],
    likesCount: 12453,
    commentsCount: 3,
    viewsCount: 89200,
    musicTitle: 'Island in the Sun',
    musicArtist: 'Weezer',
  },
  {
    userIndex: 3, // alex.beats
    caption: 'late night session 🎹🌙 something special cooking up in the lab. Who wants a preview? #music #producer #beats #studio',
    imageUrl: 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=600&h=900&fit=crop',
    thumbnailUrl: 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=300&h=450&fit=crop',
    hashtags: ['music', 'producer', 'beats', 'studio'],
    likesCount: 3291,
    commentsCount: 3,
    viewsCount: 25800,
    musicTitle: 'Original Beat #47',
    musicArtist: 'Alex Moreno',
  },
  {
    userIndex: 4, // luna.art
    caption: 'just finished this digital portrait 🖌️ 40 hours of work in one image. Swipe for timelapse! #art #digitalart #portrait #illustration',
    imageUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=600&h=900&fit=crop',
    thumbnailUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=300&h=450&fit=crop',
    hashtags: ['art', 'digitalart', 'portrait', 'illustration'],
    likesCount: 7845,
    commentsCount: 3,
    viewsCount: 56300,
    musicTitle: 'Aesthetic',
    musicArtist: 'Lofi Girl',
  },
];

// ── Demo Comments ────────────────────────────────────────────────
const commentBank = [
  ['OMG this is amazing!! 🔥🔥', 'I need this in my life 😍', 'so talented!!!'],
  ['recipe please!! 🙏', 'my mouth is watering rn', 'you make it look so easy 😭'],
  ['adding this to my bucket list ✈️', 'how is this even real?! 😱', 'I was just there last month! beautiful'],
  ['drop the full track!! 🎶', 'this goes HARD bro 🔥', 'need this on spotify asap'],
  ['the detail is insane 🤯', 'how do you even do this?!', 'commission prices?? 💰'],
];

async function seed() {
  try {
    console.log('🌱 Starting demo seed...\n');

    const hash = await bcrypt.hash('demo123', 10);
    const userIds = [];

    // ── 1. Create demo users ──────────────────────────────
    for (const u of demoUsers) {
      // Check if user already exists
      const exists = await pool.query('SELECT id FROM users WHERE email = $1', [u.email]);
      if (exists.rows.length > 0) {
        userIds.push(exists.rows[0].id);
        console.log(`  ↩  User ${u.username} already exists`);
        continue;
      }

      const id = uuid();
      await pool.query(
        `INSERT INTO users (id, username, display_name, email, password_hash, photo_url, bio, is_verified, followers_count, following_count, posts_count)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`,
        [id, u.username, u.displayName, u.email, hash, u.photoUrl, u.bio, true,
         Math.floor(Math.random() * 50000) + 1000,
         Math.floor(Math.random() * 500) + 50,
         Math.floor(Math.random() * 80) + 10]
      );
      userIds.push(id);
      console.log(`  ✅ Created user: ${u.username}`);
    }

    // ── 2. Create demo posts ──────────────────────────────
    const postIds = [];
    for (let i = 0; i < demoPosts.length; i++) {
      const p = demoPosts[i];
      const userId = userIds[p.userIndex];

      // Check if we already seeded this post (by caption prefix)
      const dup = await pool.query(
        `SELECT id FROM posts WHERE user_id = $1 AND caption LIKE $2 LIMIT 1`,
        [userId, p.caption.substring(0, 30) + '%']
      );
      if (dup.rows.length > 0) {
        postIds.push(dup.rows[0].id);
        console.log(`  ↩  Post ${i + 1} already exists`);
        continue;
      }

      const postId = uuid();
      // Stagger creation times so the feed has a nice order
      const createdAt = new Date(Date.now() - (demoPosts.length - i) * 3600000).toISOString();

      await pool.query(
        `INSERT INTO posts (id, user_id, caption, image_url, thumbnail_url, hashtags,
          likes_count, comments_count, views_count, music_title, music_artist, created_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
        [postId, userId, p.caption, p.imageUrl, p.thumbnailUrl,
         p.hashtags, p.likesCount, p.commentsCount, p.viewsCount,
         p.musicTitle, p.musicArtist, createdAt]
      );
      postIds.push(postId);
      console.log(`  ✅ Created post ${i + 1}: "${p.caption.substring(0, 40)}..."`);
    }

    // ── 3. Add comments to each post ──────────────────────
    for (let i = 0; i < postIds.length; i++) {
      const postId = postIds[i];
      const comments = commentBank[i];

      // Check if comments already exist
      const existing = await pool.query(
        'SELECT COUNT(*) FROM comments WHERE post_id = $1', [postId]
      );
      if (parseInt(existing.rows[0].count) > 0) {
        console.log(`  ↩  Comments for post ${i + 1} already exist`);
        continue;
      }

      for (let j = 0; j < comments.length; j++) {
        // Pick a random commenter (not the post author)
        const commenterIndex = (demoPosts[i].userIndex + j + 1) % userIds.length;
        await pool.query(
          'INSERT INTO comments (id, post_id, user_id, text) VALUES ($1,$2,$3,$4)',
          [uuid(), postId, userIds[commenterIndex], comments[j]]
        );
      }
      console.log(`  ✅ Added ${comments.length} comments to post ${i + 1}`);
    }

    // ── 4. Add cross-likes ────────────────────────────────
    for (let i = 0; i < postIds.length; i++) {
      for (let j = 0; j < userIds.length; j++) {
        if (j === demoPosts[i].userIndex) continue; // skip self-like
        try {
          await pool.query(
            'INSERT INTO likes (id, post_id, user_id) VALUES ($1,$2,$3) ON CONFLICT DO NOTHING',
            [uuid(), postIds[i], userIds[j]]
          );
        } catch (_) { /* ignore duplicates */ }
      }
    }
    console.log('  ✅ Added cross-likes between users');

    // ── 5. Add follows between demo users ─────────────────
    for (let i = 0; i < userIds.length; i++) {
      for (let j = 0; j < userIds.length; j++) {
        if (i === j) continue;
        try {
          await pool.query(
            'INSERT INTO follows (follower_id, following_id) VALUES ($1,$2) ON CONFLICT DO NOTHING',
            [userIds[i], userIds[j]]
          );
        } catch (_) { }
      }
    }
    console.log('  ✅ Demo users now follow each other');

    // ── 6. Create active livestream ───────────────────────
    const liveHostId = userIds[0]; // sofia.dance goes live
    const existingLive = await pool.query(
      "SELECT id FROM livestreams WHERE host_id = $1 AND status = 'active'",
      [liveHostId]
    );

    if (existingLive.rows.length > 0) {
      console.log('  ↩  Active livestream already exists');
    } else {
      // Public Apple HLS test stream for demo
      const testHlsUrl =
        'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8';

      const liveId = uuid();
      try {
        await pool.query(
          `INSERT INTO livestreams
            (id, host_id, title, status, viewer_count, peak_viewers,
             stream_key, mux_stream_id, mux_playback_id, playback_url, started_at)
           VALUES ($1,$2,$3,'active',$4,$5,$6,$7,$8,$9,NOW())`,
          [liveId, liveHostId, '💃 Friday Night Dance Party!', 234, 412,
           'demo-key', 'demo-mux-' + Date.now(), 'demo-playback', testHlsUrl]
        );
        console.log('  ✅ Created active livestream: "💃 Friday Night Dance Party!"');
      } catch (err) {
        // Column might not exist yet — try simpler insert
        console.warn('  ⚠  Livestream insert note:', err.message);
        await pool.query(
          `INSERT INTO livestreams
            (id, host_id, title, status, viewer_count, peak_viewers, stream_key, started_at)
           VALUES ($1,$2,$3,'active',$4,$5,$6,NOW())`,
          [liveId, liveHostId, '💃 Friday Night Dance Party!', 234, 412, 'demo-key']
        );
        console.log('  ✅ Created active livestream (basic)');
      }
    }

    console.log('\n🎉 Demo seed complete! Your feed is now populated.');
    console.log('   Users: sofia.dance, chef.marcus, travel.maya, alex.beats, luna.art');
    console.log('   Password for all demo accounts: demo123\n');
    process.exit(0);
  } catch (err) {
    console.error('❌ Seed error:', err.message);
    process.exit(1);
  }
}

seed();

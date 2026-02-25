import '../../models/user_model.dart';
import '../../models/video_model.dart';
import '../../models/story_model.dart';
import '../../models/comment_model.dart';
import '../../models/message_model.dart';
import '../../models/livestream_model.dart';
import '../../models/report_model.dart';
import '../../models/subscription_model.dart';
import '../../models/music_model.dart';
import '../../models/clip_model.dart';

/// Central mock data source — every screen reads from here.
class MockData {
  MockData._();

  // ── Placeholder images (via picsum.photos) ─────────────────────
  static String avatar(int seed) => 'https://i.pravatar.cc/150?img=$seed';
  static String thumbnail(int seed) => 'https://picsum.photos/seed/vid$seed/360/640';
  static String storyImg(int seed) => 'https://picsum.photos/seed/story$seed/400/700';
  static String albumCover(int seed) => 'https://picsum.photos/seed/album$seed/300/300';

  // ── Mock Users ─────────────────────────────────────────────────
  static final List<UserModel> users = [
    UserModel(
      uid: 'mock-admin-uid-001', username: 'admin', displayName: 'Admin User',
      email: 'admin@gmail.com', photoUrl: avatar(1),
      bio: 'Platform administrator & creator', followersCount: 12400,
      followingCount: 342, postsCount: 87,
      role: 'admin', isVerified: true, badgeType: 'verified',
    ),
    UserModel(
      uid: 'user-002', username: 'sarah_creates', displayName: 'Sarah Chen',
      email: 'sarah@example.com', photoUrl: avatar(5),
      bio: '✨ Digital artist | NFT creator\n🎨 Making the world more colorful',
      followersCount: 45200, followingCount: 180, postsCount: 234,
      isVerified: true, badgeType: 'verified',
    ),
    UserModel(
      uid: 'user-003', username: 'mike_beats', displayName: 'Mike Rodriguez',
      email: 'mike@example.com', photoUrl: avatar(8),
      bio: '🎵 Music producer | Beat maker\n🔊 New beats every Friday',
      followersCount: 89300, followingCount: 95, postsCount: 412,
      isVerified: true, badgeType: 'verified',
    ),
    UserModel(
      uid: 'user-004', username: 'dance_queen', displayName: 'Priya Sharma',
      email: 'priya@example.com', photoUrl: avatar(9),
      bio: '💃 Dancer | Choreographer\n📍 Mumbai → LA',
      followersCount: 128000, followingCount: 210, postsCount: 567,
      isVerified: true, badgeType: 'verified',
    ),
    UserModel(
      uid: 'user-005', username: 'tech_alex', displayName: 'Alex Kim',
      email: 'alex@example.com', photoUrl: avatar(11),
      bio: '🖥️ Tech reviews | Gadgets\n📱 Honest opinions only',
      followersCount: 34500, followingCount: 420, postsCount: 189,
    ),
    UserModel(
      uid: 'user-006', username: 'foodie_emma', displayName: 'Emma Wilson',
      email: 'emma@example.com', photoUrl: avatar(16),
      bio: '🍳 Home chef | Recipe creator\n📖 Cookbook coming 2026',
      followersCount: 67800, followingCount: 150, postsCount: 298,
      isVerified: true, badgeType: 'verified',
    ),
    UserModel(
      uid: 'user-007', username: 'traveler_jay', displayName: 'Jay Park',
      email: 'jay@example.com', photoUrl: avatar(14),
      bio: '🌍 50 countries and counting\n📸 Travel photographer',
      followersCount: 92100, followingCount: 88, postsCount: 456,
    ),
    UserModel(
      uid: 'user-008', username: 'fitness_nina', displayName: 'Nina Petrova',
      email: 'nina@example.com', photoUrl: avatar(20),
      bio: '💪 Certified PT | Nutrition coach\n🏋️ Transform your life',
      followersCount: 156000, followingCount: 76, postsCount: 621,
      isVerified: true, badgeType: 'verified',
    ),
  ];

  // ── Mock Videos (Feed) ─────────────────────────────────────────
  static final List<VideoModel> videos = [
    VideoModel(
      id: 'vid-001', userId: 'user-002', username: 'sarah_creates',
      userPhotoUrl: avatar(5),
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      thumbnailUrl: thumbnail(1),
      caption: 'New digital art process 🎨 Watch me transform a blank canvas!',
      hashtags: ['digitalart', 'process', 'artwork', 'creative'],
      likesCount: 4521, commentsCount: 234, viewsCount: 45200,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    VideoModel(
      id: 'vid-002', userId: 'user-003', username: 'mike_beats',
      userPhotoUrl: avatar(8),
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      thumbnailUrl: thumbnail(2),
      caption: '🔥 New beat just dropped! Let me know what you think in the comments',
      hashtags: ['music', 'beats', 'producer', 'hiphop'],
      likesCount: 12890, commentsCount: 567, viewsCount: 89300,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    VideoModel(
      id: 'vid-003', userId: 'user-004', username: 'dance_queen',
      userPhotoUrl: avatar(9),
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      thumbnailUrl: thumbnail(3),
      caption: 'Choreo for the latest trending song 💃 Tutorial coming soon!',
      hashtags: ['dance', 'choreography', 'tutorial', 'trending'],
      likesCount: 34200, commentsCount: 1200, viewsCount: 256000,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    VideoModel(
      id: 'vid-004', userId: 'user-005', username: 'tech_alex',
      userPhotoUrl: avatar(11),
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      thumbnailUrl: thumbnail(4),
      caption: 'iPhone 18 Pro — Is it worth upgrading? 📱 Full review',
      hashtags: ['tech', 'review', 'iphone', 'gadgets'],
      likesCount: 8900, commentsCount: 890, viewsCount: 67800,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    VideoModel(
      id: 'vid-005', userId: 'user-006', username: 'foodie_emma',
      userPhotoUrl: avatar(16),
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      thumbnailUrl: thumbnail(5),
      caption: 'One-pot pasta that will change your life 🍝 Recipe in bio!',
      hashtags: ['food', 'recipe', 'cooking', 'pasta', 'easymeals'],
      likesCount: 15600, commentsCount: 432, viewsCount: 134000,
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    VideoModel(
      id: 'vid-006', userId: 'user-007', username: 'traveler_jay',
      userPhotoUrl: avatar(14),
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      thumbnailUrl: thumbnail(6),
      caption: 'Hidden gem in Bali you NEED to visit 🌴 Save for later!',
      hashtags: ['travel', 'bali', 'indonesia', 'wanderlust'],
      likesCount: 23400, commentsCount: 678, viewsCount: 198000,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    VideoModel(
      id: 'vid-007', userId: 'user-008', username: 'fitness_nina',
      userPhotoUrl: avatar(20),
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      thumbnailUrl: thumbnail(7),
      caption: '15-min full body workout — no equipment needed! 💪🏼',
      hashtags: ['fitness', 'workout', 'homeworkout', 'health'],
      likesCount: 45600, commentsCount: 2100, viewsCount: 421000,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
    ),
    VideoModel(
      id: 'vid-008', userId: 'mock-admin-uid-001', username: 'admin',
      userPhotoUrl: avatar(1),
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      thumbnailUrl: thumbnail(8),
      caption: 'Welcome to Artistcase! 🚀 Let\'s build something amazing together',
      hashtags: ['artistcase', 'welcome', 'community'],
      likesCount: 67800, commentsCount: 3400, viewsCount: 890000,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  // ── Image-only posts (for profile Photos tab) ─────────────────
  static final List<VideoModel> imagePosts = [
    VideoModel(
      id: 'img-001', userId: 'mock-admin-uid-001', username: 'admin',
      userPhotoUrl: avatar(1), videoUrl: '',
      imageUrl: 'https://picsum.photos/seed/photo1/400/400',
      caption: 'Studio vibes ✨', hashtags: ['studio', 'creative'],
      likesCount: 1200, commentsCount: 45, viewsCount: 5600,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    VideoModel(
      id: 'img-002', userId: 'mock-admin-uid-001', username: 'admin',
      userPhotoUrl: avatar(1), videoUrl: '',
      imageUrl: 'https://picsum.photos/seed/photo2/400/400',
      caption: 'Behind the scenes 🎬', hashtags: ['bts', 'creating'],
      likesCount: 890, commentsCount: 32, viewsCount: 3400,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  // ── Mock Comments ──────────────────────────────────────────────
  static List<CommentModel> commentsFor(String videoId) {
    return [
      CommentModel(id: 'c1', userId: 'user-003', username: 'mike_beats', userPhotoUrl: avatar(8),
        text: 'This is absolutely incredible! 🔥', likesCount: 45,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30))),
      CommentModel(id: 'c2', userId: 'user-004', username: 'dance_queen', userPhotoUrl: avatar(9),
        text: 'Love this so much!! Can we collab? 💕', likesCount: 89,
        createdAt: DateTime.now().subtract(const Duration(hours: 1))),
      CommentModel(id: 'c3', userId: 'user-006', username: 'foodie_emma', userPhotoUrl: avatar(16),
        text: 'Saved this for later! Amazing content', likesCount: 23,
        createdAt: DateTime.now().subtract(const Duration(hours: 2))),
      CommentModel(id: 'c4', userId: 'user-007', username: 'traveler_jay', userPhotoUrl: avatar(14),
        text: 'How long did this take to make? 😍', likesCount: 12,
        createdAt: DateTime.now().subtract(const Duration(hours: 3))),
      CommentModel(id: 'c5', userId: 'user-005', username: 'tech_alex', userPhotoUrl: avatar(11),
        text: 'The quality is insane! What camera are you using?', likesCount: 67,
        createdAt: DateTime.now().subtract(const Duration(hours: 4))),
      CommentModel(id: 'c6', userId: 'user-008', username: 'fitness_nina', userPhotoUrl: avatar(20),
        text: 'Just followed you! Keep creating 🙌', likesCount: 34,
        createdAt: DateTime.now().subtract(const Duration(hours: 5))),
    ];
  }

  // ── Mock Stories (enhanced) ────────────────────────────────────
  static final List<StoryModel> stories = [
    StoryModel(id: 'story-1', userId: 'user-004', username: 'dance_queen',
      userPhotoUrl: avatar(9), mediaUrl: storyImg(1), mediaType: 'image',
      filter: 'vivid', mentions: ['mike_beats'], hashtags: ['dance', 'collab'],
      musicTrackId: 'track-1', musicTitle: 'Midnight Groove', musicArtist: 'Mike Rodriguez'),
    StoryModel(id: 'story-2', userId: 'user-002', username: 'sarah_creates',
      userPhotoUrl: avatar(5), mediaUrl: storyImg(2), mediaType: 'image',
      filter: 'warm', caption: 'New artwork coming soon! 🎨',
      hashtags: ['art', 'wip']),
    StoryModel(id: 'story-3', userId: 'user-003', username: 'mike_beats',
      userPhotoUrl: avatar(8), mediaUrl: storyImg(3), mediaType: 'image',
      filter: 'cool', musicTrackId: 'track-3', musicTitle: 'Neon Dreams', musicArtist: 'Mike Rodriguez',
      caption: 'Studio session tonight 🎧'),
    StoryModel(id: 'story-4', userId: 'user-006', username: 'foodie_emma',
      userPhotoUrl: avatar(16), mediaUrl: storyImg(4), mediaType: 'image',
      filter: 'sepia', caption: 'Recipe drop tomorrow 🍳', mentions: ['traveler_jay']),
    StoryModel(id: 'story-5', userId: 'user-008', username: 'fitness_nina',
      userPhotoUrl: avatar(20), mediaUrl: storyImg(5), mediaType: 'image',
      filter: 'normal', hashtags: ['fitness', 'motivation'],
      musicTrackId: 'track-6', musicTitle: 'Power Up', musicArtist: 'Nina Petrova'),
    StoryModel(id: 'story-6', userId: 'user-007', username: 'traveler_jay',
      userPhotoUrl: avatar(14), mediaUrl: storyImg(6), mediaType: 'image',
      filter: 'vintage', caption: 'Greetings from Tokyo 🇯🇵',
      hashtags: ['travel', 'tokyo', 'japan']),
  ];

  // ── Mock Music Tracks ─────────────────────────────────────────
  static final List<MusicTrack> musicTracks = [
    MusicTrack(id: 'track-1', title: 'Midnight Groove', artistName: 'Mike Rodriguez',
      artistUserId: 'user-003', coverUrl: albumCover(1),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      duration: const Duration(minutes: 3, seconds: 24), usageCount: 12400),
    MusicTrack(id: 'track-2', title: 'Sunset Vibes', artistName: 'Sarah Chen',
      artistUserId: 'user-002', coverUrl: albumCover(2),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      duration: const Duration(minutes: 4, seconds: 12), usageCount: 8900),
    MusicTrack(id: 'track-3', title: 'Neon Dreams', artistName: 'Mike Rodriguez',
      artistUserId: 'user-003', coverUrl: albumCover(3),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      duration: const Duration(minutes: 2, seconds: 56), usageCount: 34200),
    MusicTrack(id: 'track-4', title: 'Golden Hour', artistName: 'Emma Wilson',
      artistUserId: 'user-006', coverUrl: albumCover(4),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      duration: const Duration(minutes: 3, seconds: 45), usageCount: 5600),
    MusicTrack(id: 'track-5', title: 'City Lights', artistName: 'Jay Park',
      artistUserId: 'user-007', coverUrl: albumCover(5),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      duration: const Duration(minutes: 5, seconds: 8), usageCount: 67800),
    MusicTrack(id: 'track-6', title: 'Power Up', artistName: 'Nina Petrova',
      artistUserId: 'user-008', coverUrl: albumCover(6),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
      duration: const Duration(minutes: 3, seconds: 33), usageCount: 23100),
    MusicTrack(id: 'track-7', title: 'Electric Feel', artistName: 'Alex Kim',
      artistUserId: 'user-005', coverUrl: albumCover(7),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
      duration: const Duration(minutes: 4, seconds: 1), usageCount: 15600),
    MusicTrack(id: 'track-8', title: 'Wanderlust', artistName: 'Priya Sharma',
      artistUserId: 'user-004', coverUrl: albumCover(8),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
      duration: const Duration(minutes: 3, seconds: 18), usageCount: 41200),
  ];

  // ── Liked posts (mock — posts the current user has liked) ─────
  static final List<String> likedPostIds = ['vid-001', 'vid-003', 'vid-005', 'vid-007'];
  static List<VideoModel> get likedPosts =>
      videos.where((v) => likedPostIds.contains(v.id)).toList();

  // ── Reposted posts (mock) ─────────────────────────────────────
  static final List<String> repostedPostIds = ['vid-002', 'vid-006'];
  static List<VideoModel> get repostedPosts =>
      videos.where((v) => repostedPostIds.contains(v.id)).toList();

  // ── Mock Conversations ─────────────────────────────────────────
  static final List<ConversationModel> conversations = [
    ConversationModel(
      id: 'convo-1', participants: ['mock-admin-uid-001', 'user-002'],
      lastMessage: 'Hey, loved your latest artwork! 🎨', lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
      participantNames: {'mock-admin-uid-001': 'Admin User', 'user-002': 'Sarah Chen'},
      participantPhotos: {'mock-admin-uid-001': avatar(1), 'user-002': avatar(5)},
    ),
    ConversationModel(
      id: 'convo-2', participants: ['mock-admin-uid-001', 'user-003'],
      lastMessage: 'That beat was fire! Can I use it? 🔥', lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      participantNames: {'mock-admin-uid-001': 'Admin User', 'user-003': 'Mike Rodriguez'},
      participantPhotos: {'mock-admin-uid-001': avatar(1), 'user-003': avatar(8)},
    ),
    ConversationModel(
      id: 'convo-3', participants: ['mock-admin-uid-001', 'user-004'],
      lastMessage: 'Tutorial was amazing, thanks! 💃', lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
      participantNames: {'mock-admin-uid-001': 'Admin User', 'user-004': 'Priya Sharma'},
      participantPhotos: {'mock-admin-uid-001': avatar(1), 'user-004': avatar(9)},
    ),
    ConversationModel(
      id: 'convo-4', participants: ['mock-admin-uid-001', 'user-006'],
      lastMessage: 'Recipe was so good, my family loved it 🍝', lastMessageTime: DateTime.now().subtract(const Duration(hours: 6)),
      participantNames: {'mock-admin-uid-001': 'Admin User', 'user-006': 'Emma Wilson'},
      participantPhotos: {'mock-admin-uid-001': avatar(1), 'user-006': avatar(16)},
    ),
  ];

  // ── Mock Group Conversations ───────────────────────────────────
  static final List<ConversationModel> groupConversations = [
    ConversationModel(
      id: 'group-1',
      participants: ['mock-admin-uid-001', 'user-002', 'user-003', 'user-004'],
      lastMessage: 'Let\'s plan the collab! 🎬',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
      participantNames: {
        'mock-admin-uid-001': 'Admin User',
        'user-002': 'Sarah Chen',
        'user-003': 'Mike Rodriguez',
        'user-004': 'Priya Sharma',
      },
      participantPhotos: {
        'mock-admin-uid-001': avatar(1),
        'user-002': avatar(5),
        'user-003': avatar(8),
        'user-004': avatar(9),
      },
      isGroupChat: true,
      groupName: 'Creative Crew 🎨',
      createdBy: 'mock-admin-uid-001',
      adminIds: ['mock-admin-uid-001'],
    ),
    ConversationModel(
      id: 'group-2',
      participants: ['mock-admin-uid-001', 'user-006', 'user-007', 'user-008'],
      lastMessage: 'See you at the event! 🎉',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      participantNames: {
        'mock-admin-uid-001': 'Admin User',
        'user-006': 'Emma Wilson',
        'user-007': 'Jay Park',
        'user-008': 'Nina Petrova',
      },
      participantPhotos: {
        'mock-admin-uid-001': avatar(1),
        'user-006': avatar(16),
        'user-007': avatar(14),
        'user-008': avatar(20),
      },
      isGroupChat: true,
      groupName: 'Wellness Warriors 💪',
      createdBy: 'user-008',
      adminIds: ['user-008', 'mock-admin-uid-001'],
    ),
  ];

  // ── Mock Messages ──────────────────────────────────────────────
  static List<MessageModel> messagesFor(String convoId) {
    return [
      MessageModel(id: 'm1', senderId: 'mock-admin-uid-001',
        text: 'Hey! Great work on your latest post 🔥',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)), isRead: true),
      MessageModel(id: 'm2', senderId: convoId == 'convo-1' ? 'user-002' : convoId == 'convo-2' ? 'user-003' : 'user-004',
        text: 'Thanks so much! That means a lot 😊',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)), isRead: true),
      MessageModel(id: 'm3', senderId: 'mock-admin-uid-001',
        text: 'Would you be interested in collaborating on something?',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)), isRead: true),
      MessageModel(id: 'm4', senderId: convoId == 'convo-1' ? 'user-002' : convoId == 'convo-2' ? 'user-003' : 'user-004',
        text: 'Absolutely! Let\'s do it! 🤝',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)), isRead: true),
      MessageModel(id: 'm5', senderId: 'mock-admin-uid-001',
        text: 'Perfect, I\'ll send you the details later today',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)), isRead: true),
      MessageModel(id: 'm6', senderId: convoId == 'convo-1' ? 'user-002' : convoId == 'convo-2' ? 'user-003' : 'user-004',
        text: 'Sounds great! Looking forward to it 🚀',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)), isRead: false),
    ];
  }

  // ── Mock Livestreams ───────────────────────────────────────────
  static final List<LivestreamModel> activeLivestreams = [
    LivestreamModel(
      id: 'live-1', hostId: 'user-004', hostUsername: 'dance_queen',
      hostPhotoUrl: avatar(9), title: 'Live Dance Practice 💃',
      isLive: true, viewerCount: 1243, totalReactions: 5600,
      startedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    LivestreamModel(
      id: 'live-2', hostId: 'user-003', hostUsername: 'mike_beats',
      hostPhotoUrl: avatar(8), title: 'Making beats live 🎧',
      isLive: true, viewerCount: 892, totalReactions: 3200,
      startedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    LivestreamModel(
      id: 'live-3', hostId: 'user-006', hostUsername: 'foodie_emma',
      hostPhotoUrl: avatar(16), title: 'Cooking dinner together! 🍳',
      isLive: true, viewerCount: 2100, totalReactions: 8900,
      startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  static final List<LivestreamModel> replays = [
    LivestreamModel(
      id: 'replay-1', hostId: 'user-008', hostUsername: 'fitness_nina',
      hostPhotoUrl: avatar(20), title: 'Morning HIIT Session 💪',
      isLive: false, viewerCount: 4500, totalReactions: 12000,
      startedAt: DateTime.now().subtract(const Duration(days: 1)),
      endedAt: DateTime.now().subtract(const Duration(hours: 22)),
      peakViewers: 4500,
    ),
    LivestreamModel(
      id: 'replay-2', hostId: 'user-007', hostUsername: 'traveler_jay',
      hostPhotoUrl: avatar(14), title: 'Live from Tokyo streets 🇯🇵',
      isLive: false, viewerCount: 8900, totalReactions: 23000,
      startedAt: DateTime.now().subtract(const Duration(days: 2)),
      endedAt: DateTime.now().subtract(const Duration(days: 1, hours: 21)),
      peakViewers: 8900,
    ),
    LivestreamModel(
      id: 'replay-3', hostId: 'mock-admin-uid-001', hostUsername: 'admin',
      hostPhotoUrl: avatar(1), title: 'Platform Q&A 🎙️',
      isLive: false, viewerCount: 3200, totalReactions: 8400,
      startedAt: DateTime.now().subtract(const Duration(days: 3)),
      endedAt: DateTime.now().subtract(const Duration(days: 2, hours: 22)),
      peakViewers: 3200,
    ),
  ];

  // ── Mock Livestream Clips ──────────────────────────────────────
  static final List<ClipModel> livestreamClips = [
    ClipModel(
      id: 'clip-1',
      livestreamId: 'replay-1',
      hostId: 'user-008',
      hostUsername: 'fitness_nina',
      hostPhotoUrl: avatar(20),
      title: '🔥 Peak moment — 200 reactions burst!',
      thumbnailUrl: thumbnail(10),
      startTime: const Duration(minutes: 12, seconds: 30),
      endTime: const Duration(minutes: 13, seconds: 15),
      highlightType: 'peak_reactions',
      likesCount: 890,
      viewsCount: 4500,
    ),
    ClipModel(
      id: 'clip-2',
      livestreamId: 'replay-1',
      hostId: 'user-008',
      hostUsername: 'fitness_nina',
      hostPhotoUrl: avatar(20),
      title: '💪 Killer burpee combo',
      thumbnailUrl: thumbnail(11),
      startTime: const Duration(minutes: 25),
      endTime: const Duration(minutes: 25, seconds: 45),
      highlightType: 'chat_burst',
      likesCount: 1200,
      viewsCount: 6700,
      postedToFeed: true,
    ),
    ClipModel(
      id: 'clip-3',
      livestreamId: 'replay-2',
      hostId: 'user-007',
      hostUsername: 'traveler_jay',
      hostPhotoUrl: avatar(14),
      title: '🇯🇵 Cherry blossom reveal!',
      thumbnailUrl: thumbnail(12),
      startTime: const Duration(minutes: 8, seconds: 15),
      endTime: const Duration(minutes: 9),
      highlightType: 'peak_viewers',
      likesCount: 3400,
      viewsCount: 12000,
      postedToFeed: true,
      sharedToStory: true,
    ),
    ClipModel(
      id: 'clip-4',
      livestreamId: 'replay-3',
      hostId: 'mock-admin-uid-001',
      hostUsername: 'admin',
      hostPhotoUrl: avatar(1),
      title: '🎙️ Big announcement moment',
      thumbnailUrl: thumbnail(13),
      startTime: const Duration(minutes: 15, seconds: 30),
      endTime: const Duration(minutes: 16, seconds: 20),
      highlightType: 'peak_reactions',
      likesCount: 2100,
      viewsCount: 8900,
    ),
  ];

  // ── Blocked Users (mock) ───────────────────────────────────────
  static final List<String> blockedUserIds = [];

  // ── Mock Reports (Admin) ───────────────────────────────────────
  static final List<ReportModel> reports = [
    ReportModel(id: 'report-1', reporterId: 'user-005', reporterUsername: 'tech_alex',
      targetId: 'vid-003', targetType: 'video', reason: 'Inappropriate music content',
      status: 'pending', createdAt: DateTime.now().subtract(const Duration(hours: 3))),
    ReportModel(id: 'report-2', reporterId: 'user-007', reporterUsername: 'traveler_jay',
      targetId: 'user-999', targetType: 'user', reason: 'Spam account sending bulk messages',
      status: 'pending', createdAt: DateTime.now().subtract(const Duration(hours: 8))),
    ReportModel(id: 'report-3', reporterId: 'user-002', reporterUsername: 'sarah_creates',
      targetId: 'vid-099', targetType: 'video', reason: 'Stolen artwork — this is my original piece',
      status: 'pending', createdAt: DateTime.now().subtract(const Duration(days: 1))),
    ReportModel(id: 'report-4', reporterId: 'user-006', reporterUsername: 'foodie_emma',
      targetId: 'comment-055', targetType: 'comment', reason: 'Harassment in comments',
      status: 'resolved', resolvedBy: 'mock-admin-uid-001',
      createdAt: DateTime.now().subtract(const Duration(days: 2))),
  ];

  // ── Mock Subscriptions ─────────────────────────────────────────
  static final List<SubscriptionModel> subscribers = [
    SubscriptionModel(id: 'sub-1', subscriberId: 'user-003', creatorId: 'mock-admin-uid-001',
      tier: 'vip', price: 14.99, startDate: DateTime.now().subtract(const Duration(days: 30))),
    SubscriptionModel(id: 'sub-2', subscriberId: 'user-004', creatorId: 'mock-admin-uid-001',
      tier: 'pro', price: 4.99, startDate: DateTime.now().subtract(const Duration(days: 15))),
    SubscriptionModel(id: 'sub-3', subscriberId: 'user-006', creatorId: 'mock-admin-uid-001',
      tier: 'pro', price: 4.99, startDate: DateTime.now().subtract(const Duration(days: 7))),
    SubscriptionModel(id: 'sub-4', subscriberId: 'user-008', creatorId: 'mock-admin-uid-001',
      tier: 'vip', price: 14.99, startDate: DateTime.now().subtract(const Duration(days: 45))),
  ];

  // ── Mock Tips ──────────────────────────────────────────────────
  static final List<TipModel> tips = [
    TipModel(id: 'tip-1', senderId: 'user-004', senderUsername: 'dance_queen',
      receiverId: 'mock-admin-uid-001', amount: 50.0, message: 'Amazing content! Keep going! 🔥',
      timestamp: DateTime.now().subtract(const Duration(hours: 1))),
    TipModel(id: 'tip-2', senderId: 'user-003', senderUsername: 'mike_beats',
      receiverId: 'mock-admin-uid-001', amount: 10.0, message: 'Loved the collab idea',
      timestamp: DateTime.now().subtract(const Duration(hours: 4))),
    TipModel(id: 'tip-3', senderId: 'user-008', senderUsername: 'fitness_nina',
      receiverId: 'mock-admin-uid-001', amount: 25.0, livestreamId: 'live-1',
      timestamp: DateTime.now().subtract(const Duration(hours: 8))),
    TipModel(id: 'tip-4', senderId: 'user-006', senderUsername: 'foodie_emma',
      receiverId: 'mock-admin-uid-001', amount: 5.0, message: '💎',
      timestamp: DateTime.now().subtract(const Duration(days: 1))),
    TipModel(id: 'tip-5', senderId: 'user-002', senderUsername: 'sarah_creates',
      receiverId: 'mock-admin-uid-001', amount: 100.0, message: 'You deserve it! Best platform ever 🎉',
      timestamp: DateTime.now().subtract(const Duration(days: 2))),
  ];

  // ── Mock Trending Hashtags ─────────────────────────────────────
  static final Map<String, int> trendingHashtags = {
    'artistcase': 12400,
    'dance': 89300,
    'music': 67800,
    'digitalart': 45200,
    'fitness': 134000,
    'travel': 98700,
    'food': 76500,
    'tech': 54300,
    'trending': 210000,
    'creative': 38900,
  };

  // ── Helper: get user by uid ────────────────────────────────────
  static UserModel? userById(String uid) {
    try { return users.firstWhere((u) => u.uid == uid); } catch (_) { return null; }
  }

  // ── Helper: videos for a specific user ─────────────────────────
  static List<VideoModel> videosForUser(String uid) {
    return videos.where((v) => v.userId == uid).toList();
  }

  // ── Helper: user's livestream replays ──────────────────────────
  static List<LivestreamModel> livestreamsForUser(String uid) {
    return replays.where((l) => l.hostId == uid).toList();
  }

  // ── Helper: clips for a specific livestream ────────────────────
  static List<ClipModel> clipsForLivestream(String livestreamId) {
    return livestreamClips.where((c) => c.livestreamId == livestreamId).toList();
  }

  // ── Helper: clips for a specific user ──────────────────────────
  static List<ClipModel> clipsForUser(String userId) {
    return livestreamClips.where((c) => c.hostId == userId).toList();
  }

  // ── Helper: music track by id ──────────────────────────────────
  static MusicTrack? trackById(String id) {
    try { return musicTracks.firstWhere((t) => t.id == id); } catch (_) { return null; }
  }
}

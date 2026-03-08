class AppConstants {
  static const String appName = 'Artistcase';
  static const String appTagline = 'Create. Share. Inspire.';

  // Video
  static const int maxVideoDurationSeconds = 60;
  static const int maxVideoSizeMB = 50;

  // Stories
  static const int storyDurationHours = 24;
  static const int storyViewDurationSeconds = 5;

  // Pagination
  static const int feedPageSize = 10;
  static const int searchPageSize = 20;
  static const int chatPageSize = 30;

  // Admin (role is checked server-side via user.role)
  // No hardcoded credentials — admin is assigned by role in the database

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String videosCollection = 'videos';
  static const String storiesCollection = 'stories';
  static const String commentsCollection = 'comments';
  static const String likesCollection = 'likes';
  static const String followersCollection = 'followers';
  static const String followingCollection = 'following';
  static const String conversationsCollection = 'conversations';
  static const String messagesCollection = 'messages';
  static const String hashtagsCollection = 'hashtags';
  static const String livestreamsCollection = 'livestreams';
  static const String liveChatCollection = 'liveChat';
  static const String reportsCollection = 'reports';
  static const String subscriptionsCollection = 'subscriptions';
  static const String tipsCollection = 'tips';
  static const String adminLogsCollection = 'adminLogs';

  // Storage Paths
  static const String profilePhotosPath = 'profile_photos';
  static const String videosPath = 'videos';
  static const String thumbnailsPath = 'thumbnails';
  static const String storiesPath = 'stories';
  static const String livestreamReplaysPath = 'livestream_replays';
  static const String chatMediaPath = 'chat_media';
}

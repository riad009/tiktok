class VideoModel {
  final String id;
  final String userId;
  final String username;
  final String userPhotoUrl;
  final String videoUrl;
  final String thumbnailUrl;
  final String imageUrl;
  final String caption;
  final List<String> hashtags;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhotoUrl = '',
    required this.videoUrl,
    this.thumbnailUrl = '',
    this.imageUrl = '',
    this.caption = '',
    this.hashtags = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory VideoModel.fromMap(Map<String, dynamic> map, String docId) {
    return VideoModel(
      id: docId,
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
      hashtags: List<String>.from(map['hashtags'] ?? []),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      viewsCount: map['viewsCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'imageUrl': imageUrl,
      'caption': caption,
      'hashtags': hashtags,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'viewsCount': viewsCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

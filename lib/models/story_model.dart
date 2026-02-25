class StoryModel {
  final String id;
  final String userId;
  final String username;
  final String userPhotoUrl;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy;
  // New fields
  final String caption;
  final String filter; // filter name: 'normal','vivid','mono','sepia','cool','warm','vintage','fade'
  final List<String> mentions; // @usernames
  final List<String> hashtags;
  final String? musicTrackId;
  final String? musicTitle;
  final String? musicArtist;

  StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhotoUrl = '',
    required this.mediaUrl,
    required this.mediaType,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.viewedBy = const [],
    this.caption = '',
    this.filter = 'normal',
    this.mentions = const [],
    this.hashtags = const [],
    this.musicTrackId,
    this.musicTitle,
    this.musicArtist,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 24));

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory StoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return StoryModel(
      id: docId,
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      mediaType: map['mediaType'] ?? 'image',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'].toString()) ?? DateTime.now().add(const Duration(hours: 24))
          : DateTime.now().add(const Duration(hours: 24)),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      caption: map['caption'] ?? '',
      filter: map['filter'] ?? 'normal',
      mentions: List<String>.from(map['mentions'] ?? []),
      hashtags: List<String>.from(map['hashtags'] ?? []),
      musicTrackId: map['musicTrackId'],
      musicTitle: map['musicTitle'],
      musicArtist: map['musicArtist'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'viewedBy': viewedBy,
      'caption': caption,
      'filter': filter,
      'mentions': mentions,
      'hashtags': hashtags,
      'musicTrackId': musicTrackId,
      'musicTitle': musicTitle,
      'musicArtist': musicArtist,
    };
  }
}

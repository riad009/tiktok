import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an auto-generated clip from a livestream highlight.
class ClipModel {
  final String id;
  final String livestreamId;
  final String hostId;
  final String hostUsername;
  final String hostPhotoUrl;
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final Duration startTime;
  final Duration endTime;
  final String highlightType; // 'peak_reactions', 'peak_viewers', 'chat_burst', 'manual'
  final int likesCount;
  final int viewsCount;
  final bool postedToFeed;
  final bool sharedToStory;
  final DateTime createdAt;

  ClipModel({
    required this.id,
    required this.livestreamId,
    required this.hostId,
    required this.hostUsername,
    this.hostPhotoUrl = '',
    required this.title,
    this.thumbnailUrl = '',
    this.videoUrl = '',
    required this.startTime,
    required this.endTime,
    this.highlightType = 'peak_reactions',
    this.likesCount = 0,
    this.viewsCount = 0,
    this.postedToFeed = false,
    this.sharedToStory = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Duration get duration => endTime - startTime;

  factory ClipModel.fromMap(Map<String, dynamic> map, String docId) {
    return ClipModel(
      id: docId,
      livestreamId: map['livestreamId'] ?? '',
      hostId: map['hostId'] ?? '',
      hostUsername: map['hostUsername'] ?? '',
      hostPhotoUrl: map['hostPhotoUrl'] ?? '',
      title: map['title'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      startTime: Duration(milliseconds: map['startTimeMs'] ?? 0),
      endTime: Duration(milliseconds: map['endTimeMs'] ?? 0),
      highlightType: map['highlightType'] ?? 'peak_reactions',
      likesCount: map['likesCount'] ?? 0,
      viewsCount: map['viewsCount'] ?? 0,
      postedToFeed: map['postedToFeed'] ?? false,
      sharedToStory: map['sharedToStory'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'livestreamId': livestreamId,
      'hostId': hostId,
      'hostUsername': hostUsername,
      'hostPhotoUrl': hostPhotoUrl,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'startTimeMs': startTime.inMilliseconds,
      'endTimeMs': endTime.inMilliseconds,
      'highlightType': highlightType,
      'likesCount': likesCount,
      'viewsCount': viewsCount,
      'postedToFeed': postedToFeed,
      'sharedToStory': sharedToStory,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ClipModel copyWith({
    bool? postedToFeed,
    bool? sharedToStory,
    int? likesCount,
    int? viewsCount,
  }) {
    return ClipModel(
      id: id,
      livestreamId: livestreamId,
      hostId: hostId,
      hostUsername: hostUsername,
      hostPhotoUrl: hostPhotoUrl,
      title: title,
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      startTime: startTime,
      endTime: endTime,
      highlightType: highlightType,
      likesCount: likesCount ?? this.likesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      postedToFeed: postedToFeed ?? this.postedToFeed,
      sharedToStory: sharedToStory ?? this.sharedToStory,
      createdAt: createdAt,
    );
  }
}

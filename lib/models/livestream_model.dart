import 'package:cloud_firestore/cloud_firestore.dart';

class LiveChatMessage {
  final String id;
  final String senderId;
  final String username;
  final String userPhotoUrl;
  final String text;
  final String? reaction; // '❤️','🔥','👏','😂','😮','💎'
  final DateTime timestamp;

  LiveChatMessage({
    required this.id,
    required this.senderId,
    required this.username,
    this.userPhotoUrl = '',
    required this.text,
    this.reaction,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory LiveChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    return LiveChatMessage(
      id: docId,
      senderId: map['senderId'] ?? '',
      username: map['username'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      text: map['text'] ?? '',
      reaction: map['reaction'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'reaction': reaction,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class LivestreamModel {
  final String id;
  final String hostId;
  final String hostUsername;
  final String hostPhotoUrl;
  final String title;
  final int viewerCount;
  final bool isLive;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String replayUrl;
  final List<String> viewerIds;
  final int totalReactions;
  final int peakViewers;
  final List<String> notifiedFollowers;
  final List<String> clipIds;

  LivestreamModel({
    required this.id,
    required this.hostId,
    required this.hostUsername,
    this.hostPhotoUrl = '',
    required this.title,
    this.viewerCount = 0,
    this.isLive = true,
    DateTime? startedAt,
    this.endedAt,
    this.replayUrl = '',
    this.viewerIds = const [],
    this.totalReactions = 0,
    this.peakViewers = 0,
    this.notifiedFollowers = const [],
    this.clipIds = const [],
  }) : startedAt = startedAt ?? DateTime.now();

  factory LivestreamModel.fromMap(Map<String, dynamic> map, String docId) {
    return LivestreamModel(
      id: docId,
      hostId: map['hostId'] ?? '',
      hostUsername: map['hostUsername'] ?? '',
      hostPhotoUrl: map['hostPhotoUrl'] ?? '',
      title: map['title'] ?? '',
      viewerCount: map['viewerCount'] ?? 0,
      isLive: map['isLive'] ?? false,
      startedAt: (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
      replayUrl: map['replayUrl'] ?? '',
      viewerIds: List<String>.from(map['viewerIds'] ?? []),
      totalReactions: map['totalReactions'] ?? 0,
      peakViewers: map['peakViewers'] ?? 0,
      notifiedFollowers: List<String>.from(map['notifiedFollowers'] ?? []),
      clipIds: List<String>.from(map['clipIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'hostUsername': hostUsername,
      'hostPhotoUrl': hostPhotoUrl,
      'title': title,
      'viewerCount': viewerCount,
      'isLive': isLive,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'replayUrl': replayUrl,
      'viewerIds': viewerIds,
      'totalReactions': totalReactions,
      'peakViewers': peakViewers,
      'notifiedFollowers': notifiedFollowers,
      'clipIds': clipIds,
    };
  }

  LivestreamModel copyWith({
    int? viewerCount,
    bool? isLive,
    DateTime? endedAt,
    String? replayUrl,
    int? totalReactions,
    int? peakViewers,
    List<String>? notifiedFollowers,
    List<String>? clipIds,
  }) {
    return LivestreamModel(
      id: id,
      hostId: hostId,
      hostUsername: hostUsername,
      hostPhotoUrl: hostPhotoUrl,
      title: title,
      viewerCount: viewerCount ?? this.viewerCount,
      isLive: isLive ?? this.isLive,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      replayUrl: replayUrl ?? this.replayUrl,
      viewerIds: viewerIds,
      totalReactions: totalReactions ?? this.totalReactions,
      peakViewers: peakViewers ?? this.peakViewers,
      notifiedFollowers: notifiedFollowers ?? this.notifiedFollowers,
      clipIds: clipIds ?? this.clipIds,
    );
  }
}

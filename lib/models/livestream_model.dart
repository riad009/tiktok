class LiveChatMessage {
  final String id;
  final String senderId;
  final String username;
  final String userPhotoUrl;
  final String text;
  final String? reaction;
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'username': username,
    'userPhotoUrl': userPhotoUrl,
    'text': text,
    'reaction': reaction,
    'timestamp': timestamp.toIso8601String(),
  };
}

class LivestreamModel {
  final String id;
  final String hostId;
  final String hostUsername;
  final String hostPhotoUrl;
  final String title;
  final int viewerCount;
  final int peakViewers;
  final int totalReactions;

  /// 'idle' | 'active' | 'ended'
  final String status;
  bool get isLive => status == 'active';

  final DateTime startedAt;
  final DateTime? endedAt;
  final String replayUrl;
  final List<String> viewerIds;
  final List<String> notifiedFollowers;
  final List<String> clipIds;

  // Mux-related fields
  final String playbackUrl;
  final String muxStreamId;
  final String muxPlaybackId;
  final String streamKey;

  LivestreamModel({
    required this.id,
    required this.hostId,
    required this.hostUsername,
    this.hostPhotoUrl = '',
    required this.title,
    this.viewerCount = 0,
    this.peakViewers = 0,
    this.totalReactions = 0,
    this.status = 'idle',
    DateTime? startedAt,
    this.endedAt,
    this.replayUrl = '',
    this.viewerIds = const [],
    this.notifiedFollowers = const [],
    this.clipIds = const [],
    this.playbackUrl = '',
    this.muxStreamId = '',
    this.muxPlaybackId = '',
    this.streamKey = '',
  }) : startedAt = startedAt ?? DateTime.now();

  factory LivestreamModel.fromMap(Map<String, dynamic> map, String docId) {
    return LivestreamModel(
      id: docId,
      hostId: map['hostId'] ?? '',
      hostUsername: map['hostUsername'] ?? '',
      hostPhotoUrl: map['hostPhotoUrl'] ?? '',
      title: map['title'] ?? '',
      viewerCount: map['viewerCount'] ?? 0,
      status: (map['isLive'] == true) ? 'active' : (map['status'] ?? 'idle'),
      startedAt: map['startedAt'] is String
          ? DateTime.tryParse(map['startedAt']) ?? DateTime.now()
          : DateTime.now(),
      endedAt: map['endedAt'] is String
          ? DateTime.tryParse(map['endedAt'])
          : null,
      replayUrl: map['replayUrl'] ?? '',
      viewerIds: List<String>.from(map['viewerIds'] ?? []),
      totalReactions: map['totalReactions'] ?? 0,
      peakViewers: map['peakViewers'] ?? 0,
      notifiedFollowers: List<String>.from(map['notifiedFollowers'] ?? []),
      clipIds: List<String>.from(map['clipIds'] ?? []),
      playbackUrl: map['playbackUrl'] ?? '',
      muxStreamId: map['muxStreamId'] ?? '',
      muxPlaybackId: map['muxPlaybackId'] ?? '',
      streamKey: map['streamKey'] ?? '',
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
      'status': status,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'replayUrl': replayUrl,
      'viewerIds': viewerIds,
      'totalReactions': totalReactions,
      'peakViewers': peakViewers,
      'notifiedFollowers': notifiedFollowers,
      'clipIds': clipIds,
      'playbackUrl': playbackUrl,
      'muxStreamId': muxStreamId,
      'muxPlaybackId': muxPlaybackId,
      'streamKey': streamKey,
    };
  }

  LivestreamModel copyWith({
    String? id,
    String? hostId,
    String? hostUsername,
    String? hostPhotoUrl,
    String? title,
    int? viewerCount,
    int? peakViewers,
    String? status,
    List<String>? notifiedFollowers,
    List<String>? clipIds,
  }) {
    return LivestreamModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostUsername: hostUsername ?? this.hostUsername,
      hostPhotoUrl: hostPhotoUrl ?? this.hostPhotoUrl,
      title: title ?? this.title,
      viewerCount: viewerCount ?? this.viewerCount,
      peakViewers: peakViewers ?? this.peakViewers,
      status: status ?? this.status,
      notifiedFollowers: notifiedFollowers ?? this.notifiedFollowers,
      clipIds: clipIds ?? this.clipIds,
      playbackUrl: playbackUrl,
      muxStreamId: muxStreamId,
      muxPlaybackId: muxPlaybackId,
      streamKey: streamKey,
    );
  }

  factory LivestreamModel.fromJson(Map<String, dynamic> j) => LivestreamModel(
        id: j['id'] ?? '',
        hostId: j['hostId'] ?? '',
        hostUsername: j['hostUsername'] ?? '',
        hostPhotoUrl: j['hostPhotoUrl'] ?? '',
        title: j['title'] ?? 'Live',
        viewerCount: j['viewerCount'] ?? 0,
        peakViewers: j['peakViewers'] ?? 0,
        totalReactions: j['totalReactions'] ?? 0,
        status: j['status'] ?? 'idle',
        startedAt: DateTime.tryParse(j['startedAt']?.toString() ?? '') ??
            DateTime.now(),
        endedAt: j['endedAt'] != null
            ? DateTime.tryParse(j['endedAt'].toString())
            : null,
        playbackUrl: j['playbackUrl'] ?? '',
        muxStreamId: j['muxStreamId'] ?? '',
        muxPlaybackId: j['muxPlaybackId'] ?? '',
        streamKey: j['streamKey'] ?? '',
      );
}

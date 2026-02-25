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

  /// HLS playback URL from Mux (for viewers & replays)
  final String playbackUrl;

  /// Mux stream id
  final String muxStreamId;

  /// Mux playback id
  final String muxPlaybackId;

  /// RTMP stream key (shown to host only)
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
    this.playbackUrl = '',
    this.muxStreamId = '',
    this.muxPlaybackId = '',
    this.streamKey = '',
  }) : startedAt = startedAt ?? DateTime.now();

  LivestreamModel copyWith({
    String? id,
    String? hostId,
    String? hostUsername,
    String? hostPhotoUrl,
    String? title,
    int? viewerCount,
    int? peakViewers,
    int? totalReactions,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
    String? playbackUrl,
    String? muxStreamId,
    String? muxPlaybackId,
    String? streamKey,
  }) {
    return LivestreamModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostUsername: hostUsername ?? this.hostUsername,
      hostPhotoUrl: hostPhotoUrl ?? this.hostPhotoUrl,
      title: title ?? this.title,
      viewerCount: viewerCount ?? this.viewerCount,
      peakViewers: peakViewers ?? this.peakViewers,
      totalReactions: totalReactions ?? this.totalReactions,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      playbackUrl: playbackUrl ?? this.playbackUrl,
      muxStreamId: muxStreamId ?? this.muxStreamId,
      muxPlaybackId: muxPlaybackId ?? this.muxPlaybackId,
      streamKey: streamKey ?? this.streamKey,
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

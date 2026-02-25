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

  // Mux fields
  final String playbackUrl;
  final String muxStreamId;
  final String muxPlaybackId;
  final String streamKey;
  final String replayPlaybackUrl;

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
    this.replayPlaybackUrl = '',
  }) : startedAt = startedAt ?? DateTime.now();

  factory LivestreamModel.fromJson(Map<String, dynamic> j) => LivestreamModel(
        id: j['id']?.toString() ?? '',
        hostId: j['hostId']?.toString() ?? '',
        hostUsername: j['hostUsername']?.toString() ?? '',
        hostPhotoUrl: j['hostPhotoUrl']?.toString() ?? '',
        title: j['title']?.toString() ?? 'Live',
        viewerCount: j['viewerCount'] is int ? j['viewerCount'] : 0,
        peakViewers: j['peakViewers'] is int ? j['peakViewers'] : 0,
        totalReactions: j['totalReactions'] is int ? j['totalReactions'] : 0,
        status: j['status']?.toString() ?? 'idle',
        startedAt: DateTime.tryParse(j['startedAt']?.toString() ?? '') ??
            DateTime.now(),
        endedAt: j['endedAt'] != null
            ? DateTime.tryParse(j['endedAt'].toString())
            : null,
        playbackUrl: j['playbackUrl']?.toString() ?? '',
        muxStreamId: j['muxStreamId']?.toString() ?? '',
        muxPlaybackId: j['muxPlaybackId']?.toString() ?? '',
        streamKey: j['streamKey']?.toString() ?? '',
        replayPlaybackUrl: j['replayPlaybackUrl']?.toString() ?? '',
      );

  LivestreamModel copyWith({
    String? id,
    String? hostId,
    String? hostUsername,
    String? hostPhotoUrl,
    String? title,
    int? viewerCount,
    int? peakViewers,
    String? status,
    String? playbackUrl,
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
      playbackUrl: playbackUrl ?? this.playbackUrl,
      muxStreamId: muxStreamId,
      muxPlaybackId: muxPlaybackId,
      streamKey: streamKey,
      replayPlaybackUrl: replayPlaybackUrl,
    );
  }
}

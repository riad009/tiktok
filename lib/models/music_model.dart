class MusicTrack {
  final String id;
  final String title;
  final String artistName;
  final String? artistUserId;
  final String coverUrl;
  final String audioUrl;
  final Duration duration;
  final List<String> taggedUsers;
  final int usageCount;

  MusicTrack({
    required this.id,
    required this.title,
    required this.artistName,
    this.artistUserId,
    this.coverUrl = '',
    this.audioUrl = '',
    this.duration = const Duration(minutes: 3),
    this.taggedUsers = const [],
    this.usageCount = 0,
  });

  factory MusicTrack.fromMap(Map<String, dynamic> map, String docId) {
    return MusicTrack(
      id: docId,
      title: map['title'] ?? '',
      artistName: map['artistName'] ?? '',
      artistUserId: map['artistUserId'],
      coverUrl: map['coverUrl'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      duration: Duration(seconds: map['durationSecs'] ?? 180),
      taggedUsers: List<String>.from(map['taggedUsers'] ?? []),
      usageCount: map['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artistName': artistName,
      'artistUserId': artistUserId,
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
      'durationSecs': duration.inSeconds,
      'taggedUsers': taggedUsers,
      'usageCount': usageCount,
    };
  }
}

import 'package:uuid/uuid.dart';
import '../../models/livestream_model.dart';
import '../../models/clip_model.dart';
import '../data/mock_data.dart';

/// Thin wrapper — all livestream operations now go through
/// the Express/Mux backend via ApiService.
/// Firebase Firestore is no longer used for livestreams.
class LivestreamRepository {
  final _uuid = const Uuid();

  // In-memory stores (replace with API calls in production)
  final List<LivestreamModel> _streams = [];
  final Map<String, List<LiveChatMessage>> _chatMessages = {};
  final List<ClipModel> _clips = [];

  // ── Create Livestream ─────────────────────────────────────────
  Future<LivestreamModel> createLivestream({
    required String hostId,
    required String hostUsername,
    String hostPhotoUrl = '',
    required String title,
  }) async {
    final id = _uuid.v4();
    final stream = LivestreamModel(
      id: id,
      hostId: hostId,
      hostUsername: hostUsername,
      hostPhotoUrl: hostPhotoUrl,
      title: title,
      status: 'active',
      startedAt: DateTime.now(),
    );
    _streams.add(stream);
    return stream;
  }

  // ── End Livestream ────────────────────────────────────────────
  Future<void> endLivestream(String livestreamId) async {
    final idx = _streams.indexWhere((s) => s.id == livestreamId);
    if (idx >= 0) {
      _streams[idx] = _streams[idx].copyWith(status: 'ended');
    }
  }

  // ── Join / Leave ──────────────────────────────────────────────
  Future<void> joinLivestream(String livestreamId, String userId) async {
    // In production, send via API / socket
  }

  Future<void> leaveLivestream(String livestreamId, String userId) async {
    // In production, send via API / socket
  }

  // ── Chat ──────────────────────────────────────────────────────
  Future<void> sendChatMessage(String livestreamId, LiveChatMessage message) async {
    _chatMessages.putIfAbsent(livestreamId, () => []);
    _chatMessages[livestreamId]!.add(message);
  }

  // ── Reactions ─────────────────────────────────────────────────
  Future<void> addReaction(String livestreamId) async {
    // Stub — in production, update via API
  }

  // ── Convenience: send live chat with named params ─────────────
  Future<void> sendLiveChat({
    required String livestreamId,
    required String senderId,
    required String username,
    String userPhotoUrl = '',
    required String text,
    String? reaction,
  }) async {
    final msg = LiveChatMessage(
      id: _uuid.v4(),
      senderId: senderId,
      username: username,
      text: text,
      reaction: reaction,
      timestamp: DateTime.now(),
    );
    await sendChatMessage(livestreamId, msg);
  }


  // ── Active Streams ────────────────────────────────────────────
  Stream<List<LivestreamModel>> getActiveStreams() {
    final active = _streams.where((s) => s.isLive).toList();
    return Stream.value(active.isEmpty ? MockData.activeLivestreams : active);
  }

  // ── Replays ───────────────────────────────────────────────────
  Stream<List<LivestreamModel>> getReplays() {
    final replays = _streams.where((s) => !s.isLive).toList();
    return Stream.value(replays.isEmpty ? MockData.replays : replays);
  }

  // ── Live Chat Stream ──────────────────────────────────────────
  Stream<List<LiveChatMessage>> getLiveChatStream(String livestreamId) {
    return Stream.value(_chatMessages[livestreamId] ?? []);
  }

  // ── Follow Notifications ──────────────────────────────────────
  /// Notify followers that a creator has gone live.
  /// Returns the list of follower IDs that were notified.
  Future<List<String>> notifyFollowersOfLivestream({
    required String livestreamId,
    required String hostId,
    required String hostUsername,
    required String title,
  }) async {
    // In production, send push notifications via API
    return [];
  }

  // ── Update Peak Viewers ───────────────────────────────────────
  Future<void> updatePeakViewers(String livestreamId, int currentViewers) async {
    final idx = _streams.indexWhere((s) => s.id == livestreamId);
    if (idx >= 0 && currentViewers > _streams[idx].peakViewers) {
      _streams[idx] = _streams[idx].copyWith(peakViewers: currentViewers);
    }
  }

  // ── Clip Generation ───────────────────────────────────────────
  /// Auto-detect highlights from a completed livestream and generate clips.
  Future<List<ClipModel>> generateClipsForLivestream({
    required String livestreamId,
    required String hostId,
    required String hostUsername,
    String hostPhotoUrl = '',
    required String title,
    required Duration streamDuration,
  }) async {
    final clips = <ClipModel>[];

    // Generate a default highlight clip at the midpoint
    final midpoint = streamDuration ~/ 2;
    final clip = ClipModel(
      id: _uuid.v4(),
      livestreamId: livestreamId,
      hostId: hostId,
      hostUsername: hostUsername,
      hostPhotoUrl: hostPhotoUrl,
      title: '✨ Highlight from "$title"',
      startTime: midpoint - const Duration(seconds: 22),
      endTime: midpoint + const Duration(seconds: 23),
      highlightType: 'manual',
    );
    clips.add(clip);
    _clips.addAll(clips);

    return clips;
  }

  // ── Post Clip to Feed ─────────────────────────────────────────
  Future<void> postClipToFeed(ClipModel clip) async {
    // In production, post via API
  }

  // ── Share Clip to Story ───────────────────────────────────────
  Future<void> shareClipToStory(ClipModel clip) async {
    // In production, share via API
  }

  // ── Get Clips for Livestream ──────────────────────────────────
  Stream<List<ClipModel>> getClipsForLivestream(String livestreamId) {
    final forStream = _clips.where((c) => c.livestreamId == livestreamId).toList();
    return Stream.value(forStream);
  }

  // ── Get Clips for User ────────────────────────────────────────
  Stream<List<ClipModel>> getClipsForUser(String userId) {
    final forUser = _clips.where((c) => c.hostId == userId).toList();
    return Stream.value(forUser);
  }

  // ── Livestream Chat Moderation ────────────────────────────────
  /// Delete a chat message (moderator action)
  Future<void> deleteChatMessage(String livestreamId, String messageId) async {
    _chatMessages[livestreamId]?.removeWhere((m) => m.id == messageId);
  }

  /// Ban a user from the livestream chat
  Future<void> banUserFromChat(String livestreamId, String userId) async {
    // In production, send via API
  }

  /// Timeout a user from chat for a duration
  Future<void> timeoutUserFromChat(String livestreamId, String userId, int minutes) async {
    // In production, send via API
  }
}

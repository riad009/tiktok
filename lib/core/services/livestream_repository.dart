import '../../models/livestream_model.dart';
import '../services/api_service.dart';

/// Thin wrapper — all livestream operations now go through
/// the Express/Mux backend via ApiService.
/// Firebase Firestore is no longer used for livestreams.
class LivestreamRepository {
  // ── Create Livestream (calls Mux via backend) ─────────────────
  Future<Map<String, dynamic>?> createLivestreamMux({
    required String userId,
    required String title,
  }) async {
    return ApiService.createStream(userId: userId, title: title);
  }

  // ── Active Livestreams ────────────────────────────────────────
  Future<List<LivestreamModel>> getActiveLivestreams() async {
    try {
      final data = await ApiService.getLivestreams();
      return data.map((j) => LivestreamModel.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Replays ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getReplays({String? userId}) async {
    try {
      if (userId == null) return [];
      return ApiService.getUserReplays(userId);
    } catch (_) {
      return [];
    }
  }

  // ── Total count (admin) ───────────────────────────────────────
  Future<int> getTotalLivestreamCount() async => 0;
}

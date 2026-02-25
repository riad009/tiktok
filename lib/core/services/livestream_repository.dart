import '../services/api_service.dart';
import '../../models/livestream_model.dart';

/// Thin wrapper around ApiService for livestream operations.
/// All Firebase/Firestore dependencies have been removed.
class LivestreamRepository {
  /// Create a livestream via the backend (calls /mock for demo).
  Future<Map<String, dynamic>?> createLivestreamMux({
    required String userId,
    required String title,
  }) async {
    return ApiService.createStream(userId: userId, title: title);
  }

  /// Get all active (live) streams from the API.
  Future<List<LivestreamModel>> getActiveLivestreams() async {
    try {
      final data = await ApiService.getLivestreams();
      return data.map((j) => LivestreamModel.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get replay (VOD) streams for a user from the API.
  Future<List<Map<String, dynamic>>> getUserReplays(String userId) async {
    try {
      return await ApiService.getUserReplays(userId);
    } catch (_) {
      return [];
    }
  }
}

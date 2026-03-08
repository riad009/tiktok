import '../../models/video_model.dart';
import '../../models/comment_model.dart';
import '../data/mock_data.dart';
import 'api_service.dart';

/// Video repository — routes through PostgreSQL API.
/// Falls back to mock data when the API is unavailable.
class VideoRepository {

  // ── Feed ───────────────────────────────────────────────────────
  Stream<List<VideoModel>> feedStream({int limit = 10}) async* {
    try {
      final posts = await ApiService.getFeed();
      yield posts.take(limit).toList();
    } catch (_) {
      yield MockData.videos.take(limit).toList();
    }
  }

  Future<List<VideoModel>> getFeedVideos({dynamic startAfter, int limit = 10}) async {
    try {
      final posts = await ApiService.getFeed();
      return posts.take(limit).toList();
    } catch (_) {
      return MockData.videos.take(limit).toList();
    }
  }

  // ── User Videos ────────────────────────────────────────────────
  Stream<List<VideoModel>> userVideosStream(String uid) async* {
    try {
      final all = await ApiService.getFeed();
      yield all.where((v) => v.userId == uid).toList();
    } catch (_) {
      yield MockData.videosForUser(uid);
    }
  }

  // ── Upload ─────────────────────────────────────────────────────
  Future<VideoModel?> uploadVideo({
    required dynamic videoFile,
    required String userId,
    required String username,
    String userPhotoUrl = '',
    String caption = '',
    List<String> hashtags = const [],
    void Function(double)? onProgress,
  }) async {
    try {
      return await ApiService.createPost(
        userId: userId,
        caption: caption,
        hashtags: hashtags,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Likes ──────────────────────────────────────────────────────
  Future<void> likeVideo(String videoId, String userId) async {
    await ApiService.likePost(videoId, userId);
  }

  Future<void> unlikeVideo(String videoId, String userId) async {
    await ApiService.unlikePost(videoId, userId);
  }

  Future<bool> isLiked(String videoId, String userId) async {
    return ApiService.isLiked(videoId, userId);
  }

  Stream<bool> isLikedStream(String videoId, String userId) async* {
    try {
      yield await ApiService.isLiked(videoId, userId);
    } catch (_) {
      yield false;
    }
  }

  // ── Views ──────────────────────────────────────────────────────
  Future<void> incrementViews(String videoId) async {
    // Server-side view tracking can be added later
  }

  // ── Comments ───────────────────────────────────────────────────
  Stream<List<CommentModel>> commentsStream(String videoId) async* {
    try {
      yield await ApiService.getComments(videoId);
    } catch (_) {
      yield MockData.commentsFor(videoId);
    }
  }

  Future<void> addComment(String videoId, CommentModel comment) async {
    await ApiService.addComment(
      postId: videoId,
      userId: comment.userId,
      text: comment.text,
    );
  }

  // ── Delete ─────────────────────────────────────────────────────
  Future<void> deleteVideo(String videoId, String userId) async {
    await ApiService.adminDeletePost(videoId);
  }

  // ── Search by hashtag ──────────────────────────────────────────
  Future<List<VideoModel>> searchByHashtag(String hashtag) async {
    try {
      final all = await ApiService.getFeed();
      return all.where((v) => v.hashtags.contains(hashtag.toLowerCase())).toList();
    } catch (_) {
      return MockData.videos.where((v) => v.hashtags.contains(hashtag.toLowerCase())).toList();
    }
  }

  // ── Hashtags ───────────────────────────────────────────────────
  Future<Map<String, int>> getTrendingHashtags() async {
    return MockData.trendingHashtags;
  }
}

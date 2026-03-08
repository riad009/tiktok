import '../../models/story_model.dart';
import '../data/mock_data.dart';

/// Story repository — uses mock data.
/// Can be connected to a PostgreSQL API when story endpoints are added.
class StoryRepository {

  // ── Active Stories (non-expired) ───────────────────────────────
  Stream<List<StoryModel>> activeStoriesStream() {
    final now = DateTime.now();
    final active = MockData.stories.where((s) =>
      s.expiresAt.isAfter(now)
    ).toList();
    return Stream.value(active.isEmpty ? MockData.stories : active);
  }

  // ── Upload Story ───────────────────────────────────────────────
  Future<StoryModel> uploadStory({
    required dynamic mediaFile,
    required String userId,
    required String username,
    String userPhotoUrl = '',
    required String mediaType,
  }) async {
    final now = DateTime.now();
    final story = StoryModel(
      id: 'story-${now.millisecondsSinceEpoch}',
      userId: userId,
      username: username,
      userPhotoUrl: userPhotoUrl,
      mediaUrl: MockData.storyImg(now.millisecond),
      mediaType: mediaType,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );
    MockData.stories.add(story);
    return story;
  }

  // ── Mark Viewed ────────────────────────────────────────────────
  Future<void> markViewed(String storyId, String userId) async {
    // No-op in mock mode
  }

  // ── Delete Story ───────────────────────────────────────────────
  Future<void> deleteStory(String storyId) async {
    MockData.stories.removeWhere((s) => s.id == storyId);
  }

  // ── Stories grouped by user ────────────────────────────────────
  Map<String, List<StoryModel>> groupByUser(List<StoryModel> stories) {
    final map = <String, List<StoryModel>>{};
    for (final s in stories) {
      map.putIfAbsent(s.userId, () => []).add(s);
    }
    return map;
  }
}

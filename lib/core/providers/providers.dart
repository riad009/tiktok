import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../services/auth_persistence.dart';
import '../services/user_repository.dart';
import '../services/video_repository.dart';
import '../services/story_repository.dart';
import '../services/chat_repository.dart';
import '../services/livestream_repository.dart';
import '../services/admin_repository.dart';
import '../services/monetization_repository.dart';
import '../data/mock_data.dart';
import '../../models/user_model.dart';
import '../../models/video_model.dart';
import '../../models/story_model.dart';
import '../../models/message_model.dart';
import '../../models/comment_model.dart';
import '../../models/livestream_model.dart';
import '../../models/report_model.dart';
import '../../models/subscription_model.dart';
import '../../models/clip_model.dart';

// ── Repository Providers (kept for legacy methods) ───────────────
final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());
final videoRepositoryProvider = Provider<VideoRepository>((ref) => VideoRepository());
final storyRepositoryProvider = Provider<StoryRepository>((ref) => StoryRepository());
final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());
final livestreamRepositoryProvider = Provider<LivestreamRepository>((ref) => LivestreamRepository());
final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository());
final monetizationRepositoryProvider = Provider<MonetizationRepository>((ref) => MonetizationRepository());

// ── Auth ─────────────────────────────────────────────────────────
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Holds the currently logged-in user (null = not logged in)
final authUserProvider = StateProvider<UserModel?>((ref) => null);

/// Convenience: true when logged in
final mockLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authUserProvider) != null;
});

/// Current user as a stream (for widgets that use StreamProvider)
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authUserProvider);
  return Stream.value(user);
});

/// Current uid
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authUserProvider)?.uid;
});

// ── Session restore (runs once at startup) ────────────────────────
/// Reads SharedPreferences/localStorage and restores the saved JWT + user.
/// AuthGate waits on this before deciding which screen to show.
final sessionProvider = FutureProvider<UserModel?>((ref) async {
  try {
    final saved = await AuthPersistence.loadUser();
    if (saved != null) {
      // Update the authUserProvider with the restored user
      ref.read(authUserProvider.notifier).state = saved;
      return saved;
    }
  } catch (_) {}
  return null;
});
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authUserProvider);
  return user?.isAdmin ?? false;
});

// ── Feed (from PostgreSQL API) ───────────────────────────────────
final feedVideosProvider = FutureProvider<List<VideoModel>>((ref) async {
  // Watch authUser to refetch when logged in
  ref.watch(authUserProvider);
  return ApiService.getFeed();
});

// ── User Profile (API) ──────────────────────────────────────────
final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  return ApiService.getUser(uid);
});

// ── User Videos (API — user's posts from feed) ──────────────────
final userVideosProvider = FutureProvider.family<List<VideoModel>, String>((ref, uid) async {
  final allPosts = await ApiService.getFeed();
  return allPosts.where((v) => v.userId == uid).toList();
});

// ── All Users ────────────────────────────────────────────────────
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  return ApiService.getUsers();
});

// ── Is Following (stub — always false for now) ──────────────────
final isFollowingProvider = StreamProvider.family<bool, String>((ref, targetUid) {
  return Stream.value(false);
});

// ── Is Liked (stub — always false for now) ──────────────────────
final isLikedProvider = StreamProvider.family<bool, String>((ref, videoId) {
  return Stream.value(false);
});

// ── Liked Videos (from PostgreSQL API) ───────────────────────────
final likedVideosProvider = FutureProvider<List<VideoModel>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return [];
  final allPosts = await ApiService.getFeed();
  final liked = <VideoModel>[];
  for (final post in allPosts) {
    final isLiked = await ApiService.isLiked(post.id, uid);
    if (isLiked) liked.add(post);
  }
  return liked;
});

// ── Comments (from PostgreSQL API) ──────────────────────────────
final commentsProvider = FutureProvider.family<List<CommentModel>, String>((ref, videoId) async {
  return ApiService.getComments(videoId);
});

// ── Stories (mock for now) ──────────────────────────────────────
final storiesProvider = StreamProvider<List<StoryModel>>((ref) {
  return Stream.value(MockData.stories);
});

// ── Conversations (from PostgreSQL API) ─────────────────────────
final conversationsProvider = FutureProvider<List<ConversationModel>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return [];
  return ApiService.getConversations(uid);
});

// ── Messages (from PostgreSQL API) ──────────────────────────────
final messagesProvider = FutureProvider.family<List<MessageModel>, String>((ref, convoId) async {
  return ApiService.getMessages(convoId);
});

// ── Trending Hashtags (mock) ────────────────────────────────────
final trendingHashtagsProvider = FutureProvider<Map<String, int>>((ref) async {
  return MockData.trendingHashtags;
});

// ── Livestreams ──────────────────────────────────────────────────
final activeLivestreamsProvider = FutureProvider<List<LivestreamModel>>((ref) async {
  try {
    final data = await ApiService.getLivestreams();
    if (data.isNotEmpty) {
      return data.map((j) => LivestreamModel(
        id: j['id'] ?? '',
        hostId: j['hostId'] ?? '',
        hostUsername: j['hostUsername'] ?? '',
        hostPhotoUrl: j['hostPhotoUrl'] ?? '',
        title: j['title'] ?? 'Live',
        viewerCount: j['viewerCount'] ?? 0,
        peakViewers: j['peakViewers'] ?? 0,
        status: j['status'] ?? 'active',
        startedAt: DateTime.tryParse(j['startedAt']?.toString() ?? '') ?? DateTime.now(),
        playbackUrl: j['playbackUrl'] ?? '',
        muxStreamId: j['muxStreamId'] ?? '',
        muxPlaybackId: j['muxPlaybackId'] ?? '',
        streamKey: j['streamKey'] ?? '',
      )).toList();
    }
  } catch (_) {}
  return MockData.activeLivestreams;
});

final livestreamProvider = StreamProvider.family<LivestreamModel?, String>((ref, id) {
  try {
    return Stream.value(
      [...MockData.activeLivestreams, ...MockData.replays].firstWhere((l) => l.id == id),
    );
  } catch (_) {
    return Stream.value(null);
  }
});

final liveChatProvider = StreamProvider.family<List<LiveChatMessage>, String>((ref, livestreamId) {
  return Stream.value([
    LiveChatMessage(id: 'lc1', senderId: 'user-005', username: 'tech_alex',
      text: 'This is awesome! 🔥', timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
    LiveChatMessage(id: 'lc2', senderId: 'user-002', username: 'sarah_creates',
      text: 'Love the vibes!', timestamp: DateTime.now().subtract(const Duration(minutes: 1))),
    LiveChatMessage(id: 'lc3', senderId: 'user-007', username: 'traveler_jay',
      text: 'Can you do a tutorial?', timestamp: DateTime.now().subtract(const Duration(seconds: 30))),
    LiveChatMessage(id: 'lc4', senderId: 'user-008', username: 'fitness_nina',
      text: '🙌🙌🙌', timestamp: DateTime.now()),
  ]);
});

// ── Livestream Clips (mock) ─────────────────────────────────────
final livestreamClipsProvider = FutureProvider.family<List<ClipModel>, String>((ref, livestreamId) async {
  return MockData.clipsForLivestream(livestreamId);
});

final userClipsProvider = FutureProvider.family<List<ClipModel>, String>((ref, userId) async {
  return MockData.clipsForUser(userId);
});

final allClipsProvider = FutureProvider<List<ClipModel>>((ref) async {
  return MockData.livestreamClips;
});

// ── Group Conversations (from PostgreSQL API) ──────────────────
final groupConversationsProvider = FutureProvider<List<ConversationModel>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return [];
  return ApiService.getGroupConversations(uid);
});

// ── Blocked Users ───────────────────────────────────────────────
final blockedUsersProvider = StateProvider<List<String>>((ref) {
  return List<String>.from(MockData.blockedUserIds);
});

// ── Reports (from PostgreSQL API) ────────────────────────────────
final reportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  return ApiService.getAdminReports();
});

// ── Subscriptions (mock) ────────────────────────────────────────
final creatorSubscribersProvider = StreamProvider.family<List<SubscriptionModel>, String>((ref, creatorId) {
  return Stream.value(MockData.subscribers);
});

final creatorTipsProvider = StreamProvider.family<List<TipModel>, String>((ref, userId) {
  return Stream.value(MockData.tips);
});

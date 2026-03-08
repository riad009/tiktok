import '../../models/user_model.dart';
import '../data/mock_data.dart';
import 'api_service.dart';

/// User repository — routes through PostgreSQL API.
/// Falls back to mock data when the API is unavailable.
class UserRepository {
  // ── Create / Read ──────────────────────────────────────────────
  Future<void> createUser(UserModel user) async {
    // User creation is handled by ApiService.signup()
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      return await ApiService.getUser(uid);
    } catch (_) {
      return MockData.userById(uid);
    }
  }

  Stream<UserModel?> userStream(String uid) async* {
    try {
      final user = await ApiService.getUser(uid);
      yield user;
    } catch (_) {
      yield MockData.userById(uid);
    }
  }

  // ── Update Profile ─────────────────────────────────────────────
  Future<UserModel?> updateProfile(String uid, {String? displayName, String? bio, String? photoUrl}) async {
    try {
      return await ApiService.updateUserProfile(uid, displayName: displayName, bio: bio, photoUrl: photoUrl);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> uploadProfilePhoto(String uid, String base64Image) async {
    try {
      return await ApiService.uploadUserPhoto(uid, base64Image);
    } catch (_) {
      return null;
    }
  }

  // ── Follow / Unfollow ──────────────────────────────────────────
  Future<void> followUser(String currentUid, String targetUid) async {
    // Follow endpoint can be added to the server later
  }

  Future<void> unfollowUser(String currentUid, String targetUid) async {
    // Unfollow endpoint can be added to the server later
  }

  Future<bool> isFollowing(String currentUid, String targetUid) async {
    return false;
  }

  Stream<bool> isFollowingStream(String currentUid, String targetUid) {
    return Stream.value(false);
  }

  // ── Search ─────────────────────────────────────────────────────
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final allUsers = await ApiService.getUsers();
      final lq = query.toLowerCase();
      return allUsers.where((u) =>
        u.username.toLowerCase().contains(lq) ||
        u.displayName.toLowerCase().contains(lq)
      ).toList();
    } catch (_) {
      final lq = query.toLowerCase();
      return MockData.users.where((u) =>
        u.username.toLowerCase().contains(lq) ||
        u.displayName.toLowerCase().contains(lq)
      ).toList();
    }
  }

  // ── Followers List ─────────────────────────────────────────────
  Future<List<UserModel>> getFollowers(String uid) async {
    return [];
  }
}

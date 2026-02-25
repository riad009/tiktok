import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

/// Persists auth session to SharedPreferences so the user stays logged in
/// across hot restarts, app restarts, and refreshes.
class AuthPersistence {
  static const _key = 'auth_user_json';

  /// Save user to disk
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'uid': user.uid,
      'username': user.username,
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoUrl,
      'bio': user.bio,
      'followersCount': user.followersCount,
      'followingCount': user.followingCount,
      'postsCount': user.postsCount,
      'role': user.role,
      'isVerified': user.isVerified,
      'badgeType': user.badgeType,
      'subscriberCount': user.subscriberCount,
      'totalTips': user.totalTips,
      'isBanned': user.isBanned,
    });
    await prefs.setString(_key, json);
  }

  /// Load user from disk (returns null if not saved)
  static Future<UserModel?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel(
        uid: map['uid'] ?? '',
        username: map['username'] ?? '',
        displayName: map['displayName'] ?? '',
        email: map['email'] ?? '',
        photoUrl: map['photoUrl'] ?? '',
        bio: map['bio'] ?? '',
        followersCount: map['followersCount'] ?? 0,
        followingCount: map['followingCount'] ?? 0,
        postsCount: map['postsCount'] ?? 0,
        role: map['role'] ?? 'user',
        isVerified: map['isVerified'] ?? false,
        badgeType: map['badgeType'] ?? '',
        subscriberCount: map['subscriberCount'] ?? 0,
        totalTips: (map['totalTips'] as num?)?.toDouble() ?? 0.0,
        isBanned: map['isBanned'] ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  /// Clear saved user (for logout)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

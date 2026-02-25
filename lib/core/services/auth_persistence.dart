import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

/// Persists the JWT token and user object to SharedPreferences
/// (which maps to localStorage on Flutter Web).
class AuthPersistence {
  static const _keyToken = 'ac_token';
  static const _keyUser  = 'ac_user';

  static Future<void> save({required String token, required UserModel user}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(_userToJson(user)));
  }

  static Future<({String token, UserModel user})?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final userStr = prefs.getString(_keyUser);
    if (token == null || userStr == null) return null;
    try {
      final j = jsonDecode(userStr) as Map<String, dynamic>;
      return (token: token, user: _userFromJson(j));
    } catch (_) {
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  static Map<String, dynamic> _userToJson(UserModel u) => {
    'uid': u.uid,
    'username': u.username,
    'displayName': u.displayName,
    'email': u.email,
    'photoUrl': u.photoUrl,
    'bio': u.bio,
    'role': u.role,
    'isVerified': u.isVerified,
    'followersCount': u.followersCount,
    'followingCount': u.followingCount,
    'postsCount': u.postsCount,
  };

  static UserModel _userFromJson(Map<String, dynamic> j) => UserModel(
    uid: j['uid'] ?? '',
    username: j['username'] ?? '',
    displayName: j['displayName'] ?? '',
    email: j['email'] ?? '',
    photoUrl: j['photoUrl'] ?? '',
    bio: j['bio'] ?? '',
    role: j['role'] ?? 'user',
    isVerified: j['isVerified'] ?? false,
    followersCount: j['followersCount'] ?? 0,
    followingCount: j['followingCount'] ?? 0,
    postsCount: j['postsCount'] ?? 0,
  );
}

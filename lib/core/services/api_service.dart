import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kReleaseMode;
import '../../models/user_model.dart';
import '../../models/video_model.dart';
import '../../models/message_model.dart';
import '../../models/comment_model.dart';

/// HTTP client that talks to the Express API.
class ApiService {
  // In debug: local server; in release: same-origin (Vercel)
  static const String _baseUrl = kReleaseMode
      ? '/api'
      : 'http://localhost:3001/api';

  /// Public accessor for the API base URL (used by music search proxy etc.)
  static String get baseUrl => _baseUrl;

  // ── Auth ─────────────────────────────────────────────────────
  static Future<UserModel?> signup({
    required String username,
    required String email,
    required String password,
    String displayName = '',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'displayName': displayName.isNotEmpty ? displayName : username,
      }),
    );
    if (res.statusCode == 201) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      _token = j['token'] as String?;  // store JWT
      return _parseUser(j);
    }
    throw Exception(jsonDecode(res.body)['error'] ?? 'Signup failed');
  }

  static Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      _token = j['token'] as String?;  // store JWT
      return _parseUser(j);
    }
    throw Exception(jsonDecode(res.body)['error'] ?? 'Login failed');
  }

  // ── Users ────────────────────────────────────────────────────
  static Future<List<UserModel>> getUsers() async {
    final res = await http.get(Uri.parse('$_baseUrl/users'));
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((j) => _parseUser(j)).toList();
    }
    return [];
  }

  static Future<UserModel?> getUser(String id) async {
    final res = await http.get(Uri.parse('$_baseUrl/users/$id'));
    if (res.statusCode == 200) {
      return _parseUser(jsonDecode(res.body));
    }
    return null;
  }

  // ── Feed / Posts ─────────────────────────────────────────────
  static Future<List<VideoModel>> getFeed() async {
    final res = await http.get(Uri.parse('$_baseUrl/feed'));
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((j) => _parsePost(j)).toList();
    }
    return [];
  }

  static Future<VideoModel?> createPost({
    required String userId,
    String caption = '',
    String videoUrl = '',
    String thumbnailUrl = '',
    String imageUrl = '',
    List<String> hashtags = const [],
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/posts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'caption': caption,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'imageUrl': imageUrl,
        'hashtags': hashtags,
      }),
    );
    if (res.statusCode == 201) {
      return _parsePost(jsonDecode(res.body));
    }
    return null;
  }

  // ── Comments ─────────────────────────────────────────────────
  static Future<List<CommentModel>> getComments(String postId) async {
    final res = await http.get(Uri.parse('$_baseUrl/comments/$postId'));
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((j) => _parseComment(j)).toList();
    }
    return [];
  }

  static Future<CommentModel?> addComment({
    required String postId,
    required String userId,
    required String text,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'postId': postId,
        'userId': userId,
        'text': text,
      }),
    );
    if (res.statusCode == 201) {
      return _parseComment(jsonDecode(res.body));
    }
    return null;
  }

  // ── Likes ────────────────────────────────────────────────────
  static Future<bool> isLiked(String postId, String userId) async {
    final res = await http.get(Uri.parse('$_baseUrl/likes/check/$postId/$userId'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['liked'] == true;
    }
    return false;
  }

  static Future<void> likePost(String postId, String userId) async {
    await http.post(
      Uri.parse('$_baseUrl/likes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'postId': postId, 'userId': userId}),
    );
  }

  static Future<void> unlikePost(String postId, String userId) async {
    await http.delete(
      Uri.parse('$_baseUrl/likes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'postId': postId, 'userId': userId}),
    );
  }

  // ── Conversations ────────────────────────────────────────────
  static Future<List<ConversationModel>> getConversations(String userId) async {
    final res = await http.get(Uri.parse('$_baseUrl/conversations/$userId'));
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((j) => _parseConversation(j, userId)).toList();
    }
    return [];
  }

  static Future<ConversationModel?> getOrCreateConversation(String userId1, String userId2) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/conversations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId1': userId1, 'userId2': userId2}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return _parseConversation(jsonDecode(res.body), userId1);
    }
    return null;
  }

  // ── Messages ─────────────────────────────────────────────────
  static Future<List<MessageModel>> getMessages(String conversationId) async {
    final res = await http.get(Uri.parse('$_baseUrl/messages/$conversationId'));
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((j) => _parseMessage(j)).toList();
    }
    return [];
  }

  static Future<MessageModel?> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
      }),
    );
    if (res.statusCode == 201) {
      return _parseMessage(jsonDecode(res.body));
    }
    return null;
  }

  // ── Livestreams (Mux) ────────────────────────────────────────
  /// Creates a Mux live stream. Returns {streamKey, rtmpUrl, streamId, playbackId}
  static Future<Map<String, dynamic>?> createStream({
    required String userId,
    required String title,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/livestreams'),
        headers: _headers,
        body: jsonEncode({'userId': userId, 'title': title}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Gets all active live streams from the DB.
  static Future<List<Map<String, dynamic>>> getLivestreams() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/livestreams'));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return [];
  }

  /// Gets replay (VOD) assets for a user.
  static Future<List<Map<String, dynamic>>> getUserReplays(String userId) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/livestreams/replays/$userId'));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return [];
  }

  // ── Parsers ──────────────────────────────────────────────────

  static UserModel _parseUser(Map<String, dynamic> j) {
    return UserModel(
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

  static VideoModel _parsePost(Map<String, dynamic> j) {
    return VideoModel(
      id: j['id'] ?? '',
      userId: j['userId'] ?? '',
      username: j['username'] ?? '',
      userPhotoUrl: j['userPhotoUrl'] ?? '',
      videoUrl: j['videoUrl'] ?? '',
      thumbnailUrl: j['thumbnailUrl'] ?? '',
      caption: j['caption'] ?? '',
      hashtags: List<String>.from(j['hashtags'] ?? []),
      likesCount: j['likesCount'] ?? 0,
      commentsCount: j['commentsCount'] ?? 0,
      viewsCount: j['viewsCount'] ?? 0,
      imageUrl: j['imageUrl'] ?? '',
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
    );
  }

  static CommentModel _parseComment(Map<String, dynamic> j) {
    return CommentModel(
      id: j['id'] ?? '',
      userId: j['userId'] ?? '',
      username: j['username'] ?? '',
      userPhotoUrl: j['userPhotoUrl'] ?? '',
      text: j['text'] ?? '',
    );
  }

  static ConversationModel _parseConversation(Map<String, dynamic> j, String currentUid) {
    final otherId = j['otherUserId'] ?? '';
    final otherName = j['otherDisplayName'] ?? j['otherUsername'] ?? '';
    final otherPhoto = j['otherPhotoUrl'] ?? '';

    return ConversationModel(
      id: j['id'] ?? '',
      participants: [currentUid, otherId],
      lastMessage: j['lastMessage'] ?? '',
      lastMessageTime: j['lastMessageTime'] != null
          ? DateTime.tryParse(j['lastMessageTime'].toString())
          : null,
      participantNames: {currentUid: 'Me', otherId: otherName},
      participantPhotos: {currentUid: '', otherId: otherPhoto},
    );
  }

  static MessageModel _parseMessage(Map<String, dynamic> j) {
    return MessageModel(
      id: j['id'] ?? '',
      senderId: j['senderId'] ?? '',
      text: j['text'] ?? '',
      isRead: j['isRead'] ?? false,
      timestamp: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
    );
  }
}

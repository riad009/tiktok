import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String email;
  final String photoUrl;
  final String bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final String role; // 'user', 'creator', 'admin'
  final bool isVerified;
  final String badgeType; // '', 'verified', 'top_creator', 'rising_star'
  final int subscriberCount;
  final double totalTips;
  final bool isBanned;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.email,
    this.photoUrl = '',
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.role = 'user',
    this.isVerified = false,
    this.badgeType = '',
    this.subscriberCount = 0,
    this.totalTips = 0.0,
    this.isBanned = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == 'admin' || email == 'admin@gmail.com';
  bool get isCreator => role == 'creator' || role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> map) {
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
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'role': role,
      'isVerified': isVerified,
      'badgeType': badgeType,
      'subscriberCount': subscriberCount,
      'totalTips': totalTips,
      'isBanned': isBanned,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? email,
    String? photoUrl,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    String? role,
    bool? isVerified,
    String? badgeType,
    int? subscriberCount,
    double? totalTips,
    bool? isBanned,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      badgeType: badgeType ?? this.badgeType,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      totalTips: totalTips ?? this.totalTips,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

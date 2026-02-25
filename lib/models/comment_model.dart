import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String username;
  final String userPhotoUrl;
  final String text;
  final int likesCount;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhotoUrl = '',
    required this.text,
    this.likesCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CommentModel.fromMap(Map<String, dynamic> map, String docId) {
    return CommentModel(
      id: docId,
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      text: map['text'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'likesCount': likesCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

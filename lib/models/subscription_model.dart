import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String subscriberId;
  final String creatorId;
  final String tier; // 'pro', 'vip'
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  SubscriptionModel({
    required this.id,
    required this.subscriberId,
    required this.creatorId,
    this.tier = 'pro',
    this.price = 4.99,
    DateTime? startDate,
    DateTime? endDate,
    this.isActive = true,
  })  : startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now().add(const Duration(days: 30));

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String docId) {
    return SubscriptionModel(
      id: docId,
      subscriberId: map['subscriberId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      tier: map['tier'] ?? 'pro',
      price: (map['price'] as num?)?.toDouble() ?? 4.99,
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subscriberId': subscriberId,
      'creatorId': creatorId,
      'tier': tier,
      'price': price,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
    };
  }
}

class TipModel {
  final String id;
  final String senderId;
  final String senderUsername;
  final String receiverId;
  final double amount;
  final String? livestreamId;
  final String message;
  final DateTime timestamp;

  TipModel({
    required this.id,
    required this.senderId,
    this.senderUsername = '',
    required this.receiverId,
    required this.amount,
    this.livestreamId,
    this.message = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TipModel.fromMap(Map<String, dynamic> map, String docId) {
    return TipModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderUsername: map['senderUsername'] ?? '',
      receiverId: map['receiverId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      livestreamId: map['livestreamId'],
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderUsername': senderUsername,
      'receiverId': receiverId,
      'amount': amount,
      'livestreamId': livestreamId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

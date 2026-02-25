import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/subscription_model.dart';
import '../constants/app_constants.dart';

class MonetizationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _subsCol =>
      _firestore.collection(AppConstants.subscriptionsCollection);

  CollectionReference<Map<String, dynamic>> get _tipsCol =>
      _firestore.collection(AppConstants.tipsCollection);

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection(AppConstants.usersCollection);

  // ── Tips ───────────────────────────────────────────────────────
  Future<void> sendTip({
    required String senderId,
    required String senderUsername,
    required String receiverId,
    required double amount,
    String? livestreamId,
    String message = '',
  }) async {
    final id = _uuid.v4();
    final tip = TipModel(
      id: id,
      senderId: senderId,
      senderUsername: senderUsername,
      receiverId: receiverId,
      amount: amount,
      livestreamId: livestreamId,
      message: message,
    );
    await _tipsCol.doc(id).set(tip.toMap());
    // Update receiver's total tips
    await _usersCol.doc(receiverId).update({
      'totalTips': FieldValue.increment(amount),
    });
  }

  Stream<List<TipModel>> tipsForUserStream(String userId) {
    return _tipsCol
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TipModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Subscriptions ─────────────────────────────────────────────
  Future<void> createSubscription({
    required String subscriberId,
    required String creatorId,
    String tier = 'pro',
    double price = 4.99,
  }) async {
    final id = _uuid.v4();
    final sub = SubscriptionModel(
      id: id,
      subscriberId: subscriberId,
      creatorId: creatorId,
      tier: tier,
      price: price,
    );
    await _subsCol.doc(id).set(sub.toMap());
    // Update creator subscriber count
    await _usersCol.doc(creatorId).update({
      'subscriberCount': FieldValue.increment(1),
    });
  }

  Future<void> cancelSubscription(String subscriptionId, String creatorId) async {
    await _subsCol.doc(subscriptionId).update({'isActive': false});
    await _usersCol.doc(creatorId).update({
      'subscriberCount': FieldValue.increment(-1),
    });
  }

  Stream<List<SubscriptionModel>> subscribersStream(String creatorId) {
    return _subsCol
        .where('creatorId', isEqualTo: creatorId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SubscriptionModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<bool> isSubscribed(String subscriberId, String creatorId) async {
    final snap = await _subsCol
        .where('subscriberId', isEqualTo: subscriberId)
        .where('creatorId', isEqualTo: creatorId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── Creator Earnings ──────────────────────────────────────────
  Future<Map<String, double>> getCreatorEarnings(String creatorId) async {
    // Get tips total
    final tipsSnap = await _tipsCol
        .where('receiverId', isEqualTo: creatorId)
        .get();
    double totalTips = 0;
    for (final doc in tipsSnap.docs) {
      totalTips += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
    }

    // Get subscription revenue
    final subsSnap = await _subsCol
        .where('creatorId', isEqualTo: creatorId)
        .where('isActive', isEqualTo: true)
        .get();
    double subRevenue = 0;
    for (final doc in subsSnap.docs) {
      subRevenue += (doc.data()['price'] as num?)?.toDouble() ?? 0;
    }

    return {
      'totalTips': totalTips,
      'subscriptionRevenue': subRevenue,
      'totalEarnings': totalTips + subRevenue,
    };
  }
}

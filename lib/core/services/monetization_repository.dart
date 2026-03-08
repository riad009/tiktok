import '../../models/subscription_model.dart';
import '../data/mock_data.dart';

/// Monetization repository — uses mock data.
/// Can be connected to a real payment API (Stripe) when ready.
class MonetizationRepository {

  // ── Tips ───────────────────────────────────────────────────────
  Future<void> sendTip({
    required String senderId,
    required String senderUsername,
    required String receiverId,
    required double amount,
    String? livestreamId,
    String message = '',
  }) async {
    MockData.tips.add(TipModel(
      id: 'tip-${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderUsername: senderUsername,
      receiverId: receiverId,
      amount: amount,
      livestreamId: livestreamId,
      message: message,
    ));
  }

  Stream<List<TipModel>> tipsForUserStream(String userId) {
    final userTips = MockData.tips.where((t) => t.receiverId == userId).toList();
    return Stream.value(userTips);
  }

  // ── Subscriptions ─────────────────────────────────────────────
  Future<void> createSubscription({
    required String subscriberId,
    required String creatorId,
    String tier = 'pro',
    double price = 4.99,
  }) async {
    MockData.subscribers.add(SubscriptionModel(
      id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
      subscriberId: subscriberId,
      creatorId: creatorId,
      tier: tier,
      price: price,
    ));
  }

  Future<void> cancelSubscription(String subscriptionId, String creatorId) async {
    MockData.subscribers.removeWhere((s) => s.id == subscriptionId);
  }

  Stream<List<SubscriptionModel>> subscribersStream(String creatorId) {
    final subs = MockData.subscribers.where((s) => s.creatorId == creatorId && s.isActive).toList();
    return Stream.value(subs);
  }

  Future<bool> isSubscribed(String subscriberId, String creatorId) async {
    return MockData.subscribers.any((s) =>
      s.subscriberId == subscriberId && s.creatorId == creatorId && s.isActive);
  }

  // ── Creator Earnings ──────────────────────────────────────────
  Future<Map<String, double>> getCreatorEarnings(String creatorId) async {
    double totalTips = 0;
    for (final tip in MockData.tips.where((t) => t.receiverId == creatorId)) {
      totalTips += tip.amount;
    }

    double subRevenue = 0;
    for (final sub in MockData.subscribers.where((s) => s.creatorId == creatorId && s.isActive)) {
      subRevenue += sub.price;
    }

    return {
      'totalTips': totalTips,
      'subscriptionRevenue': subRevenue,
      'totalEarnings': totalTips + subRevenue,
    };
  }
}

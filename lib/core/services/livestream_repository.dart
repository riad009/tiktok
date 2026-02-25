import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/livestream_model.dart';
import '../constants/app_constants.dart';

class LivestreamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _livestreamsCol =>
      _firestore.collection(AppConstants.livestreamsCollection);

  // ── Create Livestream ─────────────────────────────────────────
  Future<LivestreamModel> createLivestream({
    required String hostId,
    required String hostUsername,
    String hostPhotoUrl = '',
    required String title,
  }) async {
    final id = _uuid.v4();
    final livestream = LivestreamModel(
      id: id,
      hostId: hostId,
      hostUsername: hostUsername,
      hostPhotoUrl: hostPhotoUrl,
      title: title,
      isLive: true,
      startedAt: DateTime.now(),
    );
    await _livestreamsCol.doc(id).set(livestream.toMap());
    return livestream;
  }

  // ── End Livestream ────────────────────────────────────────────
  Future<void> endLivestream(String livestreamId) async {
    await _livestreamsCol.doc(livestreamId).update({
      'isLive': false,
      'endedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── Active Livestreams ────────────────────────────────────────
  Stream<List<LivestreamModel>> activeLivestreamsStream() {
    return _livestreamsCol
        .where('isLive', isEqualTo: true)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LivestreamModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Single Livestream ─────────────────────────────────────────
  Stream<LivestreamModel?> livestreamStream(String livestreamId) {
    return _livestreamsCol.doc(livestreamId).snapshots().map((snap) {
      if (snap.exists) return LivestreamModel.fromMap(snap.data()!, snap.id);
      return null;
    });
  }

  // ── Join / Leave ──────────────────────────────────────────────
  Future<void> joinLivestream(String livestreamId, String userId) async {
    await _livestreamsCol.doc(livestreamId).update({
      'viewerCount': FieldValue.increment(1),
      'viewerIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> leaveLivestream(String livestreamId, String userId) async {
    await _livestreamsCol.doc(livestreamId).update({
      'viewerCount': FieldValue.increment(-1),
      'viewerIds': FieldValue.arrayRemove([userId]),
    });
  }

  // ── Live Chat ─────────────────────────────────────────────────
  Stream<List<LiveChatMessage>> liveChatStream(String livestreamId) {
    return _livestreamsCol
        .doc(livestreamId)
        .collection(AppConstants.liveChatCollection)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LiveChatMessage.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> sendLiveChat({
    required String livestreamId,
    required String senderId,
    required String username,
    String userPhotoUrl = '',
    required String text,
    String? reaction,
  }) async {
    final ref = _livestreamsCol
        .doc(livestreamId)
        .collection(AppConstants.liveChatCollection)
        .doc();
    final msg = LiveChatMessage(
      id: ref.id,
      senderId: senderId,
      username: username,
      userPhotoUrl: userPhotoUrl,
      text: text,
      reaction: reaction,
    );
    await ref.set(msg.toMap());
  }

  // ── Reactions ─────────────────────────────────────────────────
  Future<void> addReaction(String livestreamId) async {
    await _livestreamsCol.doc(livestreamId).update({
      'totalReactions': FieldValue.increment(1),
    });
  }

  // ── Replays ───────────────────────────────────────────────────
  Future<List<LivestreamModel>> getReplays({int limit = 20}) async {
    final snap = await _livestreamsCol
        .where('isLive', isEqualTo: false)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => LivestreamModel.fromMap(d.data(), d.id)).toList();
  }

  // ── All livestreams (for admin) ───────────────────────────────
  Future<int> getTotalLivestreamCount() async {
    final snap = await _livestreamsCol.count().get();
    return snap.count ?? 0;
  }
}

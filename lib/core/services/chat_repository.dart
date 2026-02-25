import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/message_model.dart';
import '../constants/app_constants.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _convosCol =>
      _firestore.collection(AppConstants.conversationsCollection);

  // ── Conversations ──────────────────────────────────────────────
  Stream<List<ConversationModel>> conversationsStream(String userId) {
    return _convosCol
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ConversationModel.fromMap(d.data(), d.id)).toList());
  }

  // ── Messages ───────────────────────────────────────────────────
  Stream<List<MessageModel>> messagesStream(String conversationId) {
    return _convosCol
        .doc(conversationId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromMap(d.data(), d.id)).toList());
  }

  // ── Send Message ───────────────────────────────────────────────
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final msgRef = _convosCol.doc(conversationId).collection(AppConstants.messagesCollection).doc();
    final now = DateTime.now();
    final message = MessageModel(
      id: msgRef.id,
      senderId: senderId,
      text: text,
      timestamp: now,
    );

    final batch = _firestore.batch();
    batch.set(msgRef, message.toMap());
    batch.update(_convosCol.doc(conversationId), {
      'lastMessage': text,
      'lastMessageTime': Timestamp.fromDate(now),
    });
    await batch.commit();
  }

  // ── Get or Create Conversation ─────────────────────────────────
  Future<ConversationModel> getOrCreateConversation({
    required String currentUid,
    required String otherUid,
    required String currentName,
    required String otherName,
    String currentPhoto = '',
    String otherPhoto = '',
  }) async {
    // Check if conversation already exists
    final existing = await _convosCol
        .where('participants', arrayContains: currentUid)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUid)) {
        return ConversationModel.fromMap(doc.data(), doc.id);
      }
    }

    // Create new conversation
    final ref = _convosCol.doc();
    final convo = ConversationModel(
      id: ref.id,
      participants: [currentUid, otherUid],
      participantNames: {currentUid: currentName, otherUid: otherName},
      participantPhotos: {currentUid: currentPhoto, otherUid: otherPhoto},
    );
    await ref.set(convo.toMap());
    return convo;
  }

  // ── Mark as Read ───────────────────────────────────────────────
  Future<void> markAsRead(String conversationId, String userId) async {
    final unread = await _convosCol
        .doc(conversationId)
        .collection(AppConstants.messagesCollection)
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

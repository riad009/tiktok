import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/message_model.dart';

class ChatRepository {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── Conversations ─────────────────────────────────────────────
  Stream<List<ConversationModel>> getConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ConversationModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Messages ──────────────────────────────────────────────────
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Send Message ──────────────────────────────────────────────
  Future<void> sendMessage(String conversationId, MessageModel message) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());

    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': message.mediaType.isNotEmpty
          ? '📎 ${message.mediaType}'
          : message.text,
      'lastMessageTime': Timestamp.fromDate(message.timestamp),
    });
  }

  // ── Mark as Read ──────────────────────────────────────────────
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final unread = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      if (doc.data()['senderId'] != userId) {
        await doc.reference.update({'isRead': true});
      }
    }
  }

  // ── Get or Create DM Conversation ─────────────────────────────
  Future<ConversationModel> getOrCreateConversation({
    required String userId,
    required String otherUserId,
    required Map<String, String> names,
    required Map<String, String> photos,
  }) async {
    final existing = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .where('isGroupChat', isEqualTo: false)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUserId) && participants.length == 2) {
        return ConversationModel.fromMap(doc.data(), doc.id);
      }
    }

    // Create new conversation
    final id = _uuid.v4();
    final convo = ConversationModel(
      id: id,
      participants: [userId, otherUserId],
      participantNames: names,
      participantPhotos: photos,
    );
    await _firestore.collection('conversations').doc(id).set(convo.toMap());
    return convo;
  }

  // ══════════════════════════════════════════════════════════════
  //  GROUP CHAT
  // ══════════════════════════════════════════════════════════════

  /// Create a new group conversation.
  Future<ConversationModel> createGroupConversation({
    required String createdBy,
    required String groupName,
    required List<String> participantIds,
    required Map<String, String> names,
    required Map<String, String> photos,
    String groupPhotoUrl = '',
  }) async {
    final id = _uuid.v4();
    final convo = ConversationModel(
      id: id,
      participants: participantIds,
      participantNames: names,
      participantPhotos: photos,
      isGroupChat: true,
      groupName: groupName,
      groupPhotoUrl: groupPhotoUrl,
      createdBy: createdBy,
      adminIds: [createdBy],
    );
    await _firestore.collection('conversations').doc(id).set(convo.toMap());
    return convo;
  }

  /// Add a member to a group chat.
  Future<void> addGroupMember({
    required String conversationId,
    required String userId,
    required String userName,
    required String userPhoto,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'participants': FieldValue.arrayUnion([userId]),
      'participantNames.$userId': userName,
      'participantPhotos.$userId': userPhoto,
    });
  }

  /// Remove a member from a group chat.
  Future<void> removeGroupMember({
    required String conversationId,
    required String userId,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'participants': FieldValue.arrayRemove([userId]),
    });
  }

  /// Promote a member to admin.
  Future<void> promoteToAdmin({
    required String conversationId,
    required String userId,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'adminIds': FieldValue.arrayUnion([userId]),
    });
  }

  /// Demote an admin to regular member.
  Future<void> demoteFromAdmin({
    required String conversationId,
    required String userId,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'adminIds': FieldValue.arrayRemove([userId]),
    });
  }

  /// Update group name.
  Future<void> updateGroupName({
    required String conversationId,
    required String name,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'groupName': name,
    });
  }

  /// Leave a group chat.
  Future<void> leaveGroup({
    required String conversationId,
    required String userId,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'participants': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  MEDIA SHARING
  // ══════════════════════════════════════════════════════════════

  /// Send a message with media attachment.
  Future<void> sendMediaMessage({
    required String conversationId,
    required String senderId,
    required String mediaUrl,
    required String mediaType, // 'image', 'video', 'audio', 'file'
    String text = '',
  }) async {
    final message = MessageModel(
      id: _uuid.v4(),
      senderId: senderId,
      text: text,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      timestamp: DateTime.now(),
    );
    await sendMessage(conversationId, message);
  }

  // ══════════════════════════════════════════════════════════════
  //  MESSAGE REACTIONS
  // ══════════════════════════════════════════════════════════════

  /// Add a reaction to a message.
  Future<void> addMessageReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$emoji': FieldValue.arrayUnion([userId]),
    });
  }

  /// Remove a reaction from a message.
  Future<void> removeMessageReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$emoji': FieldValue.arrayRemove([userId]),
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  BLOCK & REPORT
  // ══════════════════════════════════════════════════════════════

  /// Block a user.
  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked')
        .doc(blockedUserId)
        .set({
      'blockedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Unblock a user.
  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked')
        .doc(blockedUserId)
        .delete();
  }

  /// Get blocked user IDs.
  Stream<List<String>> getBlockedUsers(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('blocked')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  /// Report a user (creates a report document).
  Future<void> reportUser({
    required String reporterId,
    required String reporterUsername,
    required String targetId,
    required String reason,
    String details = '',
  }) async {
    final id = _uuid.v4();
    await _firestore.collection('reports').doc(id).set({
      'id': id,
      'reporterId': reporterId,
      'reporterUsername': reporterUsername,
      'targetId': targetId,
      'targetType': 'user',
      'reason': reason,
      'details': details,
      'status': 'pending',
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Report a message.
  Future<void> reportMessage({
    required String reporterId,
    required String reporterUsername,
    required String conversationId,
    required String messageId,
    required String reason,
  }) async {
    final id = _uuid.v4();
    await _firestore.collection('reports').doc(id).set({
      'id': id,
      'reporterId': reporterId,
      'reporterUsername': reporterUsername,
      'targetId': messageId,
      'targetType': 'message',
      'conversationId': conversationId,
      'reason': reason,
      'status': 'pending',
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  DELETE MESSAGE / CONVERSATION
  // ══════════════════════════════════════════════════════════════

  /// Delete a specific message.
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  /// Delete an entire conversation for the current user.
  Future<void> deleteConversation({
    required String conversationId,
    required String userId,
  }) async {
    // In production, you might just hide the conversation for the user
    await _firestore.collection('conversations').doc(conversationId).update({
      'deletedBy': FieldValue.arrayUnion([userId]),
    });
  }
}

import '../../models/message_model.dart';
import '../data/mock_data.dart';
import 'api_service.dart';

/// Chat repository — routes through PostgreSQL API.
/// Falls back to mock data when the API is unavailable.
class ChatRepository {

  // ── Conversations ─────────────────────────────────────────────
  Stream<List<ConversationModel>> getConversations(String userId) async* {
    try {
      yield await ApiService.getConversations(userId);
    } catch (_) {
      yield MockData.conversations;
    }
  }

  // ── Messages ──────────────────────────────────────────────────
  Stream<List<MessageModel>> getMessages(String conversationId) async* {
    try {
      yield await ApiService.getMessages(conversationId);
    } catch (_) {
      yield MockData.messagesFor(conversationId);
    }
  }

  // ── Send Message ──────────────────────────────────────────────
  Future<void> sendMessage(String conversationId, MessageModel message) async {
    await ApiService.sendMessage(
      conversationId: conversationId,
      senderId: message.senderId,
      text: message.text,
    );
  }

  // ── Mark as Read ──────────────────────────────────────────────
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    // Server endpoint can be added later
  }

  // ── Get or Create DM Conversation ─────────────────────────────
  Future<ConversationModel?> getOrCreateConversation({
    required String userId,
    required String otherUserId,
    required Map<String, String> names,
    required Map<String, String> photos,
  }) async {
    return ApiService.getOrCreateConversation(userId, otherUserId);
  }

  // ══════════════════════════════════════════════════════════════
  //  GROUP CHAT
  // ══════════════════════════════════════════════════════════════

  Future<ConversationModel?> createGroupConversation({
    required String createdBy,
    required String groupName,
    required List<String> participantIds,
    required Map<String, String> names,
    required Map<String, String> photos,
    String groupPhotoUrl = '',
  }) async {
    return ApiService.createGroupConversation(
      creatorId: createdBy,
      groupName: groupName,
      memberIds: participantIds,
    );
  }

  Future<void> addGroupMember({
    required String conversationId,
    required String userId,
    required String userName,
    required String userPhoto,
  }) async {
    // Server endpoint can be added later
  }

  Future<void> removeGroupMember({
    required String conversationId,
    required String userId,
  }) async {
    // Server endpoint can be added later
  }

  Future<void> promoteToAdmin({
    required String conversationId,
    required String userId,
  }) async {}

  Future<void> demoteFromAdmin({
    required String conversationId,
    required String userId,
  }) async {}

  Future<void> updateGroupName({
    required String conversationId,
    required String name,
  }) async {}

  Future<void> leaveGroup({
    required String conversationId,
    required String userId,
  }) async {}

  // ══════════════════════════════════════════════════════════════
  //  MEDIA SHARING
  // ══════════════════════════════════════════════════════════════

  Future<void> sendMediaMessage({
    required String conversationId,
    required String senderId,
    required String mediaUrl,
    required String mediaType,
    String text = '',
  }) async {
    await ApiService.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      text: text.isNotEmpty ? text : '📎 $mediaType',
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MESSAGE REACTIONS
  // ══════════════════════════════════════════════════════════════

  Future<void> addMessageReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {}

  Future<void> removeMessageReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {}

  // ══════════════════════════════════════════════════════════════
  //  BLOCK & REPORT
  // ══════════════════════════════════════════════════════════════

  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {}

  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {}

  Stream<List<String>> getBlockedUsers(String userId) {
    return Stream.value(MockData.blockedUserIds);
  }

  Future<void> reportUser({
    required String reporterId,
    required String reporterUsername,
    required String targetId,
    required String reason,
    String details = '',
  }) async {}

  Future<void> reportMessage({
    required String reporterId,
    required String reporterUsername,
    required String conversationId,
    required String messageId,
    required String reason,
  }) async {}

  // ══════════════════════════════════════════════════════════════
  //  DELETE MESSAGE / CONVERSATION
  // ══════════════════════════════════════════════════════════════

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {}

  Future<void> deleteConversation({
    required String conversationId,
    required String userId,
  }) async {}
}

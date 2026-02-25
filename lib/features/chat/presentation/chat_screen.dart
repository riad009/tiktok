import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/api_service.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convosAsync = ref.watch(conversationsProvider);
    final currentUid = ref.read(currentUidProvider) ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'New Chat',
            onPressed: () => _showAllUsers(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── All Users Section ──
          _AllUsersBar(currentUid: currentUid),
          const Divider(height: 1, color: AppColors.darkBorder),
          // ── Conversations List ──
          Expanded(
            child: convosAsync.when(
              data: (conversations) {
                if (conversations.isEmpty) return _buildEmpty(context, ref);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final convo = conversations[index];
                    final otherId = convo.participants.firstWhere(
                        (p) => p != currentUid,
                        orElse: () => '');
                    final otherName =
                        convo.participantNames[otherId] ?? 'User';
                    final timeAgo = _timeAgo(convo.lastMessageTime);

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.darkCard,
                        backgroundImage:
                            (convo.participantPhotos[otherId] ?? '').isNotEmpty
                                ? NetworkImage(convo.participantPhotos[otherId]!)
                                : null,
                        child: (convo.participantPhotos[otherId] ?? '').isEmpty
                            ? Text(
                                otherName.isNotEmpty
                                    ? otherName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 18))
                            : null,
                      ),
                      title: Text(otherName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        convo.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                      trailing: Text(timeAgo,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChatScreen(
                              conversationId: convo.id,
                              otherUserName: otherName),
                        ));
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllUsers(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AllUsersSheet(
        currentUid: ref.read(currentUidProvider) ?? '',
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('No messages yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Tap a user above to start chatting!',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}

// ── Horizontal Users Bar at top of Chat ──────────────────────────
class _AllUsersBar extends ConsumerWidget {
  final String currentUid;
  const _AllUsersBar({required this.currentUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return SizedBox(
      height: 100,
      child: usersAsync.when(
        data: (users) {
          final others = users.where((u) => u.uid != currentUid).toList();
          if (others.isEmpty) {
            return const Center(
                child: Text('No other users yet',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)));
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: others.length,
            itemBuilder: (context, i) {
              final user = others[i];
              return GestureDetector(
                onTap: () => _startChat(context, ref, user),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withAlpha(40),
                        backgroundImage: user.photoUrl.isNotEmpty
                            ? NetworkImage(user.photoUrl)
                            : null,
                        child: user.photoUrl.isEmpty
                            ? Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 20))
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(fontSize: 12))),
      ),
    );
  }

  void _startChat(BuildContext context, WidgetRef ref, UserModel otherUser) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final convo = await ApiService.getOrCreateConversation(currentUid, otherUser.uid);
    
    if (context.mounted) Navigator.pop(context); // dismiss loading

    if (convo != null && context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convo.id,
          otherUserName: otherUser.displayName,
        ),
      ));
    }
  }
}

// ── Full Users Sheet (New Chat) ──────────────────────────────────
class _AllUsersSheet extends StatefulWidget {
  final String currentUid;
  const _AllUsersSheet({required this.currentUid});

  @override
  State<_AllUsersSheet> createState() => _AllUsersSheetState();
}

class _AllUsersSheetState extends State<_AllUsersSheet> {
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    final users = await ApiService.getUsers();
    if (mounted) {
      setState(() {
        _users = users.where((u) => u.uid != widget.currentUid).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Start New Chat',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Divider(color: AppColors.darkBorder),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _users.isEmpty
                      ? const Center(
                          child: Text('No other users found',
                              style: TextStyle(color: AppColors.textMuted)))
                      : ListView.builder(
                          controller: controller,
                          itemCount: _users.length,
                          itemBuilder: (_, i) {
                            final user = _users[i];
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withAlpha(40),
                                backgroundImage: user.photoUrl.isNotEmpty
                                    ? NetworkImage(user.photoUrl)
                                    : null,
                                child: user.photoUrl.isEmpty
                                    ? Text(
                                        user.displayName.isNotEmpty
                                            ? user.displayName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700))
                                    : null,
                              ),
                              title: Text(user.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('@${user.username}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 13)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Chat',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ),
                              onTap: () => _openChat(user),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  void _openChat(UserModel otherUser) async {
    Navigator.pop(context); // close sheet

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final convo = await ApiService.getOrCreateConversation(
      widget.currentUid, otherUser.uid);

    if (context.mounted) Navigator.pop(context); // dismiss loading

    if (convo != null && context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convo.id,
          otherUserName: otherUser.displayName,
        ),
      ));
    }
  }
}

// ── Chat Screen ──────────────────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserName;

  const ChatScreen(
      {super.key,
      required this.conversationId,
      required this.otherUserName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    _msgController.clear();

    await ApiService.sendMessage(
      conversationId: widget.conversationId,
      senderId: uid,
      text: text,
    );

    // Refresh messages
    ref.invalidate(messagesProvider(widget.conversationId));
    ref.invalidate(conversationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final currentUid = ref.read(currentUidProvider) ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkCard,
            child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otherUserName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const Text('Online',
                  style:
                      TextStyle(fontSize: 11, color: Color(0xFF4ade80))),
            ],
          ),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                      child: Text('Say hello! 👋',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 16)));
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUid;
                    return _ChatBubble(message: msg, isMe: isMe);
                  },
                );
              },
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
          left: 16,
          right: 8,
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.darkBorder))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _msgController,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                    hintText: 'Message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: IconButton(
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
                onPressed: _sendMessage),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.primaryGradient : null,
          color: isMe ? null : AppColors.darkCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text,
                style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : AppColors.textMuted),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: message.isRead ? const Color(0xFF4ade80) : Colors.white54,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

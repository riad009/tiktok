import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final groupsAsync = ref.watch(groupConversationsProvider);
    final currentUid = ref.read(currentUidProvider) ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.screenGradient),
          child: Scaffold(
            backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Messages'),
          actions: [
            IconButton(
              icon: const Icon(Icons.group_add_rounded),
              tooltip: 'New Group',
              onPressed: () => _showCreateGroupSheet(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              tooltip: 'New Chat',
              onPressed: () => _showAllUsers(context, ref),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'Direct'),
                  Tab(text: 'Groups'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // ── Direct Messages Tab ──
            Column(
              children: [
                _AllUsersBar(currentUid: currentUid),
                const Divider(height: 1, color: AppColors.darkBorder),
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
                              (p) => p != currentUid, orElse: () => '');
                          final otherName = convo.participantNames[otherId] ?? 'User';
                          final timeAgo = _timeAgo(convo.lastMessageTime);

                          return _ConversationTile(
                            name: otherName,
                            photoUrl: convo.participantPhotos[otherId] ?? '',
                            lastMessage: convo.lastMessage,
                            timeAgo: timeAgo,
                            isGroupChat: false,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  conversationId: convo.id,
                                  otherUserName: otherName,
                                ),
                              ));
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
            // ── Groups Tab ──
            groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) return _buildEmptyGroups(context, ref);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final timeAgo = _timeAgo(group.lastMessageTime);

                    return _ConversationTile(
                      name: group.groupName,
                      photoUrl: group.groupPhotoUrl,
                      lastMessage: group.lastMessage,
                      timeAgo: timeAgo,
                      isGroupChat: true,
                      memberCount: group.participants.length,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: group.id,
                            otherUserName: group.groupName,
                            isGroupChat: true,
                            conversation: group,
                          ),
                        ));
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
        ),
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

  void _showCreateGroupSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _CreateGroupSheet(
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
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('No messages yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Tap a user above to start chatting!', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEmptyGroups(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(40),
              borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.groups_rounded, size: 40, color: AppColors.accent),
          ),
          const SizedBox(height: 20),
          const Text('No group chats yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Create a group to chat with multiple people!', style: TextStyle(color: AppColors.textSecondary)),
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

// ── Conversation Tile ────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final String name;
  final String photoUrl;
  final String lastMessage;
  final String timeAgo;
  final bool isGroupChat;
  final int memberCount;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.photoUrl,
    required this.lastMessage,
    required this.timeAgo,
    this.isGroupChat = false,
    this.memberCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: isGroupChat
            ? AppColors.accent.withValues(alpha: 0.2)
            : AppColors.darkCard,
        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty
            ? Icon(
                isGroupChat ? Icons.groups_rounded : Icons.person,
                color: isGroupChat ? AppColors.accent : AppColors.textMuted,
              )
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ),
          if (isGroupChat) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$memberCount',
                style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      trailing: Text(timeAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      onTap: onTap,
    );
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
          if (others.isEmpty) return const SizedBox();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: others.length,
            itemBuilder: (context, i) {
              final user = others[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () async {
                    final convo = await ApiService.getOrCreateConversation(
                        currentUid, user.uid);
                    if (convo != null && context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatScreen(
                            conversationId: convo.id,
                            otherUserName: user.displayName),
                      ));
                    }
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.darkCard,
                        backgroundImage: user.photoUrl.isNotEmpty
                            ? NetworkImage(user.photoUrl) : null,
                        child: user.photoUrl.isEmpty
                            ? Text(user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.w700))
                            : null,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 56,
                        child: Text(
                          user.username,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const SizedBox(),
      ),
    );
  }
}

// ── All Users Sheet ──────────────────────────────────────────────
class _AllUsersSheet extends StatefulWidget {
  final String currentUid;
  const _AllUsersSheet({required this.currentUid});

  @override
  State<_AllUsersSheet> createState() => _AllUsersSheetState();
}

class _AllUsersSheetState extends State<_AllUsersSheet> {
  List<UserModel> _users = [];
  List<UserModel> _filtered = [];
  bool _loading = true;
  final _searchController = TextEditingController();

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
        _filtered = _users;
        _loading = false;
      });
    }
  }

  void _filter(String q) {
    setState(() {
      _filtered = _users.where((u) =>
        u.username.toLowerCase().contains(q.toLowerCase()) ||
        u.displayName.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.darkBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: 'Search users...', prefixIcon: const Icon(Icons.search),
                  filled: true, fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final user = _filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withAlpha(40),
                            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                            child: user.photoUrl.isEmpty
                                ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                                    style: const TextStyle(fontWeight: FontWeight.w700))
                                : null,
                          ),
                          title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('@${user.username}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
                            child: const Text('Chat', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
    Navigator.pop(context);
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
    final convo = await ApiService.getOrCreateConversation(widget.currentUid, otherUser.uid);
    if (context.mounted) Navigator.pop(context);
    if (convo != null && context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatScreen(conversationId: convo.id, otherUserName: otherUser.displayName),
      ));
    }
  }
}

// ── Create Group Sheet ──────────────────────────────────────────
class _CreateGroupSheet extends ConsumerStatefulWidget {
  final String currentUid;
  const _CreateGroupSheet({required this.currentUid});

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _nameController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  List<UserModel> _users = [];
  bool _loading = true;
  bool _creating = false;

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

  void _createGroup() async {
    if (_selectedUserIds.isEmpty || _creating) return;
    setState(() => _creating = true);

    final groupName = _nameController.text.trim().isEmpty
        ? 'New Group' : _nameController.text.trim();

    final convo = await ApiService.createGroupConversation(
      creatorId: widget.currentUid,
      groupName: groupName,
      memberIds: _selectedUserIds.toList(),
    );

    if (!mounted) return;

    if (convo != null) {
      ref.invalidate(groupConversationsProvider);
      Navigator.pop(context); // close sheet
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convo.id,
          otherUserName: convo.groupName,
          isGroupChat: true,
          conversation: convo,
        ),
      ));
    } else {
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create group'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.darkBorder, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 24),
          const Text('Create Group Chat', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Group name',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.darkCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.group, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Select members:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                      final user = _users[i];
                      final selected = _selectedUserIds.contains(user.uid);
                      return CheckboxListTile(
                        dense: true,
                        value: selected,
                        activeColor: AppColors.accent,
                        title: Text(user.displayName, style: const TextStyle(fontSize: 14)),
                        subtitle: Text('@${user.username}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        secondary: CircleAvatar(
                          radius: 18,
                          backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                          child: user.photoUrl.isEmpty
                              ? Text(user.displayName.isNotEmpty ? user.displayName[0] : '?', style: const TextStyle(fontSize: 12))
                              : null,
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedUserIds.add(user.uid);
                            } else {
                              _selectedUserIds.remove(user.uid);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                gradient: _selectedUserIds.isNotEmpty && !_creating ? AppColors.primaryGradient : null,
                color: _selectedUserIds.isEmpty || _creating ? AppColors.darkCard : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _selectedUserIds.isEmpty || _creating ? null : _createGroup,
                  child: Center(
                    child: _creating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            _selectedUserIds.isEmpty
                                ? 'Select members to continue'
                                : 'Create Group (${_selectedUserIds.length + 1} members)',
                            style: TextStyle(
                              color: _selectedUserIds.isEmpty ? AppColors.textMuted : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Screen ──────────────────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserName;
  final bool isGroupChat;
  final ConversationModel? conversation;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    this.isGroupChat = false,
    this.conversation,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

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
    ref.invalidate(messagesProvider(widget.conversationId));
    ref.invalidate(conversationsProvider);
    if (widget.isGroupChat) {
      ref.invalidate(groupConversationsProvider);
    }
  }

  void _showReactionPicker(MessageModel message) {
    final emojis = ['❤️', '😂', '😮', '😢', '🔥', '👍', '👎', '🎉'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('React to message', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16, fontFamily: 'Inter', letterSpacing: 0.5)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis.map((emoji) => GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reacted with $emoji'), backgroundColor: AppColors.success, duration: const Duration(seconds: 1)),
                  );
                },
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share Media', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MediaOption(icon: Icons.photo, label: 'Photo', color: AppColors.primary, onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('📸 Photo picker coming soon!'), backgroundColor: AppColors.primary),
                  );
                }),
                _MediaOption(icon: Icons.videocam, label: 'Video', color: AppColors.accent, onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎬 Video picker coming soon!'), backgroundColor: AppColors.accent),
                  );
                }),
                _MediaOption(icon: Icons.mic, label: 'Audio', color: AppColors.success, onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎙️ Audio recorder coming soon!'), backgroundColor: AppColors.success),
                  );
                }),
                _MediaOption(icon: Icons.insert_drive_file, label: 'File', color: AppColors.error, onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('📄 File picker coming soon!'), backgroundColor: AppColors.error),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isGroupChat) ...[
              _OptionRow(
                icon: Icons.group, label: 'Group Info',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showGroupInfo();
                },
              ),
              const Divider(color: AppColors.darkBorder),
            ],
            _OptionRow(
              icon: Icons.block, label: 'Block User',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(ctx);
                _showBlockConfirm();
              },
            ),
            const Divider(color: AppColors.darkBorder),
            _OptionRow(
              icon: Icons.flag_rounded, label: 'Report',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(ctx);
                _showReportSheet();
              },
            ),
            const Divider(color: AppColors.darkBorder),
            _OptionRow(
              icon: Icons.delete_outline, label: 'Delete Conversation',
              color: AppColors.error.withValues(alpha: 0.7),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirm();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupInfo() {
    final convo = widget.conversation;
    if (convo == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.darkBorder, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                child: const Icon(Icons.groups_rounded, size: 40, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(convo.groupName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('${convo.participants.length} members', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            ),
            const SizedBox(height: 24),
            const Text('Members', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...convo.participants.map((uid) {
              final name = convo.participantNames[uid] ?? 'Unknown';
              final photo = convo.participantPhotos[uid] ?? '';
              final isAdmin = convo.adminIds.contains(uid);
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 20,
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty ? Text(name.isNotEmpty ? name[0] : '?') : null,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: isAdmin
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Admin', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                      )
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Block User?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Block ${widget.otherUserName}? They won\'t be able to message you.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final blockedList = ref.read(blockedUsersProvider);
              ref.read(blockedUsersProvider.notifier).state = [...blockedList, 'blocked-user'];
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User blocked'), backgroundColor: AppColors.error),
              );
            },
            child: const Text('Block', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showReportSheet() {
    final reasons = ['Spam', 'Harassment', 'Inappropriate Content', 'Scam', 'Other'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report User', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Why are you reporting ${widget.otherUserName}?',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ...reasons.map((reason) => ListTile(
              dense: true,
              leading: const Icon(Icons.radio_button_unchecked, size: 20, color: AppColors.textMuted),
              title: Text(reason, style: const TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted. We\'ll review it shortly.'), backgroundColor: AppColors.success),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Delete Conversation?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversation deleted'), backgroundColor: AppColors.error),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final currentUid = ref.read(currentUidProvider) ?? '';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.splashGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: widget.isGroupChat
                ? AppColors.accent.withValues(alpha: 0.2)
                : AppColors.darkCard,
            child: Icon(
              widget.isGroupChat ? Icons.groups_rounded : Icons.person,
              size: 18,
              color: widget.isGroupChat ? AppColors.accent : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter', letterSpacing: 0.3),
                    overflow: TextOverflow.ellipsis),
                Text(
                  widget.isGroupChat
                      ? '${widget.conversation?.participants.length ?? 0} members'
                      : 'Online',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isGroupChat ? AppColors.textMuted : const Color(0xFF4ade80),
                  ),
                ),
              ],
            ),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: _showChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                      child: Text('Say hello! 👋',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 16)));
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUid;
                    final senderName = widget.isGroupChat && !isMe
                        ? (widget.conversation?.participantNames[msg.senderId] ?? msg.senderId)
                        : null;
                    return GestureDetector(
                      onLongPress: () => _showReactionPicker(msg),
                      child: _ChatBubble(message: msg, isMe: isMe, senderName: senderName),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildInput(),
        ],
      ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
          left: 12, right: 12, top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: AppColors.navBarBg.withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _msgController,
                onSubmitted: (_) => _sendMessage(),
                style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Send', style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Bubble with green-highlighted words (matching screenshot) ──
class _ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? senderName;
  const _ChatBubble({required this.message, required this.isMe, this.senderName});

  // Colors for sender names (cycle through)
  static const _senderColors = [
    Color(0xFFFF6B8A), // pink
    Color(0xFF4ade80), // green
    Color(0xFFFFA726), // orange
    Color(0xFF42A5F5), // blue
    Color(0xFFAB47BC), // purple
    Color(0xFFFF7043), // deep orange
  ];

  Color _getSenderColor(String name) {
    final idx = name.hashCode.abs() % _senderColors.length;
    return _senderColors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')} ${message.timestamp.hour >= 12 ? 'PM' : 'AM'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name + message
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe && senderName != null) ...[
                Text(
                  '${senderName!}: ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _getSenderColor(senderName!),
                  ),
                ),
              ] else if (isMe) ...[
                Text(
                  'You: ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
              Flexible(
                child: _buildHighlightedText(message.text),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Timestamp
          Padding(
            padding: EdgeInsets.only(left: isMe ? 0 : 4, right: isMe ? 4 : 0),
            child: Text(
              timeStr,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds text with each word in a green-highlighted box (matching screenshot)
  Widget _buildHighlightedText(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    final words = text.split(' ');
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: words.map((word) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.chatHighlight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            word,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Media Option Button ─────────────────────────────────────────
class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Option Row ──────────────────────────────────────────────────
class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

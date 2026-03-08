import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/api_service.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';

// ══════════════════════════════════════════════════════════════════
// Conversations List Screen (Messages)
// ══════════════════════════════════════════════════════════════════
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convosAsync = ref.watch(conversationsProvider);
    final groupsAsync = ref.watch(groupConversationsProvider);
    final currentUid = ref.read(currentUidProvider) ?? '';
    final currentUser = ref.watch(authUserProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 24),
                    ),
                  if (Navigator.of(context).canPop())
                    const SizedBox(width: 12),
                  Text('Message',
                      style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const Spacer(),
                  // Profile avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.darkCard,
                    backgroundImage: NetworkImage(
                      currentUser?.photoUrl != null &&
                              currentUser!.photoUrl.isNotEmpty
                          ? currentUser.photoUrl
                          : 'https://i.pravatar.cc/150?u=${currentUser?.username ?? 'me'}',
                    ),
                  ),
                ],
              ),
            ),

            // ── Active Users (horizontal scroll) ───────
            _ActiveUsersRow(currentUid: currentUid),

            // ── Conversations List ─────────────────────
            Expanded(
              child: convosAsync.when(
                data: (conversations) {
                  // Combine direct + group conversations
                  final groups =
                      groupsAsync.valueOrNull ?? [];

                  if (conversations.isEmpty &&
                      groups.isEmpty) {
                    return _buildEmpty(context, ref);
                  }

                  // Build combined list
                  final allConvos = <_ConvoItem>[];

                  for (final convo in conversations) {
                    final otherId =
                        convo.participants.firstWhere(
                            (p) => p != currentUid,
                            orElse: () => '');
                    final otherName =
                        convo.participantNames[otherId] ??
                            'User';
                    final otherPhoto =
                        convo.participantPhotos[otherId] ??
                            '';
                    allConvos.add(_ConvoItem(
                      id: convo.id,
                      name: otherName,
                      photoUrl: otherPhoto,
                      lastMessage: convo.lastMessage,
                      time: convo.lastMessageTime,
                      isGroup: false,
                      conversation: convo,
                    ));
                  }

                  for (final g in groups) {
                    allConvos.add(_ConvoItem(
                      id: g.id,
                      name: g.groupName,
                      photoUrl: g.groupPhotoUrl,
                      lastMessage: g.lastMessage,
                      time: g.lastMessageTime,
                      isGroup: true,
                      memberCount:
                          g.participants.length,
                      conversation: g,
                    ));
                  }

                  // Sort by time
                  allConvos.sort((a, b) =>
                      b.time.compareTo(a.time));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8),
                    itemCount: allConvos.length,
                    itemBuilder: (context, index) {
                      final item = allConvos[index];
                      final isFirst = index == 0;

                      return _ConversationTile(
                        name: item.name,
                        photoUrl: item.photoUrl,
                        lastMessage: item.lastMessage,
                        time: item.time,
                        isHighlighted: isFirst,
                        isGroupChat: item.isGroup,
                        memberCount: item.memberCount,
                        onTap: () {
                          final otherName = item.name;
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: item.id,
                                otherUserName: otherName,
                                isGroupChat: item.isGroup,
                                conversation:
                                    item.conversation,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                    child: CupertinoActivityIndicator(
                        radius: 14,
                        color: AppColors.primary)),
                error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(
                            color:
                                AppColors.textMuted))),
              ),
            ),
          ],
        ),
      ),
      // FAB for new chat
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAllUsers(context, ref),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showAllUsers(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
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
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('No messages yet',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('Tap + to start chatting!',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Active Users Row — horizontal scrollable avatars at top of chat
// ══════════════════════════════════════════════════════════════════
class _ActiveUsersRow extends ConsumerWidget {
  final String currentUid;
  const _ActiveUsersRow({required this.currentUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      data: (users) {
        final others = users.where((u) => u.uid != currentUid).toList();
        if (others.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text('Active Now',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5)),
            ),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: others.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final user = others[index];
                  final photoUrl = user.photoUrl.isNotEmpty
                      ? user.photoUrl
                      : 'https://i.pravatar.cc/150?u=${user.username}';
                  final displayLabel = user.displayName.isNotEmpty &&
                          !user.displayName.contains('@')
                      ? user.displayName
                      : user.username;

                  return GestureDetector(
                    onTap: () => _openChat(context, ref, user),
                    child: SizedBox(
                      width: 68,
                      child: Column(
                        children: [
                          // Avatar with gradient ring + online dot
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                      AppColors.primary.withOpacity(0.6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.darkBg,
                                  ),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.darkCard,
                                    backgroundImage:
                                        CachedNetworkImageProvider(photoUrl),
                                  ),
                                ),
                              ),
                              // Green online dot
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.darkBg, width: 2.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Username
                          Text(
                            displayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Subtle divider
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 0.5,
              color: AppColors.darkBorder.withOpacity(0.5),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 88,
        child: Center(
            child: CupertinoActivityIndicator(
                radius: 10, color: AppColors.primary)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _openChat(BuildContext context, WidgetRef ref, UserModel otherUser) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CupertinoActivityIndicator(
              radius: 14, color: AppColors.primary)),
    );

    final currentUid = ref.read(currentUidProvider) ?? '';
    final convo = await ApiService.getOrCreateConversation(currentUid, otherUser.uid);
    if (context.mounted) Navigator.pop(context); // dismiss loading

    if (convo != null && context.mounted) {
      Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convo.id,
          otherUserName: otherUser.displayName.isNotEmpty
              ? otherUser.displayName
              : otherUser.username,
        ),
      ));
    }
  }
}

// ── Conversation item model ──────────────────────────────────────
class _ConvoItem {
  final String id;
  final String name;
  final String photoUrl;
  final String lastMessage;
  final DateTime time;
  final bool isGroup;
  final int memberCount;
  final ConversationModel conversation;

  _ConvoItem({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.lastMessage,
    required this.time,
    this.isGroup = false,
    this.memberCount = 0,
    required this.conversation,
  });
}

// ── Conversation Tile (Messages list) ────────────────────────────
class _ConversationTile extends StatelessWidget {
  final String name;
  final String photoUrl;
  final String lastMessage;
  final DateTime time;
  final bool isHighlighted;
  final bool isGroupChat;
  final int memberCount;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.photoUrl,
    required this.lastMessage,
    required this.time,
    this.isHighlighted = false,
    this.isGroupChat = false,
    this.memberCount = 0,
    required this.onTap,
  });

  String _timeStr(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar with online dot
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isGroupChat
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.darkCard,
                  backgroundImage: NetworkImage(
                    photoUrl.isNotEmpty
                        ? photoUrl
                        : isGroupChat
                            ? 'https://i.pravatar.cc/150?u=group_$name'
                            : 'https://i.pravatar.cc/150?u=$name',
                  ),
                ),
                // Online dot
                if (!isGroupChat)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.darkBg,
                            width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Name + preview
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time + unread badge column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_timeStr(time),
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted)),
                const SizedBox(height: 6),
                // Unread badge (show on highlighted)
                if (isHighlighted)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('2',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── All Users Sheet (New Chat) ───────────────────────────────────
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
        _users = users
            .where((u) => u.uid != widget.currentUid)
            .toList();
        _filtered = _users;
        _loading = false;
      });
    }
  }

  void _filter(String q) {
    setState(() {
      _filtered = _users
          .where((u) =>
              u.username.toLowerCase().contains(q.toLowerCase()) ||
              u.displayName
                  .toLowerCase()
                  .contains(q.toLowerCase()))
          .toList();
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
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius:
                        BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                          radius: 14,
                          color: AppColors.primary))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final user = _filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                AppColors.primary
                                    .withAlpha(40),
                            backgroundImage: NetworkImage(
                              user.photoUrl.isNotEmpty
                                  ? user.photoUrl
                                  : 'https://i.pravatar.cc/150?u=${user.username}',
                            ),
                          ),
                          title: Text(user.displayName,
                              style: GoogleFonts.inter(
                                  fontWeight:
                                      FontWeight.w600,
                                  color: Colors.white)),
                          subtitle: Text(
                              '@${user.username}',
                              style: GoogleFonts.inter(
                                  color: AppColors
                                      .textSecondary,
                                  fontSize: 13)),
                          trailing: Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6),
                            decoration: BoxDecoration(
                                gradient: AppColors
                                    .primaryGradient,
                                borderRadius:
                                    BorderRadius.circular(
                                        20)),
                            child: Text('Chat',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w600)),
                          ),
                          onTap: () =>
                              _openChat(user),
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
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CupertinoActivityIndicator(
              radius: 14, color: AppColors.primary)),
    );
    final convo = await ApiService.getOrCreateConversation(
        widget.currentUid, otherUser.uid);
    if (context.mounted) Navigator.pop(context);
    if (convo != null && context.mounted) {
      Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => ChatScreen(
            conversationId: convo.id,
            otherUserName: otherUser.displayName),
      ));
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// Chat Screen (Individual conversation)
// ══════════════════════════════════════════════════════════════════
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

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share Media',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _MediaOption(
                    icon: Icons.photo,
                    label: 'Photo',
                    color: AppColors.primary,
                    onTap: () => Navigator.pop(ctx)),
                _MediaOption(
                    icon: Icons.videocam,
                    label: 'Video',
                    color: AppColors.secondary,
                    onTap: () => Navigator.pop(ctx)),
                _MediaOption(
                    icon: Icons.mic,
                    label: 'Audio',
                    color: const Color(0xFF4CAF50),
                    onTap: () => Navigator.pop(ctx)),
                _MediaOption(
                    icon: Icons.insert_drive_file,
                    label: 'File',
                    color: AppColors.error,
                    onTap: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(messagesProvider(widget.conversationId));
    final currentUid = ref.read(currentUidProvider) ?? '';

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      // ── App bar ──────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back,
              color: Colors.white, size: 24),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.isGroupChat
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.darkCard,
                  backgroundImage: NetworkImage(
                    widget.isGroupChat
                        ? 'https://i.pravatar.cc/150?u=group_${widget.otherUserName}'
                        : 'https://i.pravatar.cc/150?u=${widget.otherUserName}',
                  ),
                ),
                if (!widget.isGroupChat)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.darkBg,
                            width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUserName,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                  Text(
                    widget.isGroupChat
                        ? '${widget.conversation?.participants.length ?? 0} members'
                        : 'Online',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: widget.isGroupChat
                          ? AppColors.textMuted
                          : const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert,
                color: AppColors.textMuted),
            onPressed: () {},
          ),
        ],
      ),

      // ── Body ─────────────────────────────────────
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text('Say hello! 👋',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 16)),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe =
                        msg.senderId == currentUid;
                    final senderName =
                        widget.isGroupChat && !isMe
                            ? (widget.conversation
                                    ?.participantNames[
                                        msg.senderId] ??
                                msg.senderId)
                            : null;
                    return _ChatBubble(
                      message: msg,
                      isMe: isMe,
                      senderName: senderName,
                    );
                  },
                );
              },
              loading: () => const Center(
                  child: CupertinoActivityIndicator(
                      radius: 14,
                      color: AppColors.primary)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(
                          color: AppColors.textMuted))),
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  // ── Message input bar ─────────────────────────────
  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        border: Border(
            top: BorderSide(
                color: AppColors.darkBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          // + button
          GestureDetector(
            onTap: _showMediaPicker,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add,
                  color: AppColors.textSecondary, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      onSubmitted: (_) => _sendMessage(),
                      style: GoogleFonts.inter(
                          fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message here',
                        hintStyle: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 14),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12),
                      ),
                    ),
                  ),
                  // Emoji button
                  GestureDetector(
                    onTap: () {},
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                          Icons.emoji_emotions_outlined,
                          color: AppColors.textMuted,
                          size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Chat Bubble (Purple received, White sent)
// ══════════════════════════════════════════════════════════════════
class _ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? senderName;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${message.timestamp.hour > 12 ? message.timestamp.hour - 12 : message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')} ${message.timestamp.hour >= 12 ? 'PM' : 'AM'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name for group chats
          if (senderName != null && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(senderName!,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),

          // Bubble
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isMe) const Spacer(flex: 2),
              Flexible(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white
                        : const Color(0xFF3D2660),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.4,
                      color: isMe ? Colors.black87 : Colors.white,
                    ),
                  ),
                ),
              ),
              if (!isMe) const Spacer(flex: 2),
            ],
          ),

          // Timestamp + "..."
          Padding(
            padding: EdgeInsets.only(
                left: isMe ? 0 : 12,
                right: isMe ? 12 : 0,
                top: 4),
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(timeStr,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted)),
                const SizedBox(width: 8),
                const Icon(Icons.more_horiz,
                    color: AppColors.textMuted, size: 16),
              ],
            ),
          ),
        ],
      ),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

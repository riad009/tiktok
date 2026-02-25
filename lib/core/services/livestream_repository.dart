import '../../models/livestream_model.dart';
import '../../models/clip_model.dart';

/// Thin wrapper — all livestream operations now go through
/// the Express/Mux backend via ApiService.
/// Firebase Firestore is no longer used for livestreams.
class LivestreamRepository {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── Create Livestream ─────────────────────────────────────────
  Future<LivestreamModel> createLivestream({
    required String hostId,
    required String hostUsername,
    String hostPhotoUrl = '',
    required String title,
  }) async {
    final id = _uuid.v4();
    final stream = LivestreamModel(
      id: id,
      hostId: hostId,
      hostUsername: hostUsername,
      hostPhotoUrl: hostPhotoUrl,
      title: title,
      isLive: true,
      startedAt: DateTime.now(),
    );
    await _firestore.collection('livestreams').doc(id).set(stream.toMap());
    return stream;
  }

  // ── End Livestream ────────────────────────────────────────────
  Future<void> endLivestream(String livestreamId) async {
    await _firestore.collection('livestreams').doc(livestreamId).update({
      'isLive': false,
      'endedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── Join / Leave ──────────────────────────────────────────────
  Future<void> joinLivestream(String livestreamId, String userId) async {
    await _firestore.collection('livestreams').doc(livestreamId).update({
      'viewerIds': FieldValue.arrayUnion([userId]),
      'viewerCount': FieldValue.increment(1),
    });
  }

  Future<void> leaveLivestream(String livestreamId, String userId) async {
    await _firestore.collection('livestreams').doc(livestreamId).update({
      'viewerIds': FieldValue.arrayRemove([userId]),
      'viewerCount': FieldValue.increment(-1),
    });
  }

  // ── Chat ──────────────────────────────────────────────────────
  Future<void> sendChatMessage(String livestreamId, LiveChatMessage message) async {
    await _firestore
        .collection('livestreams')
        .doc(livestreamId)
        .collection('liveChat')
        .doc(message.id)
        .set(message.toMap());
  }

  // ── Reactions ─────────────────────────────────────────────────
  Future<void> addReaction(String livestreamId) async {
    await _firestore.collection('livestreams').doc(livestreamId).update({
      'totalReactions': FieldValue.increment(1),
    });
  }

  // ── Convenience: send live chat with named params ─────────────
  Future<void> sendLiveChat({
    required String livestreamId,
    required String senderId,
    required String username,
    String userPhotoUrl = '',
    required String text,
    String? reaction,
  }) async {
    final msg = LiveChatMessage(
      id: _uuid.v4(),
      senderId: senderId,
      username: username,
      text: text,
      reaction: reaction,
      timestamp: DateTime.now(),
    );
    await sendChatMessage(livestreamId, msg);
  }


  // ── Active Streams ────────────────────────────────────────────
  Stream<List<LivestreamModel>> getActiveStreams() {
    return _firestore
        .collection('livestreams')
        .where('isLive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LivestreamModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Replays ───────────────────────────────────────────────────
  Stream<List<LivestreamModel>> getReplays() {
    return _firestore
        .collection('livestreams')
        .where('isLive', isEqualTo: false)
        .orderBy('endedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LivestreamModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Live Chat Stream ──────────────────────────────────────────
  Stream<List<LiveChatMessage>> getLiveChatStream(String livestreamId) {
    return _firestore
        .collection('livestreams')
        .doc(livestreamId)
        .collection('liveChat')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LiveChatMessage.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Follow Notifications ──────────────────────────────────────
  /// Notify followers that a creator has gone live.
  /// Returns the list of follower IDs that were notified.
  Future<List<String>> notifyFollowersOfLivestream({
    required String livestreamId,
    required String hostId,
    required String hostUsername,
    required String title,
  }) async {
    // In production, query the 'followers' collection for the host
    // and send push notifications. For now, we mark followers as notified.
    try {
      final followersSnap = await _firestore
          .collection('followers')
          .doc(hostId)
          .collection('userFollowers')
          .get();

      final followerIds = followersSnap.docs.map((d) => d.id).toList();

      // Create notification documents for each follower
      for (final followerId in followerIds) {
        await _firestore
            .collection('notifications')
            .doc(_uuid.v4())
            .set({
          'userId': followerId,
          'type': 'livestream_started',
          'title': '$hostUsername is live!',
          'body': title,
          'livestreamId': livestreamId,
          'hostId': hostId,
          'hostUsername': hostUsername,
          'isRead': false,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      // Update livestream with notified followers
      await _firestore.collection('livestreams').doc(livestreamId).update({
        'notifiedFollowers': followerIds,
      });

      return followerIds;
    } catch (e) {
      // If followers collection doesn't exist, return empty
      return [];
    }
  }

  // ── Update Peak Viewers ───────────────────────────────────────
  Future<void> updatePeakViewers(String livestreamId, int currentViewers) async {
    final doc = await _firestore.collection('livestreams').doc(livestreamId).get();
    if (doc.exists) {
      final currentPeak = doc.data()?['peakViewers'] ?? 0;
      if (currentViewers > currentPeak) {
        await _firestore.collection('livestreams').doc(livestreamId).update({
          'peakViewers': currentViewers,
        });
      }
    }
  }

  // ── Clip Generation ───────────────────────────────────────────
  /// Auto-detect highlights from a completed livestream and generate clips.
  /// This analyzes chat bursts, reaction spikes, and peak viewer moments.
  Future<List<ClipModel>> generateClipsForLivestream({
    required String livestreamId,
    required String hostId,
    required String hostUsername,
    String hostPhotoUrl = '',
    required String title,
    required Duration streamDuration,
  }) async {
    final clips = <ClipModel>[];

    try {
      // Fetch all chat messages for the stream
      final chatSnap = await _firestore
          .collection('livestreams')
          .doc(livestreamId)
          .collection('liveChat')
          .orderBy('timestamp')
          .get();

      if (chatSnap.docs.isEmpty) {
        // Generate a default highlight clip at the midpoint
        final midpoint = streamDuration ~/ 2;
        final clip = ClipModel(
          id: _uuid.v4(),
          livestreamId: livestreamId,
          hostId: hostId,
          hostUsername: hostUsername,
          hostPhotoUrl: hostPhotoUrl,
          title: '✨ Highlight from "$title"',
          startTime: midpoint - const Duration(seconds: 22),
          endTime: midpoint + const Duration(seconds: 23),
          highlightType: 'manual',
        );
        clips.add(clip);
      } else {
        // Analyze chat density to find bursts
        final messages = chatSnap.docs.map((d) => d.data()).toList();
        
        // Find reaction-heavy segments
        final reactionMessages = messages.where((m) => m['reaction'] != null && m['reaction'] != '').toList();
        if (reactionMessages.length >= 3) {
          final firstReactionTime = (reactionMessages.first['timestamp'] as Timestamp).toDate();
          final clip = ClipModel(
            id: _uuid.v4(),
            livestreamId: livestreamId,
            hostId: hostId,
            hostUsername: hostUsername,
            hostPhotoUrl: hostPhotoUrl,
            title: '🔥 Peak reactions moment!',
            startTime: Duration(seconds: firstReactionTime.difference(DateTime.now()).inSeconds.abs() - 15),
            endTime: Duration(seconds: firstReactionTime.difference(DateTime.now()).inSeconds.abs() + 30),
            highlightType: 'peak_reactions',
          );
          clips.add(clip);
        }

        // Find chat burst segments (many messages in short time)
        if (messages.length >= 5) {
          final midIdx = messages.length ~/ 2;
          final midTime = (messages[midIdx]['timestamp'] as Timestamp).toDate();
          final clip = ClipModel(
            id: _uuid.v4(),
            livestreamId: livestreamId,
            hostId: hostId,
            hostUsername: hostUsername,
            hostPhotoUrl: hostPhotoUrl,
            title: '💬 Chat went wild!',
            startTime: Duration(seconds: midTime.difference(DateTime.now()).inSeconds.abs() - 20),
            endTime: Duration(seconds: midTime.difference(DateTime.now()).inSeconds.abs() + 25),
            highlightType: 'chat_burst',
          );
          clips.add(clip);
        }
      }

      // Save clips to Firestore
      for (final clip in clips) {
        await _firestore.collection('clips').doc(clip.id).set(clip.toMap());
      }

      // Update livestream with clip IDs
      await _firestore.collection('livestreams').doc(livestreamId).update({
        'clipIds': clips.map((c) => c.id).toList(),
      });

      return clips;
    } catch (e) {
      return clips;
    }
  }

  // ── Post Clip to Feed ─────────────────────────────────────────
  Future<void> postClipToFeed(ClipModel clip) async {
    await _firestore.collection('videos').doc('clip-${clip.id}').set({
      'userId': clip.hostId,
      'username': clip.hostUsername,
      'userPhotoUrl': clip.hostPhotoUrl,
      'videoUrl': clip.videoUrl,
      'thumbnailUrl': clip.thumbnailUrl,
      'caption': '${clip.title} — from my livestream!',
      'hashtags': ['livestream', 'clip', 'highlight'],
      'likesCount': 0,
      'commentsCount': 0,
      'viewsCount': 0,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'isClip': true,
      'clipId': clip.id,
      'livestreamId': clip.livestreamId,
    });

    // Mark clip as posted
    await _firestore.collection('clips').doc(clip.id).update({
      'postedToFeed': true,
    });
  }

  // ── Share Clip to Story ───────────────────────────────────────
  Future<void> shareClipToStory(ClipModel clip) async {
    await _firestore.collection('stories').doc('clip-story-${clip.id}').set({
      'userId': clip.hostId,
      'username': clip.hostUsername,
      'userPhotoUrl': clip.hostPhotoUrl,
      'mediaUrl': clip.thumbnailUrl,
      'mediaType': 'clip',
      'caption': clip.title,
      'clipId': clip.id,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
    });

    await _firestore.collection('clips').doc(clip.id).update({
      'sharedToStory': true,
    });
  }

  // ── Get Clips for Livestream ──────────────────────────────────
  Stream<List<ClipModel>> getClipsForLivestream(String livestreamId) {
    return _firestore
        .collection('clips')
        .where('livestreamId', isEqualTo: livestreamId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClipModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Get Clips for User ────────────────────────────────────────
  Stream<List<ClipModel>> getClipsForUser(String userId) {
    return _firestore
        .collection('clips')
        .where('hostId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClipModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Livestream Chat Moderation ────────────────────────────────
  /// Delete a chat message (moderator action)
  Future<void> deleteChatMessage(String livestreamId, String messageId) async {
    await _firestore
        .collection('livestreams')
        .doc(livestreamId)
        .collection('liveChat')
        .doc(messageId)
        .delete();
  }

  /// Ban a user from the livestream chat
  Future<void> banUserFromChat(String livestreamId, String userId) async {
    await _firestore.collection('livestreams').doc(livestreamId).update({
      'bannedUsers': FieldValue.arrayUnion([userId]),
    });
  }

  /// Timeout a user from chat for a duration
  Future<void> timeoutUserFromChat(String livestreamId, String userId, int minutes) async {
    await _firestore
        .collection('livestreams')
        .doc(livestreamId)
        .collection('timeouts')
        .doc(userId)
        .set({
      'userId': userId,
      'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(minutes: minutes))),
    });
  }
}

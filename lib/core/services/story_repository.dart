import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../models/story_model.dart';
import '../constants/app_constants.dart';

class StoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _storiesCol =>
      _firestore.collection(AppConstants.storiesCollection);

  // ── Active Stories (non-expired) ───────────────────────────────
  Stream<List<StoryModel>> activeStoriesStream() {
    return _storiesCol
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StoryModel.fromMap(d.data(), d.id)).toList());
  }

  // ── Upload Story ───────────────────────────────────────────────
  Future<StoryModel> uploadStory({
    required File mediaFile,
    required String userId,
    required String username,
    String userPhotoUrl = '',
    required String mediaType, // 'image' or 'video'
  }) async {
    final storyId = _uuid.v4();
    final ext = mediaType == 'video' ? 'mp4' : 'jpg';
    final ref = _storage.ref().child('${AppConstants.storiesPath}/$storyId.$ext');
    await ref.putFile(mediaFile);
    final mediaUrl = await ref.getDownloadURL();

    final now = DateTime.now();
    final story = StoryModel(
      id: storyId,
      userId: userId,
      username: username,
      userPhotoUrl: userPhotoUrl,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );

    await _storiesCol.doc(storyId).set(story.toMap());
    return story;
  }

  // ── Mark Viewed ────────────────────────────────────────────────
  Future<void> markViewed(String storyId, String userId) async {
    await _storiesCol.doc(storyId).update({
      'viewedBy': FieldValue.arrayUnion([userId]),
    });
  }

  // ── Delete Story ───────────────────────────────────────────────
  Future<void> deleteStory(String storyId) async {
    final doc = await _storiesCol.doc(storyId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final mediaType = data['mediaType'] ?? 'image';
      final ext = mediaType == 'video' ? 'mp4' : 'jpg';
      try {
        await _storage.ref().child('${AppConstants.storiesPath}/$storyId.$ext').delete();
      } catch (_) {}
      await _storiesCol.doc(storyId).delete();
    }
  }

  // ── Stories grouped by user ────────────────────────────────────
  Map<String, List<StoryModel>> groupByUser(List<StoryModel> stories) {
    final map = <String, List<StoryModel>>{};
    for (final s in stories) {
      map.putIfAbsent(s.userId, () => []).add(s);
    }
    return map;
  }
}

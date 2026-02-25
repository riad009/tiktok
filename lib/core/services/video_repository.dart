import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../models/video_model.dart';
import '../../models/comment_model.dart';
import '../constants/app_constants.dart';

class VideoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _videosCol =>
      _firestore.collection(AppConstants.videosCollection);

  // ── Feed ───────────────────────────────────────────────────────
  Stream<List<VideoModel>> feedStream({int limit = 10}) {
    return _videosCol
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => VideoModel.fromMap(d.data(), d.id)).toList());
  }

  Future<List<VideoModel>> getFeedVideos({DocumentSnapshot? startAfter, int limit = 10}) async {
    Query<Map<String, dynamic>> query = _videosCol.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    return snap.docs.map((d) => VideoModel.fromMap(d.data(), d.id)).toList();
  }

  // ── User Videos ────────────────────────────────────────────────
  Stream<List<VideoModel>> userVideosStream(String uid) {
    return _videosCol
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => VideoModel.fromMap(d.data(), d.id)).toList());
  }

  // ── Upload ─────────────────────────────────────────────────────
  Future<VideoModel> uploadVideo({
    required File videoFile,
    required String userId,
    required String username,
    String userPhotoUrl = '',
    String caption = '',
    List<String> hashtags = const [],
    void Function(double)? onProgress,
  }) async {
    final videoId = _uuid.v4();

    // Upload video file
    final videoRef = _storage.ref().child('${AppConstants.videosPath}/$videoId.mp4');
    final uploadTask = videoRef.putFile(videoFile);

    uploadTask.snapshotEvents.listen((event) {
      final progress = event.bytesTransferred / event.totalBytes;
      onProgress?.call(progress);
    });

    await uploadTask;
    final videoUrl = await videoRef.getDownloadURL();

    // Create Firestore doc
    final video = VideoModel(
      id: videoId,
      userId: userId,
      username: username,
      userPhotoUrl: userPhotoUrl,
      videoUrl: videoUrl,
      caption: caption,
      hashtags: hashtags,
      createdAt: DateTime.now(),
    );

    await _videosCol.doc(videoId).set(video.toMap());

    // Update user post count
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'postsCount': FieldValue.increment(1)});

    // Update hashtag counts
    for (final tag in hashtags) {
      await _firestore
          .collection(AppConstants.hashtagsCollection)
          .doc(tag.toLowerCase())
          .set({'count': FieldValue.increment(1), 'tag': tag.toLowerCase()}, SetOptions(merge: true));
    }

    return video;
  }

  // ── Likes ──────────────────────────────────────────────────────
  Future<void> likeVideo(String videoId, String userId) async {
    final batch = _firestore.batch();
    batch.set(
      _videosCol.doc(videoId).collection(AppConstants.likesCollection).doc(userId),
      {'likedAt': FieldValue.serverTimestamp()},
    );
    batch.update(_videosCol.doc(videoId), {'likesCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> unlikeVideo(String videoId, String userId) async {
    final batch = _firestore.batch();
    batch.delete(_videosCol.doc(videoId).collection(AppConstants.likesCollection).doc(userId));
    batch.update(_videosCol.doc(videoId), {'likesCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<bool> isLiked(String videoId, String userId) async {
    final doc = await _videosCol.doc(videoId).collection(AppConstants.likesCollection).doc(userId).get();
    return doc.exists;
  }

  Stream<bool> isLikedStream(String videoId, String userId) {
    return _videosCol
        .doc(videoId)
        .collection(AppConstants.likesCollection)
        .doc(userId)
        .snapshots()
        .map((s) => s.exists);
  }

  // ── Views ──────────────────────────────────────────────────────
  Future<void> incrementViews(String videoId) async {
    await _videosCol.doc(videoId).update({'viewsCount': FieldValue.increment(1)});
  }

  // ── Comments ───────────────────────────────────────────────────
  Stream<List<CommentModel>> commentsStream(String videoId) {
    return _videosCol
        .doc(videoId)
        .collection(AppConstants.commentsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommentModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addComment(String videoId, CommentModel comment) async {
    final batch = _firestore.batch();
    batch.set(
      _videosCol.doc(videoId).collection(AppConstants.commentsCollection).doc(comment.id),
      comment.toMap(),
    );
    batch.update(_videosCol.doc(videoId), {'commentsCount': FieldValue.increment(1)});
    await batch.commit();
  }

  // ── Delete ─────────────────────────────────────────────────────
  Future<void> deleteVideo(String videoId, String userId) async {
    try {
      await _storage.ref().child('${AppConstants.videosPath}/$videoId.mp4').delete();
    } catch (_) {}
    await _videosCol.doc(videoId).delete();
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'postsCount': FieldValue.increment(-1)});
  }

  // ── Search by hashtag ──────────────────────────────────────────
  Future<List<VideoModel>> searchByHashtag(String hashtag) async {
    final snap = await _videosCol
        .where('hashtags', arrayContains: hashtag.toLowerCase())
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.searchPageSize)
        .get();
    return snap.docs.map((d) => VideoModel.fromMap(d.data(), d.id)).toList();
  }

  // ── Hashtags ───────────────────────────────────────────────────
  Future<Map<String, int>> getTrendingHashtags() async {
    final snap = await _firestore
        .collection(AppConstants.hashtagsCollection)
        .orderBy('count', descending: true)
        .limit(20)
        .get();
    return {for (final d in snap.docs) d.id: (d.data()['count'] as num).toInt()};
  }
}

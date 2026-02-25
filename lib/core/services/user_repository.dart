import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/user_model.dart';
import '../constants/app_constants.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection(AppConstants.usersCollection);

  // ── Create / Read ──────────────────────────────────────────────
  Future<void> createUser(UserModel user) async {
    await _usersCol.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final snap = await _usersCol.doc(uid).get();
    if (snap.exists) return UserModel.fromMap(snap.data()!);
    return null;
  }

  Stream<UserModel?> userStream(String uid) {
    return _usersCol.doc(uid).snapshots().map((snap) {
      if (snap.exists) return UserModel.fromMap(snap.data()!);
      return null;
    });
  }

  // ── Update Profile ─────────────────────────────────────────────
  Future<void> updateProfile(String uid, {String? displayName, String? bio, String? photoUrl}) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (data.isNotEmpty) await _usersCol.doc(uid).update(data);
  }

  Future<String> uploadProfilePhoto(String uid, File file) async {
    final ref = _storage.ref().child('${AppConstants.profilePhotosPath}/$uid.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _usersCol.doc(uid).update({'photoUrl': url});
    return url;
  }

  // ── Follow / Unfollow ──────────────────────────────────────────
  Future<void> followUser(String currentUid, String targetUid) async {
    final batch = _firestore.batch();

    // Add to current user's following
    batch.set(
      _usersCol.doc(currentUid).collection(AppConstants.followingCollection).doc(targetUid),
      {'followedAt': FieldValue.serverTimestamp()},
    );
    // Add to target user's followers
    batch.set(
      _usersCol.doc(targetUid).collection(AppConstants.followersCollection).doc(currentUid),
      {'followedAt': FieldValue.serverTimestamp()},
    );
    // Increment counts
    batch.update(_usersCol.doc(currentUid), {'followingCount': FieldValue.increment(1)});
    batch.update(_usersCol.doc(targetUid), {'followersCount': FieldValue.increment(1)});

    await batch.commit();
  }

  Future<void> unfollowUser(String currentUid, String targetUid) async {
    final batch = _firestore.batch();

    batch.delete(_usersCol.doc(currentUid).collection(AppConstants.followingCollection).doc(targetUid));
    batch.delete(_usersCol.doc(targetUid).collection(AppConstants.followersCollection).doc(currentUid));
    batch.update(_usersCol.doc(currentUid), {'followingCount': FieldValue.increment(-1)});
    batch.update(_usersCol.doc(targetUid), {'followersCount': FieldValue.increment(-1)});

    await batch.commit();
  }

  Future<bool> isFollowing(String currentUid, String targetUid) async {
    final doc = await _usersCol.doc(currentUid).collection(AppConstants.followingCollection).doc(targetUid).get();
    return doc.exists;
  }

  Stream<bool> isFollowingStream(String currentUid, String targetUid) {
    return _usersCol
        .doc(currentUid)
        .collection(AppConstants.followingCollection)
        .doc(targetUid)
        .snapshots()
        .map((s) => s.exists);
  }

  // ── Search ─────────────────────────────────────────────────────
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    final snap = await _usersCol
        .where('username', isGreaterThanOrEqualTo: lowerQuery)
        .where('username', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .limit(AppConstants.searchPageSize)
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  // ── Followers List ─────────────────────────────────────────────
  Future<List<UserModel>> getFollowers(String uid) async {
    final snap = await _usersCol.doc(uid).collection(AppConstants.followersCollection).get();
    final uids = snap.docs.map((d) => d.id).toList();
    if (uids.isEmpty) return [];
    final userSnaps = await _usersCol.where(FieldPath.documentId, whereIn: uids.take(10).toList()).get();
    return userSnaps.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }
}

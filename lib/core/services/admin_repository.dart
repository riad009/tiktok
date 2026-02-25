import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../constants/app_constants.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _reportsCol =>
      _firestore.collection(AppConstants.reportsCollection);

  CollectionReference<Map<String, dynamic>> get _videosCol =>
      _firestore.collection(AppConstants.videosCollection);

  // ── User Management ───────────────────────────────────────────
  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    final snap = await _usersCol
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  Future<List<UserModel>> searchUsersAdmin(String query) async {
    if (query.isEmpty) return getAllUsers();
    final lq = query.toLowerCase();
    final snap = await _usersCol
        .where('username', isGreaterThanOrEqualTo: lq)
        .where('username', isLessThanOrEqualTo: '$lq\uf8ff')
        .limit(30)
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  Future<void> banUser(String uid) async {
    await _usersCol.doc(uid).update({'isBanned': true});
  }

  Future<void> unbanUser(String uid) async {
    await _usersCol.doc(uid).update({'isBanned': false});
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _usersCol.doc(uid).update({'role': role});
  }

  Future<void> verifyUser(String uid, bool verified) async {
    await _usersCol.doc(uid).update({
      'isVerified': verified,
      'badgeType': verified ? 'verified' : '',
    });
  }

  // ── Content Moderation ────────────────────────────────────────
  Future<void> deleteContent(String videoId) async {
    await _videosCol.doc(videoId).delete();
  }

  // ── Reports ───────────────────────────────────────────────────
  Future<void> createReport(ReportModel report) async {
    final id = _uuid.v4();
    await _reportsCol.doc(id).set(report.toMap());
  }

  Stream<List<ReportModel>> reportsStream() {
    return _reportsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReportModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<List<ReportModel>> getPendingReports() async {
    final snap = await _reportsCol
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ReportModel.fromMap(d.data(), d.id)).toList();
  }

  Future<void> resolveReport(String reportId, String adminId, String action) async {
    await _reportsCol.doc(reportId).update({
      'status': action, // 'resolved' or 'dismissed'
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
      'resolvedBy': adminId,
    });
  }

  // ── Platform Stats ────────────────────────────────────────────
  Future<Map<String, int>> getPlatformStats() async {
    final usersSnap = await _usersCol.count().get();
    final videosSnap = await _videosCol.count().get();
    final reportsSnap = await _reportsCol
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    // Livestreams
    final livestreamsSnap = await _firestore
        .collection(AppConstants.livestreamsCollection)
        .count()
        .get();

    return {
      'totalUsers': usersSnap.count ?? 0,
      'totalVideos': videosSnap.count ?? 0,
      'pendingReports': reportsSnap.count ?? 0,
      'totalLivestreams': livestreamsSnap.count ?? 0,
    };
  }
}

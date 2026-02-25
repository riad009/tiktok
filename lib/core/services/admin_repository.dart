import '../../models/report_model.dart';
import '../../models/user_model.dart';
import 'api_service.dart';

class AdminRepository {
  // ── User Management ───────────────────────────────────────────
  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    return ApiService.getUsers();
  }

  Future<List<UserModel>> searchUsersAdmin(String query) async {
    if (query.isEmpty) return getAllUsers();
    final allUsers = await ApiService.getUsers();
    final lq = query.toLowerCase();
    return allUsers
        .where((u) =>
            u.username.toLowerCase().contains(lq) ||
            u.displayName.toLowerCase().contains(lq) ||
            u.email.toLowerCase().contains(lq))
        .toList();
  }

  Future<void> banUser(String uid) async {
    await ApiService.adminBanUser(uid, true);
  }

  Future<void> unbanUser(String uid) async {
    await ApiService.adminBanUser(uid, false);
  }

  Future<void> updateUserRole(String uid, String role) async {
    await ApiService.adminUpdateRole(uid, role);
  }

  Future<void> verifyUser(String uid, bool verified) async {
    await ApiService.adminVerifyUser(uid, verified);
  }

  // ── Content Moderation ────────────────────────────────────────
  Future<void> deleteContent(String postId) async {
    await ApiService.adminDeletePost(postId);
  }

  // ── Reports ───────────────────────────────────────────────────
  Future<List<ReportModel>> getReports() async {
    return ApiService.getAdminReports();
  }

  Future<void> resolveReport(String reportId, String adminId, String action) async {
    await ApiService.adminResolveReport(reportId, adminId, action);
  }

  // ── Platform Stats ────────────────────────────────────────────
  Future<Map<String, int>> getPlatformStats() async {
    return ApiService.getAdminStats();
  }
}

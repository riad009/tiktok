class ReportModel {
  final String id;
  final String reporterId;
  final String reporterUsername;
  final String targetId;
  final String targetType; // 'user', 'video', 'livestream', 'message'
  final String reason;
  final String details;
  final String status; // 'pending', 'resolved', 'dismissed'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  ReportModel({
    required this.id,
    required this.reporterId,
    this.reporterUsername = '',
    required this.targetId,
    required this.targetType,
    required this.reason,
    this.details = '',
    this.status = 'pending',
    DateTime? createdAt,
    this.resolvedAt,
    this.resolvedBy,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ReportModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ReportModel(
      id: docId ?? map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reporterUsername: map['reporterUsername'] ?? '',
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? 'user',
      reason: map['reason'] ?? '',
      details: map['details'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.tryParse(map['resolvedAt'].toString())
          : null,
      resolvedBy: map['resolvedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterUsername': reporterUsername,
      'targetId': targetId,
      'targetType': targetType,
      'reason': reason,
      'details': details,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolvedBy': resolvedBy,
    };
  }
}

class NotificationModel {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final int? artworkId;
  final String? eventId;
  final String? submissionId;
  final String? actionUrl;
  final String? iconType;

  NotificationModel({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.artworkId,
    this.eventId,
    this.submissionId,
    this.actionUrl,
    this.iconType,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      artworkId: json['artwork_id'] as int?,
      eventId: json['event_id'] as String?,
      submissionId: json['submission_id'] as String?,
      actionUrl: json['action_url'] as String?,
      iconType: json['icon_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'is_read': isRead,
      'artwork_id': artworkId,
      'event_id': eventId,
      'submission_id': submissionId,
      'action_url': actionUrl,
      'icon_type': iconType,
    };
  }

  NotificationModel copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    int? artworkId,
    String? eventId,
    String? submissionId,
    String? actionUrl,
    String? iconType,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      artworkId: artworkId ?? this.artworkId,
      eventId: eventId ?? this.eventId,
      submissionId: submissionId ?? this.submissionId,
      actionUrl: actionUrl ?? this.actionUrl,
      iconType: iconType ?? this.iconType,
    );
  }
}

class EventModel {
  final String id;
  final DateTime createdAt;
  final String title;
  final String? content;
  final DateTime? eventDate;
  final String? location;
  final String? imageUrl;
  final String status;
  final String? organizerId;
  final String? rejectionReason;
  final String? organizerName;

  EventModel({
    required this.id,
    required this.createdAt,
    required this.title,
    this.content,
    this.eventDate,
    this.location,
    this.imageUrl,
    required this.status,
    this.organizerId,
    this.rejectionReason,
    this.organizerName,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      title: json['title'] as String,
      content: json['content'] as String?,
      eventDate: json['event_date'] != null 
          ? DateTime.parse(json['event_date'] as String)
          : null,
      location: json['location'] as String?,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      organizerId: json['organizer_id'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      organizerName: json['organizer_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'title': title,
      'content': content,
      'event_date': eventDate?.toIso8601String(),
      'location': location,
      'image_url': imageUrl,
      'status': status,
      'organizer_id': organizerId,
      'rejection_reason': rejectionReason,
      'organizer_name': organizerName,
    };
  }

  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'menunggu_persetujuan':
      case 'menunggu':
        return 'Menunggu Persetujuan';
      case 'approved':
      case 'disetujui':
        return 'Disetujui';
      case 'rejected':
      case 'ditolak':
        return 'Ditolak';
      default:
        return status;
    }
  }

  bool get isPending => 
      status.toLowerCase() == 'pending' || 
      status.toLowerCase() == 'menunggu_persetujuan' ||
      status.toLowerCase() == 'menunggu';

  bool get isApproved => 
      status.toLowerCase() == 'approved' || 
      status.toLowerCase() == 'disetujui';

  bool get isRejected => 
      status.toLowerCase() == 'rejected' || 
      status.toLowerCase() == 'ditolak';
}

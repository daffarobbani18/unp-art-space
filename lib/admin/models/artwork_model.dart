class ArtworkModel {
  final int id;
  final String title;
  final String artistName;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String status;
  final String? category;
  final DateTime? createdAt;
  final double? aiGeneratedScore;
  final bool isAiSuspected;

  ArtworkModel({
    required this.id,
    required this.title,
    required this.artistName,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.status,
    this.category,
    this.createdAt,
    this.aiGeneratedScore,
    this.isAiSuspected = false,
  });

  factory ArtworkModel.fromJson(Map<String, dynamic> json) {
    return ArtworkModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      artistName: json['artist_name'] as String? ?? '',
      mediaUrl: json['media_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      category: json['category'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      aiGeneratedScore: _parseDouble(json['ai_generated_score']),
      isAiSuspected: json['is_ai_suspected'] as bool? ?? false,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist_name': artistName,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'status': status,
      'category': category,
      'created_at': createdAt?.toIso8601String(),
      'ai_generated_score': aiGeneratedScore,
      'is_ai_suspected': isAiSuspected,
    };
  }

  ArtworkModel copyWith({
    int? id,
    String? title,
    String? artistName,
    String? mediaUrl,
    String? thumbnailUrl,
    String? status,
    String? category,
    DateTime? createdAt,
    double? aiGeneratedScore,
    bool? isAiSuspected,
  }) {
    return ArtworkModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      aiGeneratedScore: aiGeneratedScore ?? this.aiGeneratedScore,
      isAiSuspected: isAiSuspected ?? this.isAiSuspected,
    );
  }

  // Computed properties
  String get scorePercentage {
    if (aiGeneratedScore == null) return '0%';
    return '${(aiGeneratedScore! * 100).toStringAsFixed(0)}%';
  }

  String get riskLevel {
    if (aiGeneratedScore == null || aiGeneratedScore! < 0.5) return 'Aman';
    if (aiGeneratedScore! < 0.8) return 'Risiko Rendah';
    if (aiGeneratedScore! < 0.9) return 'Risiko Sedang';
    return 'Risiko Tinggi';
  }

  bool get isHighRisk => aiGeneratedScore != null && aiGeneratedScore! > 0.9;
  bool get isMediumRisk => aiGeneratedScore != null && aiGeneratedScore! > 0.8 && aiGeneratedScore! <= 0.9;

  String get imageUrl => thumbnailUrl ?? mediaUrl ?? '';
}

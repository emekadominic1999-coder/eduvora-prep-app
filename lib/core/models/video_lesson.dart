import 'package:flutter/foundation.dart';

/// A catalogue entry in the video-lesson store. No payment is wired up yet —
/// [videoUrl] stays null until that is added, so the "Buy" action is honest
/// about not being live rather than pretending to process a payment.
@immutable
class VideoLesson {
  const VideoLesson({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.priceNaira,
    this.thumbnailUrl,
    this.videoUrl,
  });

  factory VideoLesson.fromRow(Map<String, dynamic> row) {
    return VideoLesson(
      id: row['id'] as String,
      subjectId: row['subject_id'] as String? ?? '',
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      priceNaira: (row['price_naira'] as num?)?.toDouble() ?? 0,
      thumbnailUrl: row['thumbnail_url'] as String?,
      videoUrl: row['video_url'] as String?,
    );
  }

  final String id;
  final String subjectId;
  final String title;
  final String description;
  final double priceNaira;
  final String? thumbnailUrl;
  final String? videoUrl;

  bool get isUnlocked => videoUrl != null && videoUrl!.isNotEmpty;
}

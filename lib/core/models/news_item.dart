import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// An editorially managed story — results, admissions, timetables and the
/// like. Students can read but never post to this feed, which keeps it free
/// of rumours and unverified claims about exam dates.
@immutable
class NewsItem {
  const NewsItem({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.body,
    required this.sourceLabel,
    required this.publishedAt,
    this.sourceUrl,
  });

  factory NewsItem.fromRow(Map<String, dynamic> row) {
    return NewsItem(
      id: row['id'] as String,
      category: row['category'] as String? ?? 'General News',
      title: row['title'] as String,
      summary: row['summary'] as String? ?? '',
      body: row['body'] as String? ?? '',
      sourceLabel: row['source_label'] as String? ?? '',
      sourceUrl: row['source_url'] as String?,
      publishedAt: DateTime.parse(row['published_at'] as String),
    );
  }

  final String id;
  final String category;
  final String title;
  final String summary;
  final String body;
  final String sourceLabel;
  final String? sourceUrl;
  final DateTime publishedAt;

  Color get categoryColour {
    switch (category) {
      case 'JAMB News':
        return AppColours.primary;
      case 'O\'Level News':
        return const Color(0xFF047857);
      case 'Admission News':
        return AppColours.accent;
      case 'Scholarship':
        return const Color(0xFF7C3AED);
      default:
        return AppColours.info;
    }
  }
}

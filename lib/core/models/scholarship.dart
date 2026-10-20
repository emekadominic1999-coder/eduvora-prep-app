import 'package:flutter/foundation.dart';

/// A scholarship listing. Admin-managed, like [NewsItem] — the entries
/// seeded with this app are clearly-labelled placeholders, not real
/// opportunities, until replaced with verified listings.
@immutable
class Scholarship {
  const Scholarship({
    required this.id,
    required this.title,
    required this.degreeLevel,
    required this.country,
    required this.description,
    this.deadline,
    this.link,
  });

  factory Scholarship.fromRow(Map<String, dynamic> row) {
    return Scholarship(
      id: row['id'] as String,
      title: row['title'] as String,
      degreeLevel: row['degree_level'] as String? ?? '',
      country: row['country'] as String? ?? '',
      description: row['description'] as String? ?? '',
      deadline: row['deadline'] == null
          ? null
          : DateTime.tryParse(row['deadline'] as String),
      link: row['link'] as String?,
    );
  }

  final String id;
  final String title;
  final String degreeLevel;
  final String country;
  final String description;
  final DateTime? deadline;
  final String? link;

  bool get isExpired =>
      deadline != null && deadline!.isBefore(DateTime.now());
}

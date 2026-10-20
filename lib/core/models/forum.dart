import 'package:flutter/foundation.dart';

/// The two question categories myschool.ng's forum splits by: questions
/// about a specific school (admissions, porter, fees) versus general
/// academic questions (subject help, career advice).
enum ForumCategory {
  school('School-based'),
  academic('Academic');

  const ForumCategory(this.label);

  final String label;

  static ForumCategory fromName(String? name) => ForumCategory.values
      .firstWhere((ForumCategory c) => c.name == name, orElse: () => academic);
}

@immutable
class ForumQuestion {
  const ForumQuestion({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.authorName = '',
    this.answerCount = 0,
  });

  factory ForumQuestion.fromRow(Map<String, dynamic> row) {
    return ForumQuestion(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      category: ForumCategory.fromName(row['category'] as String?),
      title: row['title'] as String,
      body: row['body'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
      authorName: row['author_name'] as String? ?? '',
      answerCount: (row['answer_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String userId;
  final ForumCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final String authorName;
  final int answerCount;
}

@immutable
class ForumAnswer {
  const ForumAnswer({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.authorName = '',
  });

  factory ForumAnswer.fromRow(Map<String, dynamic> row) {
    return ForumAnswer(
      id: row['id'] as String,
      questionId: row['question_id'] as String,
      userId: row['user_id'] as String,
      body: row['body'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      authorName: row['author_name'] as String? ?? '',
    );
  }

  final String id;
  final String questionId;
  final String userId;
  final String body;
  final DateTime createdAt;
  final String authorName;
}

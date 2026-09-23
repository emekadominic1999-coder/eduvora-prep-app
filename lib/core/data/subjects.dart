import 'package:flutter/material.dart';

import '../models/exam.dart';

/// The subject catalogue. Every question-bank asset is keyed by [Subject.id],
/// so the id doubles as the asset file name: `assets/question_bank/<id>.json`
class Subjects {
  const Subjects._();

  static const List<Subject> all = <Subject>[
    Subject(
      id: 'english',
      name: 'Use of English',
      shortName: 'English',
      icon: Icons.translate_rounded,
      colour: Color(0xFF2563EB),
      category: SubjectCategory.core,
    ),
    Subject(
      id: 'mathematics',
      name: 'Mathematics',
      shortName: 'Maths',
      icon: Icons.calculate_rounded,
      colour: Color(0xFF7C3AED),
      category: SubjectCategory.core,
    ),
    Subject(
      id: 'physics',
      name: 'Physics',
      shortName: 'Physics',
      icon: Icons.bolt_rounded,
      colour: Color(0xFF0891B2),
      category: SubjectCategory.science,
    ),
    Subject(
      id: 'chemistry',
      name: 'Chemistry',
      shortName: 'Chemistry',
      icon: Icons.science_rounded,
      colour: Color(0xFFDB2777),
      category: SubjectCategory.science,
    ),
    Subject(
      id: 'biology',
      name: 'Biology',
      shortName: 'Biology',
      icon: Icons.biotech_rounded,
      colour: Color(0xFF047857),
      category: SubjectCategory.science,
    ),
    Subject(
      id: 'economics',
      name: 'Economics',
      shortName: 'Economics',
      icon: Icons.trending_up_rounded,
      colour: Color(0xFFF97316),
      category: SubjectCategory.commercial,
    ),
    Subject(
      id: 'government',
      name: 'Government',
      shortName: 'Government',
      icon: Icons.account_balance_rounded,
      colour: Color(0xFF1E3A8A),
      category: SubjectCategory.arts,
    ),
    Subject(
      id: 'literature',
      name: 'Literature-in-English',
      shortName: 'Literature',
      icon: Icons.auto_stories_rounded,
      colour: Color(0xFFB45309),
      category: SubjectCategory.arts,
    ),
    Subject(
      id: 'commerce',
      name: 'Commerce',
      shortName: 'Commerce',
      icon: Icons.storefront_rounded,
      colour: Color(0xFF0D9488),
      category: SubjectCategory.commercial,
    ),
    Subject(
      id: 'accounting',
      name: 'Financial Accounting',
      shortName: 'Accounting',
      icon: Icons.receipt_long_rounded,
      colour: Color(0xFF4338CA),
      category: SubjectCategory.commercial,
    ),
    Subject(
      id: 'crs',
      name: 'Christian Religious Studies',
      shortName: 'CRS',
      icon: Icons.menu_book_rounded,
      colour: Color(0xFF9333EA),
      category: SubjectCategory.arts,
    ),
    Subject(
      id: 'geography',
      name: 'Geography',
      shortName: 'Geography',
      icon: Icons.public_rounded,
      colour: Color(0xFF166534),
      category: SubjectCategory.arts,
    ),
    Subject(
      id: 'agriculture',
      name: 'Agricultural Science',
      shortName: 'Agric',
      icon: Icons.agriculture_rounded,
      colour: Color(0xFF65A30D),
      category: SubjectCategory.science,
    ),
    Subject(
      id: 'civic',
      name: 'Civic Education',
      shortName: 'Civic Ed',
      icon: Icons.gavel_rounded,
      colour: Color(0xFFCA8A04),
      category: SubjectCategory.core,
    ),
  ];

  static Subject byId(String id) {
    return all.firstWhere(
      (Subject subject) => subject.id == id,
      orElse: () => all.first,
    );
  }

  static List<Subject> inCategory(SubjectCategory category) {
    return all.where((Subject s) => s.category == category).toList();
  }
}

/// JAMB's own rules: English carries 60 questions, every other subject 40,
/// and the whole four-subject sitting runs for two hours.
class JambRules {
  const JambRules._();

  static const int englishQuestions = 60;
  static const int subjectQuestions = 40;
  static const int sittingMinutes = 120;

  /// Minutes a single subject deserves inside a two-hour, 180-question paper.
  static int minutesFor(String subjectId) {
    return subjectId == 'english' ? 40 : 27;
  }
}

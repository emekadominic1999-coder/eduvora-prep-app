import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The examination bodies Eduvora Prep carries past questions for.
enum ExamBody {
  jamb(
    code: 'JAMB',
    name: 'JAMB UTME',
    longName: 'Joint Admissions and Matriculation Board',
    blurb: 'Computer-based UTME. Four subjects, 180 questions, 2 hours.',
    colour: AppColours.primary,
    icon: Icons.school_rounded,
  ),
  waec(
    code: 'WAEC',
    name: 'WAEC SSCE',
    longName: 'West African Examinations Council',
    blurb: 'May/June and GCE objective papers, subject by subject.',
    colour: Color(0xFF047857),
    icon: Icons.workspace_premium_rounded,
  ),
  neco(
    code: 'NECO',
    name: 'NECO SSCE',
    longName: 'National Examinations Council',
    blurb: 'June/July internal and November GCE objective papers.',
    colour: Color(0xFF7C3AED),
    icon: Icons.menu_book_rounded,
  ),
  postUtme(
    code: 'POST-UTME',
    name: 'Post-UTME',
    longName: 'University screening tests',
    blurb: 'Screening-style drills built from recurring UTME topics.',
    colour: AppColours.accent,
    icon: Icons.account_balance_rounded,
  );

  const ExamBody({
    required this.code,
    required this.name,
    required this.longName,
    required this.blurb,
    required this.colour,
    required this.icon,
  });

  final String code;
  final String name;
  final String longName;
  final String blurb;
  final Color colour;
  final IconData icon;

  static ExamBody fromCode(String code) {
    final String needle = code.trim().toUpperCase();
    return ExamBody.values.firstWhere(
      (ExamBody body) => body.code == needle,
      orElse: () => ExamBody.jamb,
    );
  }
}

/// A single multiple-choice past question.
@immutable
class Question {
  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.answerIndex,
    required this.topic,
    this.explanation = '',
    this.passage = '',
    this.instruction = '',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      options: List<String>.unmodifiable(
        (json['options'] as List<dynamic>).map((dynamic o) => o as String),
      ),
      answerIndex: json['answer'] as int,
      topic: json['topic'] as String? ?? 'General',
      explanation: json['explanation'] as String? ?? '',
      passage: json['passage'] as String? ?? '',
      instruction: json['instruction'] as String? ?? '',
    );
  }

  final String id;

  /// Optional comprehension passage or shared stimulus shown above the stem.
  final String passage;

  /// Optional directive, e.g. "Choose the option nearest in meaning".
  final String instruction;

  final String text;
  final List<String> options;
  final int answerIndex;
  final String topic;
  final String explanation;

  String get answerLetter => letterFor(answerIndex);

  String get answerText => options[answerIndex];

  static String letterFor(int index) => String.fromCharCode(65 + index);
}

/// One past paper: an exam body, a subject and a diet (year).
@immutable
class PastPaper {
  const PastPaper({
    required this.id,
    required this.body,
    required this.subjectId,
    required this.year,
    required this.questions,
    required this.durationMinutes,
    this.diet = '',
  });

  final String id;
  final ExamBody body;
  final String subjectId;
  final int year;

  /// e.g. "May/June", "November (GCE)". Blank for JAMB.
  final String diet;
  final int durationMinutes;
  final List<Question> questions;

  int get questionCount => questions.length;

  String get label => diet.isEmpty ? '$year' : '$year $diet';

  String get title => '${body.code} $label';
}

/// A subject in the secondary-school curriculum.
@immutable
class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.shortName,
    required this.icon,
    required this.colour,
    required this.category,
  });

  final String id;
  final String name;
  final String shortName;
  final IconData icon;
  final Color colour;
  final SubjectCategory category;
}

enum SubjectCategory {
  core('Core'),
  science('Science'),
  arts('Arts & Humanities'),
  commercial('Commercial');

  const SubjectCategory(this.label);

  final String label;
}

/// How an exam session is run.
enum PracticeMode {
  /// Timed, answers hidden until submission — mirrors the real CBT hall.
  exam('Exam mode', 'Timed. Answers revealed only after you submit.',
      Icons.timer_rounded),

  /// Untimed, correct answer and explanation revealed after each question.
  study('Study mode', 'Untimed. See the answer and why, question by question.',
      Icons.lightbulb_rounded);

  const PracticeMode(this.label, this.blurb, this.icon);

  final String label;
  final String blurb;
  final IconData icon;
}

/// The configuration a student picks before starting a session.
@immutable
class ExamConfig {
  const ExamConfig({
    required this.paper,
    required this.mode,
    required this.questionCount,
    required this.durationMinutes,
    required this.shuffleQuestions,
  });

  final PastPaper paper;
  final PracticeMode mode;
  final int questionCount;
  final int durationMinutes;
  final bool shuffleQuestions;
}

/// A finished attempt, stored locally so progress survives restarts.
@immutable
class AttemptRecord {
  const AttemptRecord({
    required this.id,
    required this.paperId,
    required this.bodyCode,
    required this.subjectId,
    required this.year,
    required this.mode,
    required this.correct,
    required this.total,
    required this.secondsUsed,
    required this.takenAt,
    required this.topicScores,
  });

  factory AttemptRecord.fromJson(Map<String, dynamic> json) {
    return AttemptRecord(
      id: json['id'] as String,
      paperId: json['paperId'] as String,
      bodyCode: json['bodyCode'] as String,
      subjectId: json['subjectId'] as String,
      year: json['year'] as int,
      mode: json['mode'] as String == 'study'
          ? PracticeMode.study
          : PracticeMode.exam,
      correct: json['correct'] as int,
      total: json['total'] as int,
      secondsUsed: json['secondsUsed'] as int,
      takenAt: DateTime.parse(json['takenAt'] as String),
      topicScores: <String, List<int>>{
        for (final MapEntry<String, dynamic> entry
            in (json['topics'] as Map<String, dynamic>? ??
                    <String, dynamic>{})
                .entries)
          entry.key: List<int>.from(entry.value as List<dynamic>),
      },
    );
  }

  final String id;
  final String paperId;
  final String bodyCode;
  final String subjectId;
  final int year;
  final PracticeMode mode;
  final int correct;
  final int total;
  final int secondsUsed;
  final DateTime takenAt;

  /// topic -> [correct, attempted]
  final Map<String, List<int>> topicScores;

  ExamBody get body => ExamBody.fromCode(bodyCode);

  double get percentage => total == 0 ? 0 : (correct / total) * 100;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'paperId': paperId,
        'bodyCode': bodyCode,
        'subjectId': subjectId,
        'year': year,
        'mode': mode.name,
        'correct': correct,
        'total': total,
        'secondsUsed': secondsUsed,
        'takenAt': takenAt.toIso8601String(),
        'topics': topicScores,
      };
}

/// Grading bands used on the result screen.
class Grade {
  const Grade(this.label, this.remark, this.colour);

  final String label;
  final String remark;
  final Color colour;

  static Grade forPercentage(double percentage) {
    if (percentage >= 75) {
      return const Grade('A1', 'Excellent', AppColours.success);
    }
    if (percentage >= 70) {
      return const Grade('B2', 'Very good', AppColours.success);
    }
    if (percentage >= 65) {
      return const Grade('B3', 'Good', Color(0xFF15803D));
    }
    if (percentage >= 60) {
      return const Grade('C4', 'Credit', AppColours.info);
    }
    if (percentage >= 55) {
      return const Grade('C5', 'Credit', AppColours.info);
    }
    if (percentage >= 50) {
      return const Grade('C6', 'Credit', AppColours.info);
    }
    if (percentage >= 45) {
      return const Grade('D7', 'Pass', AppColours.warning);
    }
    if (percentage >= 40) {
      return const Grade('E8', 'Pass', AppColours.warning);
    }
    return const Grade('F9', 'Keep practising', AppColours.danger);
  }
}

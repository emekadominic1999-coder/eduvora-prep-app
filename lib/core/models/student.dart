import 'exam.dart';

/// Where the student currently is in secondary school.
enum ClassLevel {
  ss1('SS 1'),
  ss2('SS 2'),
  ss3('SS 3'),
  graduate('Finished school');

  const ClassLevel(this.label);

  final String label;

  static ClassLevel fromName(String? name) => ClassLevel.values.firstWhere(
        (ClassLevel level) => level.name == name,
        orElse: () => ClassLevel.ss3,
      );
}

/// The locally held profile. No account, no server — the app is usable the
/// moment it is installed, which matters when data is expensive.
class StudentProfile {
  const StudentProfile({
    this.name = '',
    this.level = ClassLevel.ss3,
    this.targetBody = ExamBody.jamb,
    this.subjectIds = const <String>['english'],
    this.examDate,
    this.onboarded = false,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      name: json['name'] as String? ?? '',
      level: ClassLevel.fromName(json['level'] as String?),
      targetBody: ExamBody.fromCode(json['targetBody'] as String? ?? 'JAMB'),
      subjectIds: List<String>.from(
        json['subjects'] as List<dynamic>? ?? const <dynamic>['english'],
      ),
      examDate: json['examDate'] == null
          ? null
          : DateTime.tryParse(json['examDate'] as String),
      onboarded: json['onboarded'] as bool? ?? false,
    );
  }

  final String name;
  final ClassLevel level;
  final ExamBody targetBody;
  final List<String> subjectIds;
  final DateTime? examDate;
  final bool onboarded;

  String get firstName {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  int? get daysToExam {
    final DateTime? date = examDate;
    if (date == null) return null;
    final DateTime today = DateTime.now();
    final DateTime start = DateTime(today.year, today.month, today.day);
    final DateTime target = DateTime(date.year, date.month, date.day);
    return target.difference(start).inDays;
  }

  StudentProfile copyWith({
    String? name,
    ClassLevel? level,
    ExamBody? targetBody,
    List<String>? subjectIds,
    DateTime? examDate,
    bool clearExamDate = false,
    bool? onboarded,
  }) {
    return StudentProfile(
      name: name ?? this.name,
      level: level ?? this.level,
      targetBody: targetBody ?? this.targetBody,
      subjectIds: subjectIds ?? this.subjectIds,
      examDate: clearExamDate ? null : (examDate ?? this.examDate),
      onboarded: onboarded ?? this.onboarded,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'level': level.name,
        'targetBody': targetBody.code,
        'subjects': subjectIds,
        'examDate': examDate?.toIso8601String(),
        'onboarded': onboarded,
      };
}

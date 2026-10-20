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

/// The signed-in student's academic identity. Keyed to the Supabase auth
/// user, and synced to the `profiles` table so it follows the student
/// between devices.
class StudentProfile {
  const StudentProfile({
    this.id = '',
    this.email = '',
    this.name = '',
    this.level = ClassLevel.ss3,
    this.targetBody = ExamBody.jamb,
    this.subjectIds = const <String>['english'],
    this.examDate,
    this.onboarded = false,
  });

  /// A fresh profile for a just-created account, before onboarding runs.
  factory StudentProfile.empty(String id, String email, String name) {
    return StudentProfile(id: id, email: email, name: name);
  }

  /// From the local cache (camelCase — written by this app only).
  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
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

  /// From a row of the `profiles` table (snake_case).
  factory StudentProfile.fromRow(Map<String, dynamic> row) {
    return StudentProfile(
      id: row['id'] as String? ?? '',
      email: row['email'] as String? ?? '',
      name: row['full_name'] as String? ?? '',
      level: ClassLevel.fromName(row['class_level'] as String?),
      targetBody: ExamBody.fromCode(row['target_body'] as String? ?? 'JAMB'),
      subjectIds: List<String>.from(
        row['subject_ids'] as List<dynamic>? ?? const <dynamic>['english'],
      ),
      examDate: row['exam_date'] == null
          ? null
          : DateTime.tryParse(row['exam_date'] as String),
      onboarded: row['onboarded'] as bool? ?? false,
    );
  }

  final String id;
  final String email;
  final String name;
  final ClassLevel level;
  final ExamBody targetBody;
  final List<String> subjectIds;
  final DateTime? examDate;
  final bool onboarded;

  /// A profile counts as set up once a name has been given — the rest
  /// (class, exam body, subjects) all have sensible defaults.
  bool get isComplete => name.trim().isNotEmpty;

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
    String? id,
    String? email,
    String? name,
    ClassLevel? level,
    ExamBody? targetBody,
    List<String>? subjectIds,
    DateTime? examDate,
    bool clearExamDate = false,
    bool? onboarded,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      level: level ?? this.level,
      targetBody: targetBody ?? this.targetBody,
      subjectIds: subjectIds ?? this.subjectIds,
      examDate: clearExamDate ? null : (examDate ?? this.examDate),
      onboarded: onboarded ?? this.onboarded,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'name': name,
        'level': level.name,
        'targetBody': targetBody.code,
        'subjects': subjectIds,
        'examDate': examDate?.toIso8601String(),
        'onboarded': onboarded,
      };

  /// For an upsert into the `profiles` table (snake_case columns).
  Map<String, dynamic> toRow() => <String, dynamic>{
        'id': id,
        'full_name': name,
        'email': email,
        'class_level': level.name,
        'target_body': targetBody.code,
        'subject_ids': subjectIds,
        'exam_date': examDate == null
            ? null
            : '${examDate!.year.toString().padLeft(4, '0')}-'
                '${examDate!.month.toString().padLeft(2, '0')}-'
                '${examDate!.day.toString().padLeft(2, '0')}',
        'onboarded': onboarded,
      };
}

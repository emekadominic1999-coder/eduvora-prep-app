import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/subjects.dart';
import '../../../core/models/exam.dart';
import '../../../core/models/student.dart';
import '../../../core/services/question_bank.dart';
import '../../../core/state/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../bookmarks/presentation/bookmarks_screen.dart';

/// Profile and settings: name, class, target exam, exam date, subjects, and
/// the sign-out control — there being no offline mode here, signing out is a
/// real action, not a toggle.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sessionController,
      builder: (BuildContext context, Widget? _) {
        final StudentProfile profile =
            sessionController.profile ?? const StudentProfile();
        final TextTheme text = Theme.of(context).textTheme;
        final QuestionBank bank = QuestionBank.instance;

        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: <Widget>[
              AppCard(
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 56,
                      width: 56,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: AppColours.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        profile.firstName.isEmpty
                            ? '?'
                            : profile.firstName.characters.first.toUpperCase(),
                        style: text.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            profile.name.isEmpty ? 'Student' : profile.name,
                            style: text.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.email.isEmpty
                                ? '${profile.level.label} · Preparing for '
                                    '${profile.targetBody.code}'
                                : profile.email,
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editName(context, profile),
                      icon: const Icon(Icons.edit_rounded, size: 19),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.bookmark_rounded),
                  title: const Text('Saved questions'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BookmarksScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Exam settings'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.school_rounded),
                      title: const Text('Target exam'),
                      subtitle: Text(profile.targetBody.name),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _pickBody(context, profile),
                    ),
                    const Divider(
                      indent: AppSpacing.lg,
                      endIndent: AppSpacing.lg,
                    ),
                    ListTile(
                      leading: const Icon(Icons.class_rounded),
                      title: const Text('Class'),
                      subtitle: Text(profile.level.label),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _pickLevel(context, profile),
                    ),
                    const Divider(
                      indent: AppSpacing.lg,
                      endIndent: AppSpacing.lg,
                    ),
                    ListTile(
                      leading: const Icon(Icons.event_rounded),
                      title: const Text('Exam date'),
                      subtitle: Text(
                        profile.examDate == null
                            ? 'Not set'
                            : DateFormat('d MMMM y').format(profile.examDate!),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _pickDate(context, profile),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'My subjects',
                subtitle: '${profile.subjectIds.length} of 4 selected.',
              ),
              AppCard(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: Subjects.all.map((Subject subject) {
                    final bool selected =
                        profile.subjectIds.contains(subject.id);
                    final bool stocked = bank.hasContent(subject.id);
                    return FilterChip(
                      avatar: Icon(
                        subject.icon,
                        size: 16,
                        color: selected ? Colors.white : subject.colour,
                      ),
                      label: Text(subject.shortName),
                      selected: selected,
                      selectedColor: subject.colour,
                      onSelected: stocked
                          ? (_) => _toggleSubject(profile, subject.id)
                          : null,
                      labelStyle: text.labelMedium?.copyWith(
                        color: selected
                            ? Colors.white
                            : stocked
                                ? AppColours.text
                                : AppColours.textFaint,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'About'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const PrepLogo(size: 38),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Eduvora Prep', style: text.titleSmall),
                              Text('Version 1.0.0', style: text.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${bank.totalQuestions} past questions across '
                      '${bank.papers.length} papers, every one with a '
                      'written explanation.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed:
                    sessionController.isBusy ? null : () => _signOut(context),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColours.danger,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleSubject(StudentProfile profile, String subjectId) {
    final List<String> next = List<String>.from(profile.subjectIds);
    if (next.contains(subjectId)) {
      if (next.length <= 1) return Future<void>.value();
      next.remove(subjectId);
    } else {
      if (next.length >= 4) return Future<void>.value();
      next.add(subjectId);
    }
    return sessionController.saveProfile(profile.copyWith(subjectIds: next));
  }

  Future<void> _signOut(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You can sign back in any time with the same email and password.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColours.danger,
              minimumSize: const Size(110, 44),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await sessionController.signOut();
    }
  }

  Future<void> _editName(BuildContext context, StudentProfile profile) async {
    final TextEditingController controller =
        TextEditingController(text: profile.name);
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) {
      await sessionController.saveProfile(profile.copyWith(name: name));
    }
  }

  Future<void> _pickBody(BuildContext context, StudentProfile profile) async {
    final ExamBody? body = await showModalBottomSheet<ExamBody>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ExamBody.values.map((ExamBody value) {
            return ListTile(
              leading: Icon(value.icon, color: value.colour),
              title: Text(value.name),
              subtitle: Text(value.longName),
              trailing: value == profile.targetBody
                  ? const Icon(Icons.check_rounded, color: AppColours.primary)
                  : null,
              onTap: () => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );
    if (body != null) {
      await sessionController.saveProfile(profile.copyWith(targetBody: body));
    }
  }

  Future<void> _pickLevel(BuildContext context, StudentProfile profile) async {
    final ClassLevel? level = await showModalBottomSheet<ClassLevel>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ClassLevel.values.map((ClassLevel value) {
            return ListTile(
              title: Text(value.label),
              trailing: value == profile.level
                  ? const Icon(Icons.check_rounded, color: AppColours.primary)
                  : null,
              onTap: () => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );
    if (level != null) {
      await sessionController.saveProfile(profile.copyWith(level: level));
    }
  }

  Future<void> _pickDate(BuildContext context, StudentProfile profile) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: profile.examDate ?? now.add(const Duration(days: 60)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      await sessionController.saveProfile(profile.copyWith(examDate: picked));
    }
  }
}

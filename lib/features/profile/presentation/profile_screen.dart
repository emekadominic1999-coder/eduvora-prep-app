import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/subjects.dart';
import '../../../core/models/exam.dart';
import '../../../core/models/student.dart';
import '../../../core/services/question_bank.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';

/// Profile and settings: name, class, target exam, exam date and subjects.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final StudentProfile profile = state.profile;
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
                    profile.firstName.characters.first.toUpperCase(),
                    style: text.headlineSmall?.copyWith(color: Colors.white),
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
                        '${profile.level.label} · '
                        'Preparing for ${profile.targetBody.code}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editName(context, state),
                  icon: const Icon(Icons.edit_rounded, size: 19),
                ),
              ],
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
                  onTap: () => _pickBody(context, state),
                ),
                const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.class_rounded),
                  title: const Text('Class'),
                  subtitle: Text(profile.level.label),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickLevel(context, state),
                ),
                const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.event_rounded),
                  title: const Text('Exam date'),
                  subtitle: Text(
                    profile.examDate == null
                        ? 'Not set'
                        : DateFormat('d MMMM y').format(profile.examDate!),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickDate(context, state),
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
                final bool selected = profile.subjectIds.contains(subject.id);
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
                  onSelected:
                      stocked ? (_) => state.toggleSubject(subject.id) : null,
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
                  '${bank.papers.length} papers, every one with a written '
                  'explanation. Everything works offline once installed.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, AppState state) async {
    final TextEditingController controller =
        TextEditingController(text: state.profile.name);
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
    if (name != null) {
      await state.saveProfile(state.profile.copyWith(name: name));
    }
  }

  Future<void> _pickBody(BuildContext context, AppState state) async {
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
              trailing: value == state.profile.targetBody
                  ? const Icon(Icons.check_rounded, color: AppColours.primary)
                  : null,
              onTap: () => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );
    if (body != null) {
      await state.saveProfile(state.profile.copyWith(targetBody: body));
    }
  }

  Future<void> _pickLevel(BuildContext context, AppState state) async {
    final ClassLevel? level = await showModalBottomSheet<ClassLevel>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ClassLevel.values.map((ClassLevel value) {
            return ListTile(
              title: Text(value.label),
              trailing: value == state.profile.level
                  ? const Icon(Icons.check_rounded, color: AppColours.primary)
                  : null,
              onTap: () => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );
    if (level != null) {
      await state.saveProfile(state.profile.copyWith(level: level));
    }
  }

  Future<void> _pickDate(BuildContext context, AppState state) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: state.profile.examDate ?? now.add(const Duration(days: 60)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      await state.saveProfile(state.profile.copyWith(examDate: picked));
    }
  }
}

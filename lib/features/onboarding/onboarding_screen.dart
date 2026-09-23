import 'package:flutter/material.dart';

import '../../core/data/subjects.dart';
import '../../core/models/exam.dart';
import '../../core/models/student.dart';
import '../../core/services/question_bank.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../home/home_shell.dart';

/// Three quick steps before the student reaches the dashboard: who they are,
/// which exam they are sitting, and which subjects they are taking.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  final TextEditingController _name = TextEditingController();

  int _step = 0;
  ClassLevel _level = ClassLevel.ss3;
  ExamBody _body = ExamBody.jamb;
  final Set<String> _subjects = <String>{'english'};
  DateTime? _examDate;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 2) {
      _finish();
      return;
    }
    setState(() => _step += 1);
    _pages.animateToPage(
      _step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
    _pages.animateToPage(
      _step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final AppState state = AppScope.read(context);
    await state.saveProfile(
      StudentProfile(
        name: _name.text.trim(),
        level: _level,
        targetBody: _body,
        subjectIds: _subjects.toList(),
        examDate: _examDate,
        onboarded: true,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    );
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return true;
      case 1:
        return true;
      case 2:
        return _subjects.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _Header(step: _step, onBack: _step == 0 ? null : _back),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  _WelcomeStep(
                    controller: _name,
                    level: _level,
                    onLevel: (ClassLevel l) => setState(() => _level = l),
                  ),
                  _ExamStep(
                    body: _body,
                    examDate: _examDate,
                    onBody: (ExamBody b) => setState(() => _body = b),
                    onDate: (DateTime? d) => setState(() => _examDate = d),
                  ),
                  _SubjectStep(
                    body: _body,
                    selected: _subjects,
                    onToggle: (String id) {
                      setState(() {
                        if (_subjects.contains(id)) {
                          if (_subjects.length > 1) _subjects.remove(id);
                        } else if (_subjects.length < 4) {
                          _subjects.add(id);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: FilledButton(
                onPressed: _canContinue ? _next : null,
                child: Text(_step == 2 ? 'Start practising' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step, this.onBack});

  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColours.surfaceMuted,
              ),
            )
          else
            const PrepLogo(size: 40),
          const Spacer(),
          Row(
            children: List<Widget>.generate(3, (int i) {
              final bool active = i <= step;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                margin: const EdgeInsets.only(left: 6),
                height: 6,
                width: active ? 24 : 12,
                decoration: BoxDecoration(
                  color: active ? AppColours.primary : AppColours.border,
                  borderRadius: AppRadii.pill,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    required this.controller,
    required this.level,
    required this.onLevel,
  });

  final TextEditingController controller;
  final ClassLevel level;
  final ValueChanged<ClassLevel> onLevel;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: <Widget>[
        Text('Welcome to Eduvora Prep', style: text.displaySmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Past questions for JAMB, WAEC and NECO — timed exactly like the '
          'real computer-based test, and fully usable offline.',
          style: text.bodyMedium?.copyWith(color: AppColours.textMuted),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('What should we call you?', style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Your name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Which class are you in?', style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: ClassLevel.values.map((ClassLevel value) {
            return ChoiceChip(
              label: Text(value.label),
              selected: value == level,
              onSelected: (_) => onLevel(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ExamStep extends StatelessWidget {
  const _ExamStep({
    required this.body,
    required this.examDate,
    required this.onBody,
    required this.onDate,
  });

  final ExamBody body;
  final DateTime? examDate;
  final ValueChanged<ExamBody> onBody;
  final ValueChanged<DateTime?> onDate;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: <Widget>[
        Text('Which exam are you writing?', style: text.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We will tune the timer and question count to match that body.',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        ...ExamBody.values.map((ExamBody value) {
          final bool selected = value == body;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              onTap: () => onBody(value),
              border: Border.all(
                color: selected ? value.colour : AppColours.border,
                width: selected ? 1.8 : 1,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: value.colour.withValues(alpha: 0.12),
                      borderRadius: AppRadii.md,
                    ),
                    child: Icon(value.icon, color: value.colour, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(value.name, style: text.titleSmall),
                        const SizedBox(height: 2),
                        Text(value.blurb, style: text.bodySmall),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? value.colour : AppColours.borderStrong,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.sm),
        Text('When is your exam? (optional)', style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          onTap: () async {
            final DateTime now = DateTime.now();
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: examDate ?? now.add(const Duration(days: 60)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 730)),
            );
            if (picked != null) onDate(picked);
          },
          child: Row(
            children: <Widget>[
              const Icon(Icons.event_rounded, color: AppColours.accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  examDate == null
                      ? 'Set a date to see your countdown'
                      : '${examDate!.day}/${examDate!.month}/${examDate!.year}',
                  style: text.bodyMedium,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubjectStep extends StatelessWidget {
  const _SubjectStep({
    required this.body,
    required this.selected,
    required this.onToggle,
  });

  final ExamBody body;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final QuestionBank bank = QuestionBank.instance;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: <Widget>[
        Text('Pick your subjects', style: text.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          body == ExamBody.jamb
              ? 'JAMB allows four subjects. Use of English is compulsory, so '
                  'choose three others.'
              : 'Choose up to four subjects to keep on your dashboard.',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: Pill(
            '${selected.length} of 4 selected',
            icon: Icons.checklist_rounded,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...SubjectCategory.values.map((SubjectCategory category) {
          final List<Subject> subjects = Subjects.inCategory(category);
          if (subjects.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  category.label.toUpperCase(),
                  style: text.labelSmall?.copyWith(
                    color: AppColours.textFaint,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: subjects.map((Subject subject) {
                  final bool isSelected = selected.contains(subject.id);
                  final bool stocked = bank.hasContent(subject.id);
                  return FilterChip(
                    avatar: Icon(
                      subject.icon,
                      size: 16,
                      color: isSelected ? Colors.white : subject.colour,
                    ),
                    label: Text(subject.shortName),
                    selected: isSelected,
                    onSelected: stocked ? (_) => onToggle(subject.id) : null,
                    selectedColor: subject.colour,
                    labelStyle: text.labelMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : stocked
                              ? AppColours.text
                              : AppColours.textFaint,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          );
        }),
      ],
    );
  }
}

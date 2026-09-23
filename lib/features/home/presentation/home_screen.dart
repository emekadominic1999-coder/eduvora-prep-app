import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/guides.dart';
import '../../../core/data/subjects.dart';
import '../../../core/models/exam.dart';
import '../../../core/models/student.dart';
import '../../../core/services/question_bank.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../exam/presentation/exam_setup_sheet.dart';
import '../../practice/presentation/subject_papers_screen.dart';
import '../home_shell.dart';

/// The dashboard: countdown, quick actions, the student's own subjects,
/// recent attempts and the exam guide.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final StudentProfile profile = state.profile;
    final QuestionBank bank = QuestionBank.instance;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: <Widget>[
            _Greeting(profile: profile, streak: state.streak),
            const SizedBox(height: AppSpacing.xl),
            _CountdownCard(profile: profile),
            const SizedBox(height: AppSpacing.xl),
            _QuickActions(profile: profile),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Your subjects',
              subtitle: 'Tap to open the papers for ${profile.targetBody.code}.',
              actionLabel: 'Browse all',
              onAction: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const HomeShell(initialIndex: 1),
                ),
              ),
            ),
            _SubjectStrip(profile: profile),
            const SizedBox(height: AppSpacing.xl),
            if (state.attempts.isNotEmpty) ...<Widget>[
              SectionHeader(
                title: 'Recent attempts',
                subtitle:
                    'Overall accuracy ${state.overallAccuracy.toStringAsFixed(0)}% '
                    'across ${state.questionsAnswered} questions.',
                actionLabel: 'See all',
                onAction: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const HomeShell(initialIndex: 2),
                  ),
                ),
              ),
              ...state.attempts.take(3).map(
                    (AttemptRecord attempt) =>
                        _AttemptTile(attempt: attempt),
                  ),
              const SizedBox(height: AppSpacing.xl),
            ] else ...<Widget>[
              AppCard(
                colour: AppColours.primaryTint,
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.rocket_launch_rounded,
                        color: AppColours.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'You have ${bank.totalQuestions} past questions '
                        'waiting, all with explanations. Start with a short '
                        'drill to see where you stand.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            const SectionHeader(
              title: 'Exam guide',
              subtitle: 'How the exams work, and how to work them.',
            ),
            const _GuideStrip(),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.profile, required this.streak});

  final StudentProfile profile;
  final int streak;

  String get _timeOfDay {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        const PrepLogo(size: 42),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('$_timeOfDay,', style: text.bodySmall),
              Text(
                profile.firstName,
                style: text.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (streak > 0)
          Pill(
            '$streak day${streak == 1 ? '' : 's'}',
            colour: AppColours.accent,
            icon: Icons.local_fire_department_rounded,
          ),
      ],
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int? days = profile.daysToExam;
    final ExamBody body = profile.targetBody;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColours.brandGradient,
        borderRadius: AppRadii.xl,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  body.name.toUpperCase(),
                  style: text.labelSmall?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (days == null)
                  Text(
                    'Set your exam date to start the countdown',
                    style: text.titleMedium?.copyWith(color: Colors.white),
                  )
                else if (days > 0)
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: '$days',
                          style: text.displayMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: days == 1 ? ' day to go' : ' days to go',
                          style: text.titleSmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (days == 0)
                  Text(
                    'Today is the day. Go and take it.',
                    style: text.titleMedium?.copyWith(color: Colors.white),
                  )
                else
                  Text(
                    'Exam date has passed. Update it in your profile.',
                    style: text.titleSmall?.copyWith(color: Colors.white),
                  ),
                if (days != null && days > 0) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    DateFormat('EEEE, d MMMM y').format(profile.examDate!),
                    style: text.bodySmall?.copyWith(color: Colors.white60),
                  ),
                ],
              ],
            ),
          ),
          Icon(body.icon, color: Colors.white24, size: 58),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.profile});

  final StudentProfile profile;

  void _quickDrill(BuildContext context, PracticeMode mode) {
    final QuestionBank bank = QuestionBank.instance;
    final List<Question> pool = <Question>[
      for (final String id in profile.subjectIds)
        ...bank.allQuestionsFor(id, body: profile.targetBody),
    ];

    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No questions for those subjects yet.'),
        ),
      );
      return;
    }

    pool.shuffle(Random());
    final int count = min(20, pool.length);
    final PastPaper drill = PastPaper(
      id: 'quick-drill-${profile.targetBody.code.toLowerCase()}',
      body: profile.targetBody,
      subjectId: profile.subjectIds.first,
      year: DateTime.now().year,
      diet: 'Quick drill',
      durationMinutes: (count * 0.75).ceil().clamp(5, 60),
      questions: pool.take(count).toList(),
    );
    startPaper(context, drill);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ActionTile(
            icon: Icons.bolt_rounded,
            label: 'Quick drill',
            caption: '20 mixed questions',
            colour: AppColours.primary,
            onTap: () => _quickDrill(context, PracticeMode.exam),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionTile(
            icon: Icons.library_books_rounded,
            label: 'Full paper',
            caption: 'Sit a real past paper',
            colour: AppColours.accent,
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const HomeShell(initialIndex: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.colour,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final Color colour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.12),
              borderRadius: AppRadii.sm,
            ),
            child: Icon(icon, color: colour, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: text.titleSmall),
          const SizedBox(height: 2),
          Text(caption, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _SubjectStrip extends StatelessWidget {
  const _SubjectStrip({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    final QuestionBank bank = QuestionBank.instance;
    final TextTheme text = Theme.of(context).textTheme;

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: profile.subjectIds.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext context, int i) {
          final Subject subject = Subjects.byId(profile.subjectIds[i]);
          final List<PastPaper> papers =
              bank.forSubjectAndBody(subject.id, profile.targetBody);
          final int questions = papers.fold<int>(
            0,
            (int sum, PastPaper p) => sum + p.questionCount,
          );

          return SizedBox(
            width: 168,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              onTap: papers.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SubjectPapersScreen(
                            subject: subject,
                            body: profile.targetBody,
                          ),
                        ),
                      ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: subject.colour.withValues(alpha: 0.12),
                      borderRadius: AppRadii.sm,
                    ),
                    child: Icon(subject.icon, color: subject.colour, size: 19),
                  ),
                  const Spacer(),
                  Text(
                    subject.shortName,
                    style: text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    papers.isEmpty
                        ? 'No ${profile.targetBody.code} paper yet'
                        : '$questions questions',
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt});

  final AttemptRecord attempt;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Subject subject = Subjects.byId(attempt.subjectId);
    final Grade grade = Grade.forPercentage(attempt.percentage);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: subject.colour.withValues(alpha: 0.12),
                borderRadius: AppRadii.sm,
              ),
              child: Icon(subject.icon, color: subject.colour, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(subject.shortName, style: text.titleSmall),
                  Text(
                    '${attempt.bodyCode} ${attempt.year} · '
                    '${DateFormat('d MMM').format(attempt.takenAt)}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${attempt.correct}/${attempt.total}',
                  style: text.titleSmall?.copyWith(color: grade.colour),
                ),
                Text(
                  '${attempt.percentage.toStringAsFixed(0)}%',
                  style: text.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideStrip extends StatelessWidget {
  const _GuideStrip();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: Guides.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext context, int i) {
          final GuideItem item = Guides.all[i];
          return SizedBox(
            width: 236,
            child: AppCard(
              onTap: () => _openGuide(context, item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(item.icon, color: item.colour, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Pill(item.category, colour: item.colour),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    item.title,
                    style: text.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      item.summary,
                      style: text.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Read',
                    style: text.labelMedium?.copyWith(
                      color: AppColours.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openGuide(BuildContext context, GuideItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.94,
        builder: (BuildContext context, ScrollController controller) {
          final TextTheme text = Theme.of(context).textTheme;
          return ListView(
            controller: controller,
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(item.icon, color: item.colour),
                  const SizedBox(width: AppSpacing.sm),
                  Pill(item.category, colour: item.colour),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(item.title, style: text.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              Text(item.body, style: text.bodyMedium),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }
}

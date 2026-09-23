import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/subjects.dart';
import '../../../core/models/exam.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../home/home_shell.dart';

/// Progress over time: headline figures, subject ranking, weak topics and the
/// full attempt history.
class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<AttemptRecord> attempts = state.attempts;

    if (attempts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Progress')),
        body: EmptyState(
          icon: Icons.insights_rounded,
          title: 'No attempts yet',
          message:
              'Sit a paper and your scores, weak topics and streak will '
              'appear here.',
          actionLabel: 'Go to past questions',
          onAction: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const HomeShell(initialIndex: 1),
            ),
          ),
        ),
      );
    }

    final List<MapEntry<String, double>> ranking = state.subjectRanking();
    final List<MapEntry<String, double>> weak = state.weakTopics();

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _HeadlineTile(
                  label: 'Papers sat',
                  value: '${attempts.length}',
                  icon: Icons.assignment_turned_in_rounded,
                  colour: AppColours.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _HeadlineTile(
                  label: 'Accuracy',
                  value: '${state.overallAccuracy.toStringAsFixed(0)}%',
                  icon: Icons.track_changes_rounded,
                  colour: AppColours.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _HeadlineTile(
                  label: 'Questions done',
                  value: '${state.questionsAnswered}',
                  icon: Icons.quiz_rounded,
                  colour: AppColours.info,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _HeadlineTile(
                  label: 'Day streak',
                  value: '${state.streak}',
                  icon: Icons.local_fire_department_rounded,
                  colour: AppColours.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Last five papers',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 120,
                  child: _TrendChart(
                    attempts: attempts.take(5).toList().reversed.toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Average ${state.recentAverage().toStringAsFixed(0)}% '
                  'over the most recent papers.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (ranking.isNotEmpty) ...<Widget>[
            const SectionHeader(
              title: 'By subject',
              subtitle: 'Strongest at the top.',
            ),
            AppCard(
              child: Column(
                children: ranking.map((MapEntry<String, double> entry) {
                  final Subject subject = Subjects.byId(entry.key);
                  return MeterRow(
                    label: subject.name,
                    value: entry.value,
                    colour: subject.colour,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (weak.isNotEmpty) ...<Widget>[
            const SectionHeader(
              title: 'Topics to revise',
              subtitle: 'Where you keep dropping marks.',
            ),
            AppCard(
              child: Column(
                children: weak.map((MapEntry<String, double> entry) {
                  return MeterRow(
                    label: entry.key,
                    value: entry.value,
                    colour: entry.value >= 60
                        ? AppColours.success
                        : entry.value >= 40
                            ? AppColours.warning
                            : AppColours.danger,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          const SectionHeader(title: 'History'),
          ...attempts.map((AttemptRecord attempt) {
            final Subject subject = Subjects.byId(attempt.subjectId);
            final Grade grade = Grade.forPercentage(attempt.percentage);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 40,
                      width: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: grade.colour.withValues(alpha: 0.12),
                        borderRadius: AppRadii.sm,
                      ),
                      child: Text(
                        grade.label,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: grade.colour,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            subject.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '${attempt.label} · '
                            '${attempt.mode == PracticeMode.study ? 'Study' : 'Exam'} '
                            '· ${DateFormat('d MMM, HH:mm').format(attempt.takenAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${attempt.correct}/${attempt.total}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () async {
              final bool? clear = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Clear history?'),
                  content: const Text(
                    'This removes every recorded attempt. Your bookmarks and '
                    'profile stay as they are.',
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
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (clear == true && context.mounted) {
                await AppScope.read(context).clearHistory();
              }
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Clear history'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColours.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadlineTile extends StatelessWidget {
  const _HeadlineTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.colour,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: colour, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: text.headlineSmall?.copyWith(color: colour)),
          Text(label, style: text.bodySmall),
        ],
      ),
    );
  }
}

/// A small bar chart of the most recent scores — enough to show a trend
/// without pulling in a charting package.
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.attempts});

  final List<AttemptRecord> attempts;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: attempts.map((AttemptRecord attempt) {
        final Grade grade = Grade.forPercentage(attempt.percentage);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${attempt.percentage.toStringAsFixed(0)}%',
                  style: text.labelSmall?.copyWith(color: grade.colour),
                ),
                const SizedBox(height: 4),
                Container(
                  height: (attempt.percentage / 100 * 74).clamp(6, 74),
                  decoration: BoxDecoration(
                    color: grade.colour,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Subjects.byId(attempt.subjectId).shortName,
                  style: text.labelSmall?.copyWith(
                    color: AppColours.textFaint,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

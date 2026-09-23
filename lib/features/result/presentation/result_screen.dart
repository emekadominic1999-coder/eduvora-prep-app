import 'package:flutter/material.dart';

import '../../../core/data/subjects.dart';
import '../../../core/models/exam.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import 'review_screen.dart';

/// The score sheet shown immediately after a paper is submitted.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.attempt,
    required this.questions,
    required this.answers,
    this.autoSubmitted = false,
  });

  final AttemptRecord attempt;
  final List<Question> questions;
  final Map<int, int> answers;
  final bool autoSubmitted;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Subject subject = Subjects.byId(attempt.subjectId);
    final Grade grade = Grade.forPercentage(attempt.percentage);
    final int wrong = attempt.total - attempt.correct - _skipped;
    final AppState state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Your result'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: <Widget>[
          if (autoSubmitted)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: AppCard(
                colour: AppColours.warningSoft,
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.timer_off_rounded,
                      color: AppColours.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Time ran out, so the paper was submitted '
                        'automatically — exactly as it would be in the hall.',
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: AppColours.brandGradient,
              borderRadius: AppRadii.xl,
              boxShadow: AppShadows.raised,
            ),
            child: Column(
              children: <Widget>[
                Text(
                  subject.name,
                  style: text.titleSmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  attempt.label,
                  style: text.bodySmall?.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '${attempt.correct}/${attempt.total}',
                  style: text.displayLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: AppRadii.pill,
                  ),
                  child: Text(
                    '${attempt.percentage.toStringAsFixed(0)}%  ·  '
                    '${grade.label}  ·  ${grade.remark}',
                    style: text.labelMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  label: 'Correct',
                  value: '${attempt.correct}',
                  colour: AppColours.success,
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatTile(
                  label: 'Wrong',
                  value: '$wrong',
                  colour: AppColours.danger,
                  icon: Icons.cancel_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatTile(
                  label: 'Skipped',
                  value: '$_skipped',
                  colour: AppColours.textMuted,
                  icon: Icons.remove_circle_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Row(
              children: <Widget>[
                const Icon(Icons.schedule_rounded, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text('Time used', style: text.bodyMedium),
                ),
                Text(
                  formatDuration(attempt.secondsUsed),
                  style: text.titleSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (attempt.topicScores.isNotEmpty) ...<Widget>[
            const SectionHeader(
              title: 'Topic breakdown',
              subtitle: 'Where the marks came from, and where they went.',
            ),
            AppCard(
              child: Column(
                children: _sortedTopics.map((MapEntry<String, List<int>> e) {
                  final double pct = (e.value[0] / e.value[1]) * 100;
                  return MeterRow(
                    label: e.key,
                    value: pct,
                    colour: pct >= 60
                        ? AppColours.success
                        : pct >= 40
                            ? AppColours.warning
                            : AppColours.danger,
                    trailing: '${e.value[0]}/${e.value[1]}',
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          AppCard(
            colour: AppColours.primaryTint,
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColours.accent,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    state.streak <= 1
                        ? 'Practice streak started. Come back tomorrow to '
                            'keep it alive.'
                        : '${state.streak}-day practice streak. Keep going.',
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReviewScreen(
                  questions: questions,
                  answers: answers,
                  subjectName: subject.name,
                ),
              ),
            ),
            icon: const Icon(Icons.fact_check_rounded),
            label: const Text('Review answers and explanations'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            icon: const Icon(Icons.home_rounded, size: 18),
            label: const Text('Back to dashboard'),
          ),
        ],
      ),
    );
  }

  int get _skipped => attempt.total - answers.length;

  List<MapEntry<String, List<int>>> get _sortedTopics {
    final List<MapEntry<String, List<int>>> entries =
        attempt.topicScores.entries.toList();
    entries.sort((MapEntry<String, List<int>> a,
        MapEntry<String, List<int>> b) {
      final double aPct = a.value[0] / a.value[1];
      final double bPct = b.value[0] / b.value[1];
      return aPct.compareTo(bPct);
    });
    return entries;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.colour,
    required this.icon,
  });

  final String label;
  final String value;
  final Color colour;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
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

import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/models/exam.dart';
import '../../../core/services/question_bank.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../exam/presentation/exam_setup_sheet.dart';

/// Every paper Eduvora Prep holds for one subject under one exam body,
/// plus a mixed drill that pulls across all the years at once.
class SubjectPapersScreen extends StatelessWidget {
  const SubjectPapersScreen({
    super.key,
    required this.subject,
    required this.body,
  });

  final Subject subject;
  final ExamBody body;

  @override
  Widget build(BuildContext context) {
    final QuestionBank bank = QuestionBank.instance;
    final List<PastPaper> papers = bank.forSubjectAndBody(subject.id, body);
    final TextTheme text = Theme.of(context).textTheme;
    final AppState state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: <Widget>[
          AppCard(
            colour: subject.colour.withValues(alpha: 0.08),
            border: Border.all(color: subject.colour.withValues(alpha: 0.22)),
            child: Row(
              children: <Widget>[
                Icon(subject.icon, color: subject.colour, size: 26),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('${body.name} · ${subject.name}',
                          style: text.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        '${papers.length} '
                        '${papers.length == 1 ? 'paper' : 'papers'} · '
                        '${papers.fold<int>(0, (int s, PastPaper p) => s + p.questionCount)} '
                        'questions with worked explanations',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (papers.length > 1) ...<Widget>[
            AppCard(
              onTap: () => _startMixedDrill(context, papers),
              border: Border.all(color: AppColours.accent, width: 1.4),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 44,
                    width: 44,
                    decoration: const BoxDecoration(
                      gradient: AppColours.accentGradient,
                      borderRadius: AppRadii.md,
                    ),
                    child: const Icon(
                      Icons.shuffle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Mixed drill', style: text.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          'Questions pulled at random across every year.',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          const SectionHeader(title: 'Papers by year'),
          ...papers.map((PastPaper paper) {
            final AttemptRecord? best = _bestAttempt(state, paper.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                onTap: () => startPaper(context, paper),
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 50,
                      width: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: body.colour.withValues(alpha: 0.10),
                        borderRadius: AppRadii.md,
                      ),
                      child: Text(
                        '${paper.year}'.substring(2),
                        style: text.titleMedium?.copyWith(
                          color: body.colour,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(paper.title, style: text.titleSmall),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: 4,
                            children: <Widget>[
                              Pill(
                                '${paper.questionCount} questions',
                                colour: AppColours.textMuted,
                              ),
                              Pill(
                                '${paper.durationMinutes} min',
                                colour: AppColours.textMuted,
                                icon: Icons.timer_outlined,
                              ),
                              if (best != null)
                                Pill(
                                  'Best ${best.percentage.toStringAsFixed(0)}%',
                                  colour: AppColours.success,
                                  icon: Icons.emoji_events_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.play_circle_fill_rounded,
                        color: AppColours.primary, size: 30),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  AttemptRecord? _bestAttempt(AppState state, String paperId) {
    final List<AttemptRecord> matching = state.attempts
        .where((AttemptRecord a) => a.paperId == paperId)
        .toList();
    if (matching.isEmpty) return null;
    matching.sort((AttemptRecord a, AttemptRecord b) =>
        b.percentage.compareTo(a.percentage));
    return matching.first;
  }

  void _startMixedDrill(BuildContext context, List<PastPaper> papers) {
    final List<Question> pool = <Question>[
      for (final PastPaper paper in papers) ...paper.questions,
    ]..shuffle(Random());

    final int count = min(40, pool.length);
    final PastPaper drill = PastPaper(
      id: '${body.code.toLowerCase()}-${subject.id}-mixed',
      body: body,
      subjectId: subject.id,
      year: DateTime.now().year,
      diet: 'Mixed drill',
      synthetic: true,
      durationMinutes: (count * 0.75).ceil().clamp(5, 120),
      questions: pool.take(count).toList(),
    );
    startPaper(context, drill);
  }
}

import 'package:flutter/material.dart';

import '../../../core/models/exam.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';

/// Question-by-question review with the correct answer and the reasoning.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.subjectName,
  });

  final List<Question> questions;
  final Map<int, int> answers;
  final String subjectName;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

enum _Filter { all, wrong, skipped }

class _ReviewScreenState extends State<ReviewScreen> {
  _Filter _filter = _Filter.all;

  List<int> get _visible {
    final List<int> indices = <int>[];
    for (int i = 0; i < widget.questions.length; i++) {
      final int? given = widget.answers[i];
      switch (_filter) {
        case _Filter.all:
          indices.add(i);
        case _Filter.wrong:
          if (given != null && given != widget.questions[i].answerIndex) {
            indices.add(i);
          }
        case _Filter.skipped:
          if (given == null) indices.add(i);
      }
    }
    return indices;
  }

  @override
  Widget build(BuildContext context) {
    final List<int> visible = _visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                _FilterChip(
                  label: 'All',
                  selected: _filter == _Filter.all,
                  onTap: () => setState(() => _filter = _Filter.all),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Got wrong',
                  selected: _filter == _Filter.wrong,
                  onTap: () => setState(() => _filter = _Filter.wrong),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Skipped',
                  selected: _filter == _Filter.skipped,
                  onTap: () => setState(() => _filter = _Filter.skipped),
                ),
              ],
            ),
          ),
        ),
      ),
      body: visible.isEmpty
          ? EmptyState(
              icon: Icons.celebration_rounded,
              title: _filter == _Filter.wrong
                  ? 'Nothing wrong here'
                  : 'Nothing skipped',
              message: _filter == _Filter.wrong
                  ? 'You did not miss a single question in this filter.'
                  : 'You attempted every question in this paper.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: visible.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int i) {
                final int index = visible[i];
                return _ReviewCard(
                  number: index + 1,
                  question: widget.questions[index],
                  given: widget.answers[index],
                );
              },
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.number,
    required this.question,
    required this.given,
  });

  final int number;
  final Question question;
  final int? given;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppState state = AppScope.of(context);
    final bool correct = given == question.answerIndex;
    final bool skipped = given == null;

    final Color statusColour = skipped
        ? AppColours.textMuted
        : correct
            ? AppColours.success
            : AppColours.danger;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Pill('Q$number', colour: AppColours.primary),
              const SizedBox(width: AppSpacing.sm),
              Pill(
                skipped
                    ? 'Skipped'
                    : correct
                        ? 'Correct'
                        : 'Wrong',
                colour: statusColour,
              ),
              const Spacer(),
              InkWell(
                borderRadius: AppRadii.pill,
                onTap: () => state.toggleBookmark(question.id),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    state.isBookmarked(question.id)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 20,
                    color: state.isBookmarked(question.id)
                        ? AppColours.primary
                        : AppColours.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (question.instruction.isNotEmpty) ...<Widget>[
            Text(
              question.instruction,
              style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6),
          ],
          Text(question.text, style: text.titleSmall?.copyWith(height: 1.4)),
          const SizedBox(height: AppSpacing.md),
          ...List<Widget>.generate(question.options.length, (int i) {
            final bool isAnswer = i == question.answerIndex;
            final bool isGiven = i == given;
            if (!isAnswer && !isGiven) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${Question.letterFor(i)}.  ',
                      style: text.bodySmall,
                    ),
                    Expanded(
                      child: Text(question.options[i], style: text.bodySmall),
                    ),
                  ],
                ),
              );
            }
            final Color colour =
                isAnswer ? AppColours.success : AppColours.danger;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.08),
                  borderRadius: AppRadii.sm,
                  border: Border.all(color: colour.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      isAnswer
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 16,
                      color: colour,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${Question.letterFor(i)}.  '
                        '${question.options[i]}',
                        style: text.bodySmall?.copyWith(
                          color: AppColours.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isGiven && !isAnswer)
                      Text(
                        'your answer',
                        style: text.labelSmall?.copyWith(color: colour),
                      ),
                  ],
                ),
              ),
            );
          }),
          if (question.explanation.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColours.infoSoft,
                borderRadius: AppRadii.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.lightbulb_rounded,
                    size: 16,
                    color: AppColours.info,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(question.explanation, style: text.bodySmall),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Pill(question.topic, colour: AppColours.textMuted),
          ),
        ],
      ),
    );
  }
}

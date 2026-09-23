import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/data/subjects.dart';
import '../../../core/models/exam.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../exam/presentation/exam_setup_sheet.dart';
import '../../home/home_shell.dart';

/// Every question the student has saved, with the answer and the reasoning,
/// and a one-tap drill built from them.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<Question> saved = state.bookmarkedQuestions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved questions'),
        actions: <Widget>[
          if (saved.length >= 4)
            IconButton(
              tooltip: 'Drill saved questions',
              onPressed: () => _drill(context, saved),
              icon: const Icon(Icons.play_circle_outline_rounded),
            ),
        ],
      ),
      body: saved.isEmpty
          ? EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'Nothing saved yet',
              message:
                  'Tap the bookmark icon on any question to keep it here for '
                  'later revision.',
              actionLabel: 'Find questions',
              onAction: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const HomeShell(initialIndex: 1),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: saved.length + 1,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      colour: AppColours.primaryTint,
                      onTap: saved.length >= 4
                          ? () => _drill(context, saved)
                          : null,
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.playlist_add_check_rounded,
                            color: AppColours.primary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              saved.length >= 4
                                  ? '${saved.length} saved. Tap to drill them '
                                      'as a paper.'
                                  : '${saved.length} saved. Save four or more '
                                      'to drill them as a paper.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _SavedCard(question: saved[i - 1]);
              },
            ),
    );
  }

  void _drill(BuildContext context, List<Question> saved) {
    final List<Question> pool = List<Question>.from(saved)..shuffle(Random());
    final int count = min(40, pool.length);
    startPaper(
      context,
      PastPaper(
        id: 'saved-drill',
        body: ExamBody.jamb,
        subjectId: Subjects.mixed.id,
        year: DateTime.now().year,
        diet: 'Saved questions',
        synthetic: true,
        durationMinutes: (count * 0.75).ceil().clamp(5, 60),
        questions: pool.take(count).toList(),
      ),
    );
  }
}

class _SavedCard extends StatefulWidget {
  const _SavedCard({required this.question});

  final Question question;

  @override
  State<_SavedCard> createState() => _SavedCardState();
}

class _SavedCardState extends State<_SavedCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Question question = widget.question;
    final AppState state = AppScope.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Pill(question.topic, colour: AppColours.primary),
              const Spacer(),
              InkWell(
                borderRadius: AppRadii.pill,
                onTap: () => state.toggleBookmark(question.id),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.bookmark_remove_rounded,
                    size: 20,
                    color: AppColours.textMuted,
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
            final bool isAnswer = _revealed && i == question.answerIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${Question.letterFor(i)}.  ',
                    style: text.bodySmall?.copyWith(
                      fontWeight:
                          isAnswer ? FontWeight.w800 : FontWeight.w400,
                      color:
                          isAnswer ? AppColours.success : AppColours.textMuted,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      question.options[i],
                      style: text.bodySmall?.copyWith(
                        color: isAnswer ? AppColours.success : AppColours.text,
                        fontWeight:
                            isAnswer ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.sm),
          if (!_revealed)
            TextButton.icon(
              onPressed: () => setState(() => _revealed = true),
              icon: const Icon(Icons.visibility_rounded, size: 17),
              label: const Text('Show answer'),
            )
          else if (question.explanation.isNotEmpty)
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
      ),
    );
  }
}

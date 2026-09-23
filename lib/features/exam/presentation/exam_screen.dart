import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/data/subjects.dart';
import '../../../core/models/exam.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../result/presentation/result_screen.dart';

/// The CBT hall. In exam mode a countdown runs and answers stay hidden until
/// submission; in study mode the answer and explanation open immediately.
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.config});

  final ExamConfig config;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  late final List<Question> _questions;
  late final DateTime _startedAt;
  final Map<int, int> _answers = <int, int>{};
  final Set<int> _flagged = <int>{};
  final PageController _pages = PageController();

  Timer? _ticker;
  int _remaining = 0;
  int _elapsed = 0;
  int _index = 0;
  bool _submitting = false;

  bool get _isExamMode => widget.config.mode == PracticeMode.exam;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();

    final List<Question> pool =
        List<Question>.from(widget.config.paper.questions);
    if (widget.config.shuffleQuestions) {
      pool.shuffle(Random());
    }
    _questions = pool.take(widget.config.questionCount).toList();

    _remaining = widget.config.durationMinutes * 60;
    _ticker = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    if (!mounted) return;
    setState(() {
      _elapsed += 1;
      if (_isExamMode) {
        _remaining -= 1;
      }
    });
    if (_isExamMode && _remaining <= 0) {
      timer.cancel();
      _submit(autoSubmitted: true);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() => _index = index);
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _choose(int questionIndex, int optionIndex) {
    setState(() => _answers[questionIndex] = optionIndex);
  }

  Future<void> _submit({bool autoSubmitted = false}) async {
    if (_submitting) return;

    if (!autoSubmitted) {
      final int unanswered = _questions.length - _answers.length;
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Submit this paper?'),
          content: Text(
            unanswered == 0
                ? 'You have answered every question. Submit now?'
                : 'You still have $unanswered unanswered '
                    '${unanswered == 1 ? 'question' : 'questions'}. '
                    'Submit anyway?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep working'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    _submitting = true;
    _ticker?.cancel();

    int correct = 0;
    final Map<String, List<int>> topics = <String, List<int>>{};
    for (int i = 0; i < _questions.length; i++) {
      final Question question = _questions[i];
      final List<int> tally =
          topics.putIfAbsent(question.topic, () => <int>[0, 0]);
      tally[1] += 1;
      if (_answers[i] == question.answerIndex) {
        correct += 1;
        tally[0] += 1;
      }
    }

    final PastPaper paper = widget.config.paper;
    final AttemptRecord attempt = AttemptRecord(
      id: '${paper.id}-${_startedAt.millisecondsSinceEpoch}',
      paperId: paper.id,
      bodyCode: paper.body.code,
      subjectId: paper.subjectId,
      year: paper.year,
      label: paper.title,
      mode: widget.config.mode,
      correct: correct,
      total: _questions.length,
      secondsUsed: _elapsed,
      takenAt: _startedAt,
      topicScores: topics,
    );

    if (!mounted) return;
    await AppScope.read(context).recordAttempt(attempt);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          attempt: attempt,
          questions: _questions,
          answers: Map<int, int>.from(_answers),
          autoSubmitted: autoSubmitted,
        ),
      ),
    );
  }

  Future<bool> _confirmExit() async {
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Leave this paper?'),
        content: const Text(
          'Your answers for this session will not be saved.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColours.danger,
              minimumSize: const Size(110, 44),
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final Subject subject = Subjects.byId(widget.config.paper.subjectId);
    final bool lowTime = _isExamMode && _remaining <= 60;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (await _confirmExit() && mounted) {
          if (!context.mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              if (await _confirmExit() && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(subject.name, style: Theme.of(context).textTheme.titleSmall),
              Text(
                widget.config.paper.title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: lowTime
                    ? AppColours.dangerSoft
                    : AppColours.primaryTint,
                borderRadius: AppRadii.pill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    _isExamMode ? Icons.timer_rounded : Icons.schedule_rounded,
                    size: 15,
                    color: lowTime ? AppColours.danger : AppColours.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatDuration(_isExamMode ? _remaining : _elapsed),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color:
                              lowTime ? AppColours.danger : AppColours.primary,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_index + 1) / _questions.length,
              minHeight: 4,
              backgroundColor: AppColours.border,
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _pages,
                onPageChanged: (int i) => setState(() => _index = i),
                itemCount: _questions.length,
                itemBuilder: (BuildContext context, int i) {
                  return _QuestionView(
                    question: _questions[i],
                    number: i + 1,
                    total: _questions.length,
                    selected: _answers[i],
                    revealAnswer: !_isExamMode && _answers.containsKey(i),
                    flagged: _flagged.contains(i),
                    onSelect: (int option) => _choose(i, option),
                    onToggleFlag: () => setState(() {
                      if (!_flagged.remove(i)) _flagged.add(i);
                    }),
                  );
                },
              ),
            ),
            _BottomBar(
              index: _index,
              total: _questions.length,
              answered: _answers.length,
              onPrevious: _index == 0 ? null : () => _goTo(_index - 1),
              onNext: _index == _questions.length - 1
                  ? null
                  : () => _goTo(_index + 1),
              onPalette: _openPalette,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }

  void _openPalette() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: <Widget>[
                Text(
                  'Question palette',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: const <Widget>[
                    _LegendDot(colour: AppColours.success, label: 'Answered'),
                    _LegendDot(colour: AppColours.accent, label: 'Flagged'),
                    _LegendDot(
                      colour: AppColours.borderStrong,
                      label: 'Not answered',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children:
                      List<Widget>.generate(_questions.length, (int i) {
                    final bool answered = _answers.containsKey(i);
                    final bool flagged = _flagged.contains(i);
                    final bool current = i == _index;
                    final Color colour = flagged
                        ? AppColours.accent
                        : answered
                            ? AppColours.success
                            : AppColours.surfaceMuted;
                    return InkWell(
                      borderRadius: AppRadii.sm,
                      onTap: () {
                        Navigator.pop(context);
                        _goTo(i);
                      },
                      child: Container(
                        height: 42,
                        width: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colour,
                          borderRadius: AppRadii.sm,
                          border: Border.all(
                            color: current
                                ? AppColours.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: answered || flagged
                                    ? Colors.white
                                    : AppColours.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.colour, required this.label});

  final Color colour;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 11,
          width: 11,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.question,
    required this.number,
    required this.total,
    required this.selected,
    required this.revealAnswer,
    required this.flagged,
    required this.onSelect,
    required this.onToggleFlag,
  });

  final Question question;
  final int number;
  final int total;
  final int? selected;
  final bool revealAnswer;
  final bool flagged;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggleFlag;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppState state = AppScope.of(context);
    final bool saved = state.isBookmarked(question.id);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: <Widget>[
        Row(
          children: <Widget>[
            Pill('Question $number of $total'),
            const Spacer(),
            IconButton(
              tooltip: saved ? 'Remove bookmark' : 'Bookmark question',
              onPressed: () => state.toggleBookmark(question.id),
              icon: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: saved ? AppColours.primary : AppColours.textMuted,
              ),
            ),
            IconButton(
              tooltip: flagged ? 'Unflag' : 'Flag for review',
              onPressed: onToggleFlag,
              icon: Icon(
                flagged ? Icons.flag_rounded : Icons.outlined_flag_rounded,
                color: flagged ? AppColours.accent : AppColours.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (question.passage.isNotEmpty) ...<Widget>[
          AppCard(
            colour: AppColours.surfaceMuted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'PASSAGE',
                  style: text.labelSmall?.copyWith(
                    color: AppColours.textFaint,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(question.passage, style: text.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (question.instruction.isNotEmpty) ...<Widget>[
          Text(
            question.instruction,
            style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(question.text, style: text.titleMedium?.copyWith(height: 1.45)),
        const SizedBox(height: AppSpacing.lg),
        ...List<Widget>.generate(question.options.length, (int i) {
          return _OptionTile(
            letter: Question.letterFor(i),
            label: question.options[i],
            selected: selected == i,
            isCorrect: revealAnswer && i == question.answerIndex,
            isWrong: revealAnswer && selected == i && i != question.answerIndex,
            onTap: revealAnswer ? null : () => onSelect(i),
          );
        }),
        if (revealAnswer && question.explanation.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            colour: AppColours.infoSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.lightbulb_rounded,
                  color: AppColours.info,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Why', style: text.labelMedium),
                      const SizedBox(height: 4),
                      Text(question.explanation, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.label,
    required this.selected,
    required this.isCorrect,
    required this.isWrong,
    this.onTap,
  });

  final String letter;
  final String label;
  final bool selected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color border = AppColours.border;
    Color background = AppColours.surface;
    Color badge = AppColours.surfaceMuted;
    Color badgeText = AppColours.textMuted;

    if (isCorrect) {
      border = AppColours.success;
      background = AppColours.successSoft;
      badge = AppColours.success;
      badgeText = Colors.white;
    } else if (isWrong) {
      border = AppColours.danger;
      background = AppColours.dangerSoft;
      badge = AppColours.danger;
      badgeText = Colors.white;
    } else if (selected) {
      border = AppColours.primary;
      background = AppColours.primaryTint;
      badge = AppColours.primary;
      badgeText = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.md,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadii.md,
              border: Border.all(
                color: border,
                width: selected || isCorrect || isWrong ? 1.7 : 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 30,
                  width: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badge,
                    borderRadius: AppRadii.sm,
                  ),
                  child: Text(
                    letter,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: badgeText,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                if (isCorrect)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColours.success,
                    size: 20,
                  ),
                if (isWrong)
                  const Icon(
                    Icons.cancel_rounded,
                    color: AppColours.danger,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.total,
    required this.answered,
    required this.onPrevious,
    required this.onNext,
    required this.onPalette,
    required this.onSubmit,
  });

  final int index;
  final int total;
  final int answered;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPalette;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bool onLast = index == total - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColours.surface,
        border: Border(top: BorderSide(color: AppColours.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColours.surfaceMuted,
                minimumSize: const Size(48, 48),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPalette,
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: Text('$answered/$total answered'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (onLast)
              FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(104, 48),
                  backgroundColor: AppColours.success,
                ),
                child: const Text('Submit'),
              )
            else
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(104, 48),
                ),
                child: const Text('Next'),
              ),
          ],
        ),
      ),
    );
  }
}

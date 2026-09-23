import 'package:flutter/material.dart';

import '../../../core/data/subjects.dart';
import '../../../core/models/exam.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import 'exam_screen.dart';

/// Opens the setup sheet for [paper] and, if the student starts, pushes the
/// exam screen. Used from every entry point that begins a session.
Future<void> startPaper(BuildContext context, PastPaper paper) async {
  final ExamConfig? config = await showModalBottomSheet<ExamConfig>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => _ExamSetupSheet(paper: paper),
  );
  if (config == null || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ExamScreen(config: config)),
  );
}

class _ExamSetupSheet extends StatefulWidget {
  const _ExamSetupSheet({required this.paper});

  final PastPaper paper;

  @override
  State<_ExamSetupSheet> createState() => _ExamSetupSheetState();
}

class _ExamSetupSheetState extends State<_ExamSetupSheet> {
  PracticeMode _mode = PracticeMode.exam;
  late int _count = widget.paper.questionCount;
  late int _minutes = widget.paper.durationMinutes;
  bool _shuffle = true;

  List<int> get _countChoices {
    final int max = widget.paper.questionCount;
    final List<int> choices = <int>[10, 20, 30, 40, 60]
        .where((int value) => value < max)
        .toList()
      ..add(max);
    return choices;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Subject subject = Subjects.byId(widget.paper.subjectId);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: subject.colour.withValues(alpha: 0.12),
                    borderRadius: AppRadii.md,
                  ),
                  child: Icon(subject.icon, color: subject.colour),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(subject.name, style: text.titleMedium),
                      Text(widget.paper.title, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('How do you want to practise?', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            ...PracticeMode.values.map((PracticeMode mode) {
              final bool selected = mode == _mode;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  onTap: () => setState(() => _mode = mode),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  border: Border.all(
                    color: selected ? AppColours.primary : AppColours.border,
                    width: selected ? 1.7 : 1,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        mode.icon,
                        color: selected
                            ? AppColours.primary
                            : AppColours.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(mode.label, style: text.titleSmall),
                            Text(mode.blurb, style: text.bodySmall),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColours.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),
            Text('Number of questions', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: _countChoices.map((int value) {
                return ChoiceChip(
                  label: Text('$value'),
                  selected: _count == value,
                  onSelected: (_) => setState(() => _count = value),
                );
              }).toList(),
            ),
            if (_mode == PracticeMode.exam) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('Time limit', style: text.titleSmall),
                  ),
                  Pill('$_minutes min', icon: Icons.timer_rounded),
                ],
              ),
              Slider(
                value: _minutes.toDouble().clamp(5, 180),
                min: 5,
                max: 180,
                divisions: 35,
                label: '$_minutes min',
                onChanged: (double value) =>
                    setState(() => _minutes = value.round()),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile.adaptive(
              value: _shuffle,
              onChanged: (bool value) => setState(() => _shuffle = value),
              contentPadding: EdgeInsets.zero,
              title: Text('Shuffle questions', style: text.titleSmall),
              subtitle: Text(
                'Mix the order so you learn the content, not the position.',
                style: text.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => Navigator.pop(
                context,
                ExamConfig(
                  paper: widget.paper,
                  mode: _mode,
                  questionCount: _count,
                  durationMinutes: _minutes,
                  shuffleQuestions: _shuffle,
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                _mode == PracticeMode.exam ? 'Start exam' : 'Start studying',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

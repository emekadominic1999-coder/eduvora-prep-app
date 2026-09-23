import 'package:flutter/material.dart';

import '../../../core/models/exam.dart';
import '../../../core/services/question_bank.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import 'subject_papers_screen.dart';

/// Browse the whole archive: pick an exam body, then a subject.
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ExamBody> bodies = ExamBody.values
        .where((ExamBody body) => QuestionBank.instance.forBody(body).isNotEmpty)
        .toList();

    return DefaultTabController(
      length: bodies.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Past questions'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: bodies
                .map((ExamBody body) => Tab(text: body.code))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: bodies.map((ExamBody body) => _BodyTab(body: body)).toList(),
        ),
      ),
    );
  }
}

class _BodyTab extends StatelessWidget {
  const _BodyTab({required this.body});

  final ExamBody body;

  @override
  Widget build(BuildContext context) {
    final QuestionBank bank = QuestionBank.instance;
    final List<Subject> subjects = bank.subjectsFor(body);
    final TextTheme text = Theme.of(context).textTheme;

    if (subjects.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_rounded,
        title: 'Nothing here yet',
        message: 'Papers for this body are being added.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: body.colour.withValues(alpha: 0.08),
            borderRadius: AppRadii.lg,
            border: Border.all(color: body.colour.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: <Widget>[
              Icon(body.icon, color: body.colour, size: 26),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(body.longName, style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(body.blurb, style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: '${subjects.length} subjects available',
          subtitle: 'Tap a subject to see the papers year by year.',
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjects.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (BuildContext context, int i) {
            final Subject subject = subjects[i];
            final List<PastPaper> papers =
                bank.forSubjectAndBody(subject.id, body);
            final int questions = papers.fold<int>(
              0,
              (int sum, PastPaper p) => sum + p.questionCount,
            );
            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      SubjectPapersScreen(subject: subject, body: body),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: subject.colour.withValues(alpha: 0.12),
                      borderRadius: AppRadii.sm,
                    ),
                    child: Icon(subject.icon, color: subject.colour, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    subject.name,
                    style: text.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${papers.length} '
                    '${papers.length == 1 ? 'paper' : 'papers'} · '
                    '$questions questions',
                    style: text.bodySmall,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

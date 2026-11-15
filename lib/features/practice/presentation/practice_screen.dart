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

    // The bank can legitimately be empty — e.g. while real past questions
    // are being added back in. A TabController needs at least one tab, so
    // guard this rather than build one with zero tabs.
    if (bodies.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Past questions')),
        body: const EmptyState(
          icon: Icons.inbox_rounded,
          title: 'No papers yet',
          message: 'Past questions are being added. Check back soon.',
        ),
      );
    }

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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (BuildContext context, int i) {
            final Subject subject = subjects[i];
            final List<PastPaper> papers =
                bank.forSubjectAndBody(subject.id, body);
            final int questions = papers.fold<int>(
              0,
              (int sum, PastPaper p) => sum + p.questionCount,
            );
            return _SubjectCard(
              subject: subject,
              papers: papers.length,
              questions: questions,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      SubjectPapersScreen(subject: subject, body: body),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A full-bleed pastel subject card — title first, a solid-colour icon
/// badge below it, then the paper/question count — matching the big
/// tappable card style used throughout myschool.ng's own Study and Test
/// tabs, adapted here to carry the extra detail those don't need to show.
class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.papers,
    required this.questions,
    required this.onTap,
  });

  final Subject subject;
  final int papers;
  final int questions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: subject.colour.withValues(alpha: 0.14),
      borderRadius: AppRadii.lg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                subject.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  color: AppColours.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: subject.colour,
                  shape: BoxShape.circle,
                ),
                child: Icon(subject.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                papers == 0
                    ? 'Coming soon'
                    : '$papers ${papers == 1 ? 'paper' : 'papers'} · '
                        '$questions questions',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(
                  color: subject.colour,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

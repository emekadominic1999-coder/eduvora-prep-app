import 'package:flutter/material.dart';

import '../../../core/data/subjects.dart';
import '../../../core/models/exam.dart' show Subject;
import '../../../core/models/video_lesson.dart';
import '../../../core/services/video_lesson_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../marketplace/presentation/marketplace_screen.dart' show nairaFormat;

/// The video-lesson catalogue. No payment is wired up yet, so "Buy" is
/// honest about that rather than pretending to charge a card.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final VideoLessonRepository _repo = const VideoLessonRepository();
  late Future<List<VideoLesson>> _future;

  @override
  void initState() {
    super.initState();
    // FutureBuilder requires the future to be created in initState (or
    // earlier), never lazily during build — see its own documentation.
    _future = _repo.fetchAll()..ignore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Lessons')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _repo.fetchAll()),
        child: FutureBuilder<List<VideoLesson>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<VideoLesson>> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load this',
                message: 'Check your connection and try again.',
                actionLabel: 'Retry',
                onAction: () => setState(() => _future = _repo.fetchAll()),
              );
            }
            final List<VideoLesson> items = snap.data ?? const <VideoLesson>[];
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.ondemand_video_rounded,
                title: 'No video lessons yet',
                message: 'Topic-by-topic video lessons will appear here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int i) =>
                  _LessonCard(lesson: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson});

  final VideoLesson lesson;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool hasSubject = lesson.subjectId.isNotEmpty &&
        Subjects.all.any((Subject s) => s.id == lesson.subjectId);
    final Subject? subject =
        hasSubject ? Subjects.byId(lesson.subjectId) : null;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: (subject?.colour ?? AppColours.primary)
                  .withValues(alpha: 0.12),
              borderRadius: AppRadii.md,
            ),
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: subject?.colour ?? AppColours.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(lesson.title, style: text.titleSmall),
                const SizedBox(height: 4),
                Text(lesson.description, style: text.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Text(
                      nairaFormat.format(lesson.priceNaira),
                      style: text.titleSmall?.copyWith(
                        color: AppColours.primary,
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => _buy(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(80, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: Text(lesson.isUnlocked ? 'Watch' : 'Buy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _buy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Payments coming soon'),
        content: const Text(
          'Buying video lessons is not live yet — we have not connected a '
          'payment provider. Check back soon.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

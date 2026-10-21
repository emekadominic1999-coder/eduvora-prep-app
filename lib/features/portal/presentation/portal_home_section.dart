import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../forum/presentation/forum_screen.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../news/presentation/news_screen.dart';
import '../../scholarships/presentation/scholarships_screen.dart';
import '../../store/presentation/store_screen.dart';

/// The myschool.ng-style portal hub: a horizontal row of bold, pastel-tinted
/// cards — one colour per card, matching the "Take a test" / feature-card
/// row on myschool.ng's own home feed — each pushing its own full screen.
class PortalHomeSection extends StatelessWidget {
  const PortalHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_PortalEntry> entries = <_PortalEntry>[
      _PortalEntry(
        label: 'Exam News',
        caption: 'Results, admissions and timetables',
        icon: Icons.newspaper_rounded,
        builder: (_) => const NewsScreen(),
      ),
      _PortalEntry(
        label: 'Scholarships',
        caption: 'Opportunities for students',
        icon: Icons.school_rounded,
        builder: (_) => const ScholarshipsScreen(),
      ),
      _PortalEntry(
        label: 'Forum',
        caption: 'Ask and answer questions',
        icon: Icons.forum_rounded,
        builder: (_) => const ForumScreen(),
      ),
      _PortalEntry(
        label: 'Marketplace',
        caption: 'Buy and sell with students',
        icon: Icons.storefront_rounded,
        builder: (_) => const MarketplaceScreen(),
      ),
      _PortalEntry(
        label: 'Video Lessons',
        caption: 'Topic-by-topic teaching',
        icon: Icons.ondemand_video_rounded,
        builder: (_) => const StoreScreen(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(
          title: 'Explore the portal',
          subtitle: 'Everything beyond past questions.',
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (BuildContext context, int i) {
              final _PortalEntry entry = entries[i];
              final Color tint =
                  AppColours.cardTints[i % AppColours.cardTints.length];
              final Color fg = AppColours.cardTintForegrounds[
                  i % AppColours.cardTintForegrounds.length];
              return _PortalCard(entry: entry, tint: tint, foreground: fg);
            },
          ),
        ),
      ],
    );
  }
}

class _PortalCard extends StatelessWidget {
  const _PortalCard({
    required this.entry,
    required this.tint,
    required this.foreground,
  });

  final _PortalEntry entry;
  final Color tint;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Material(
        color: tint,
        borderRadius: AppRadii.lg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: entry.builder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: foreground,
                    borderRadius: AppRadii.md,
                  ),
                  child: Icon(entry.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  entry.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  entry.caption,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: 0.82),
                        height: 1.25,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortalEntry {
  const _PortalEntry({
    required this.label,
    required this.caption,
    required this.icon,
    required this.builder,
  });

  final String label;
  final String caption;
  final IconData icon;
  final WidgetBuilder builder;
}

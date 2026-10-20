import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../forum/presentation/forum_screen.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../news/presentation/news_screen.dart';
import '../../scholarships/presentation/scholarships_screen.dart';
import '../../store/presentation/store_screen.dart';

/// The myschool.ng-style portal hub: short entry cards for everything beyond
/// CBT practice — news, scholarships, forum, marketplace and the video
/// store — each pushing its own full screen.
class PortalHomeSection extends StatelessWidget {
  const PortalHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_PortalEntry> entries = <_PortalEntry>[
      _PortalEntry(
        label: 'Exam News',
        caption: 'Results, admissions, timetables',
        icon: Icons.newspaper_rounded,
        colour: AppColours.info,
        builder: (_) => const NewsScreen(),
      ),
      _PortalEntry(
        label: 'Scholarships',
        caption: 'Opportunities for students',
        icon: Icons.school_rounded,
        colour: const Color(0xFF7C3AED),
        builder: (_) => const ScholarshipsScreen(),
      ),
      _PortalEntry(
        label: 'Forum',
        caption: 'Ask and answer questions',
        icon: Icons.forum_rounded,
        colour: AppColours.success,
        builder: (_) => const ForumScreen(),
      ),
      _PortalEntry(
        label: 'Marketplace',
        caption: 'Buy and sell with students',
        icon: Icons.storefront_rounded,
        colour: AppColours.accent,
        builder: (_) => const MarketplaceScreen(),
      ),
      _PortalEntry(
        label: 'Video Lessons',
        caption: 'Topic-by-topic teaching',
        icon: Icons.ondemand_video_rounded,
        colour: const Color(0xFFDB2777),
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
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (BuildContext context, int i) {
              final _PortalEntry entry = entries[i];
              return SizedBox(
                width: 140,
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: entry.builder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: entry.colour.withValues(alpha: 0.12),
                          borderRadius: AppRadii.sm,
                        ),
                        child: Icon(entry.icon, color: entry.colour, size: 19),
                      ),
                      const Spacer(),
                      Text(
                        entry.label,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.caption,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PortalEntry {
  const _PortalEntry({
    required this.label,
    required this.caption,
    required this.icon,
    required this.colour,
    required this.builder,
  });

  final String label;
  final String caption;
  final IconData icon;
  final Color colour;
  final WidgetBuilder builder;
}

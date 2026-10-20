import 'package:flutter/material.dart';

import '../../forum/presentation/forum_screen.dart';
import '../../marketplace/presentation/marketplace_screen.dart';

/// Groups the two "shared by students" parts of the portal — the forum and
/// the marketplace — under one bottom-nav destination, so the nav bar stays
/// at five items while the full myschool.ng feature set is still reachable.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _index = 0;

  static const List<Widget> _pages = <Widget>[
    ForumScreen(),
    MarketplaceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: IndexedStack(index: _index, children: _pages)),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _SwitchTab(
                    label: 'Forum',
                    icon: Icons.forum_rounded,
                    selected: _index == 0,
                    onTap: () => setState(() => _index = 0),
                  ),
                ),
                Expanded(
                  child: _SwitchTab(
                    label: 'Marketplace',
                    icon: Icons.storefront_rounded,
                    selected: _index == 1,
                    onTap: () => setState(() => _index = 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchTab extends StatelessWidget {
  const _SwitchTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 20,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

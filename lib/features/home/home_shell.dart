import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../community/presentation/community_screen.dart';
import '../performance/presentation/performance_screen.dart';
import '../practice/presentation/practice_screen.dart';
import '../profile/presentation/profile_screen.dart';
import 'presentation/home_screen.dart';

/// The five-tab frame that holds the app together: Home, Practice (CBT),
/// Community (forum + marketplace), Progress and Profile. Saved questions
/// live inside Profile rather than taking a sixth nav slot.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  static const List<Widget> _tabs = <Widget>[
    HomeScreen(),
    PracticeScreen(),
    CommunityScreen(),
    PerformanceScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColours.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (int value) => setState(() => _index = value),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_outlined),
              selectedIcon: Icon(Icons.edit_note_rounded),
              label: 'Practice',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Community',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

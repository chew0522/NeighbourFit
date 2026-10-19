import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../challenges/challenges_screen.dart';
import '../chat/messages_screen.dart';
import '../compose/create_screen.dart';
import '../feed/feed_screen.dart';
import '../profile/me_screen.dart';
import 'app_drawer.dart';

/// Five slots in a floating, rounded bar: Home · Messages · ＋ · Challenges · Me.
/// The ＋ opens a sheet, it is not a tab.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _key = GlobalKey<ScaffoldState>();
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      extendBody: true,
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _tab,
        children: [
          FeedScreen(onMenu: () => _key.currentState?.openDrawer()),
          const MessagesScreen(),
          const ChallengesScreen(),
          const MeScreen(),
        ],
      ),
      // The bar is 66 high; the ＋ is 70 and sticks out above it. The extra
      // height of this box is what keeps the raised part tappable.
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 104,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                height: 66,
                child: Material(
                  elevation: 12,
                  color: Colors.white,
                  shadowColor: Colors.black38,
                  borderRadius: BorderRadius.circular(33),
                  child: Row(
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      _NavItem(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Messages',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                      const Expanded(child: SizedBox.shrink()), // room for the ＋
                      _NavItem(
                        icon: Icons.emoji_events_rounded,
                        label: 'Challenges',
                        selected: _tab == 2,
                        onTap: () => setState(() => _tab = 2),
                      ),
                      _NavItem(
                        icon: Icons.person_rounded,
                        label: 'Me',
                        selected: _tab == 3,
                        onTap: () => setState(() => _tab = 3),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 34,
                child: Center(
                  child: Semantics(
                    label: 'Create a post',
                    button: true,
                    child: GestureDetector(
                      onTap: () => openCreate(context),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: kAccent,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: kBackground, width: 4),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, size: 40, color: kText),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? kPrimary : kMuted;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

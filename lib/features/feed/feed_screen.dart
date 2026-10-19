import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/ui_helpers.dart';
import '../compose/create_screen.dart';
import '../search/search_screen.dart';
import 'post_card.dart';

/// Home: drawer button on the left, scrollable tabs in the middle, search on
/// the right. Swipe sideways or tap a tab to change the feed.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key, required this.onMenu});

  final VoidCallback onMenu;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(feedFilterProvider);
    // Keep the pages in step when the tab changes elsewhere (for example
    // after posting, the feed jumps back to For You).
    ref.listen(feedFilterProvider, (prev, next) {
      if (_pages.hasClients && (_pages.page ?? 0).round() != next.index) {
        _pages.animateToPage(
          next.index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              current: current,
              onMenu: widget.onMenu,
              onTab: (f) => ref.read(feedFilterProvider.notifier).set(f),
              onSearch: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => ref
                    .read(feedFilterProvider.notifier)
                    .set(FeedFilter.values[i]),
                children: [
                  for (final f in FeedFilter.values)
                    _FeedList(key: ValueKey(f), filter: f),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.current,
    required this.onMenu,
    required this.onTab,
    required this.onSearch,
  });

  final FeedFilter current;
  final VoidCallback onMenu;
  final ValueChanged<FeedFilter> onTab;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            iconSize: 28,
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded, color: kText),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: box.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final f in FeedFilter.values)
                        _TabLabel(
                          label: f.label,
                          selected: f == current,
                          onTap: () => onTab(f),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search',
            iconSize: 28,
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded, color: kText),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: selected ? 19 : 17,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? kText : kMuted,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 26 : 0,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedList extends ConsumerWidget {
  const _FeedList({super.key, required this.filter});

  final FeedFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider(filter));
    final message = switch (filter) {
      FeedFilter.meetup => 'No meetups yet. Start one?',
      FeedFilter.equipment => 'Nobody is lending anything yet. Be the first?',
      FeedFilter.forYou => 'Nothing here yet. Be the first to share something.',
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
      children: [
        if (feed.posts.isEmpty)
          SizedBox(
            height: 320,
            child: EmptyState(
              icon: Icons.directions_walk,
              message: message,
              actionLabel: 'Start something',
              onAction: () => openCreate(
                context,
                initial: switch (filter) {
                  FeedFilter.meetup => CreateMode.meetup,
                  FeedFilter.equipment => CreateMode.equipment,
                  FeedFilter.forYou => CreateMode.workout,
                },
              ),
            ),
          ),
        for (final p in feed.posts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostCard(key: ValueKey(p.id), post: p),
          ),
        _EndCard(hasOlder: feed.hasOlder),
      ],
    );
  }
}

class _EndCard extends ConsumerWidget {
  const _EndCard({required this.hasOlder});

  final bool hasOlder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: kSurfaceGreen,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: kPrimary, size: 30),
            const SizedBox(height: 8),
            Text(
              hasOlder
                  ? "You're all caught up. Go for a walk!"
                  : "That's everything. Go for a walk!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            if (hasOlder) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.read(feedWindowProvider.notifier).more(),
                child: const Text('Show earlier posts'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

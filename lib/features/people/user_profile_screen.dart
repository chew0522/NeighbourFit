import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../core/models/constants.dart';
import '../../core/models/enums.dart';
import '../../core/models/post.dart';
import '../../core/models/user_profile.dart';
import '../../core/utils/time_utils.dart';
import '../../state/actions.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/avatar.dart';
import '../../widgets/tags.dart';
import '../../widgets/ui_helpers.dart';
import '../feed/post_card.dart';
import '../onboarding/wizard_screen.dart';

/// Another neighbour's page, in the style of Instagram or TikTok. There is no
/// follow or add-friend button: the only action is Message.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final user = ref.watch(userByIdProvider(userId));
    if (me == null || user == null || user.blockedUserIds.contains(me.id)) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          message: 'This profile is not available.',
        ),
      );
    }
    final isMe = me.id == user.id;
    final posts =
        ref.watch(postsProvider).where((p) => p.authorId == user.id).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final shares = posts
        .where((p) => p.type == PostType.sport || p.type == PostType.meal)
        .toList();
    final hosted = posts.where((p) => p.type == PostType.meetup).toList();
    final joined = ref
        .watch(postsProvider)
        .where(
          (p) =>
              p.isMeetup &&
              p.memberIds.contains(user.id) &&
              p.authorId != user.id,
        )
        .toList();
    final meetups = [...hosted, ...joined]
      ..sort(
        (a, b) =>
            (b.startsAt ?? b.createdAt).compareTo(a.startsAt ?? a.createdAt),
      );
    final lending = posts
        .where((p) => p.type == PostType.equipment && !p.isRequest)
        .toList();
    final community =
        ref.watch(referenceProvider).community(user.communityId)?.name ?? '';

    // Why this person is suggested, and meetups you are both going to.
    final match = isMe
        ? null
        : ref.watch(peopleMatcherProvider).scorePair(me, user);
    final now = DateTime.now();
    final together = isMe
        ? <Post>[]
        : ref
              .watch(postsProvider)
              .where(
                (p) =>
                    p.isMeetup &&
                    p.isUpcoming(now) &&
                    p.memberIds.contains(me.id) &&
                    p.memberIds.contains(user.id),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(user.nickname),
        actions: [
          if (!isMe)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'report') {
                  // MOCK: nothing is sent anywhere in the prototype.
                  showSnack('Thanks. The township team will take a look.');
                } else if (v == 'block') {
                  final ok = await confirmDialog(
                    context,
                    title: 'Block ${user.nickname}?',
                    message:
                        "You won't see their posts or messages, and they won't appear in suggestions.",
                    confirmLabel: 'Block',
                  );
                  if (!ok) return;
                  await ref.read(usersProvider.notifier).block(me.id, user.id);
                  if (context.mounted) Navigator.of(context).pop();
                  showSnack('${user.nickname} is blocked.');
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('Report')),
                PopupMenuItem(value: 'block', child: Text('Block')),
              ],
            ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: _Header(
                user: user,
                community: community,
                isMe: isMe,
                postCount: shares.length,
                meetupCount: meetups.length,
                lendingCount: lending.length,
                reasons: match?.reasons ?? const [],
                together: together,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsDelegate(
                TabBar(
                  labelColor: kText,
                  unselectedLabelColor: kMuted,
                  indicatorColor: kPrimary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  tabs: [
                    Tab(text: 'Posts ${shares.length}'),
                    Tab(text: 'Meetups ${meetups.length}'),
                    Tab(text: 'Lending ${lending.length}'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _PostList(
                posts: shares,
                empty: '${user.nickname} has not shared anything yet.',
              ),
              _PostList(posts: meetups, empty: 'No meetups yet.'),
              _PostList(posts: lending, empty: 'Nothing to borrow right now.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.user,
    required this.community,
    required this.isMe,
    required this.postCount,
    required this.meetupCount,
    required this.lendingCount,
    required this.reasons,
    required this.together,
  });

  final UserProfile user;
  final String community;
  final bool isMe;
  final int postCount;
  final int meetupCount;
  final int lendingCount;
  final List<String> reasons;
  final List<Post> together;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bio = [
      if (user.isVisible('level')) user.level.label,
      user.sports.map((s) => s.label.toLowerCase()).join(' · '),
    ].where((e) => e.isNotEmpty).join(' · ');
    final tags = <Widget>[
      if (user.isVisible('ageGroup'))
        InfoTag(icon: Icons.cake_outlined, label: 'Age ${user.ageGroup.label}'),
      if (user.isVisible('timeSlots'))
        for (final t in user.timeSlots)
          InfoTag(icon: Icons.schedule, label: t.label),
      for (final l in user.languages)
        InfoTag(icon: Icons.translate, label: languageLabels[l] ?? l),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          UserAvatar(user: user, radius: 48),
          const SizedBox(height: 12),
          Text(
            user.nickname,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            '$community · joined ${DateFormat('MMM yyyy').format(user.createdAt)}',
            style: const TextStyle(color: kMuted),
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(value: postCount, label: 'Posts'),
              _Stat(value: meetupCount, label: 'Meetups'),
              _Stat(value: lendingCount, label: 'Lending'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: isMe
                ? OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WizardScreen(editing: user),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit profile'),
                  )
                : FilledButton.icon(
                    onPressed: () async {
                      final id = await ref
                          .read(appActionsProvider)
                          .messageNeighbour(user.id);
                      if (id != null && context.mounted) openChat(context, id);
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text('Message ${user.nickname}'),
                  ),
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in reasons)
                    Chip(
                      avatar: const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: kAccentDark,
                      ),
                      label: Text(r, style: const TextStyle(fontSize: 13)),
                      backgroundColor: kAccentSoft,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ],
          if (together.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              color: kSurfaceGreen,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "You're both going to",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    for (final p in together)
                      InkWell(
                        onTap: () => openPost(context, p.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                sportIcon(p.sport),
                                size: 18,
                                color: kPrimary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${p.title ?? 'Meetup'} · ${fmtDateTime(p.startsAt!)}',
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 6, runSpacing: 6, children: tags),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        Text(label, style: const TextStyle(color: kMuted, fontSize: 13)),
      ],
    ),
  );
}

class _PostList extends StatelessWidget {
  const _PostList({required this.posts, required this.empty});

  final List<Post> posts;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            empty,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kMuted),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        for (final p in posts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostCard(key: ValueKey(p.id), post: p),
          ),
      ],
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: kBackground, child: tabBar);

  @override
  bool shouldRebuild(covariant _TabsDelegate oldDelegate) => false;
}

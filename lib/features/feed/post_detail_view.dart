import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/equipment_loan.dart';
import '../../core/models/post.dart';
import '../../core/models/user_profile.dart';
import '../../core/utils/time_utils.dart';
import '../../state/actions.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/avatar.dart';
import '../../widgets/comments_section.dart';
import '../../widgets/detail_parts.dart';
import '../../widgets/mention_text.dart';
import '../../widgets/post_photo.dart';
import '../../widgets/tags.dart';
import '../profile/my_equipment_screen.dart';
import 'post_card.dart';

/// Detail page for workouts, healthy meals and equipment. Same family as the
/// meetup page: a green header with the type's icon, then cards. The photo is
/// a card in the page, not the background.
class PostDetailView extends ConsumerWidget {
  const PostDetailView({
    super.key,
    required this.post,
    required this.me,
    required this.commentController,
    required this.onSendComment,
    required this.onPickMention,
  });

  final Post post;
  final UserProfile me;
  final TextEditingController commentController;
  final VoidCallback onSendComment;
  final VoidCallback onPickMention;

  bool get _mine => post.authorId == me.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = ref.watch(userByIdProvider(post.authorId));
    final loc = ref.watch(referenceProvider).location(post.locationId);
    final loans = ref.watch(loansProvider);
    final now = DateTime.now();

    final style = _HeaderStyle.of(post, loans, me.id, author?.nickname);

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 250,
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: detailBackButton(context),
            leadingWidth: 64,
            titleSpacing: 4,
            title: CollapseFade(
              invert: true,
              child: Text(
                style.headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: style.colors,
                      ),
                    ),
                    child: Align(
                      alignment: const Alignment(0.75, -0.3),
                      child: Icon(
                        style.icon,
                        size: 180,
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.transparent,
                          Colors.black54,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 44,
                    child: IgnorePointer(
                      child: CollapseFade(
                        child: Text(
                          style.headline,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 28,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 116,
                    child: CollapseFade(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: style.chips,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottom: detailHeaderEdge(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- who
                  DetailPanel(
                    child: Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () => openProfile(context, post.authorId),
                          child: UserAvatar(user: author, radius: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.type == PostType.equipment
                                    ? (post.isRequest
                                          ? 'Requested by'
                                          : 'Lent by')
                                    : 'Shared by',
                                style: const TextStyle(
                                  color: kMuted,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                author?.nickname ?? 'Neighbour',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                timeAgo(post.createdAt, now),
                                style: const TextStyle(
                                  color: kMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_mine)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 42),
                            ),
                            onPressed: () async {
                              final id = await ref
                                  .read(appActionsProvider)
                                  .startDm(post.authorId);
                              if (id != null && context.mounted) {
                                openChat(context, id);
                              }
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                            ),
                            label: const Text('Message'),
                          ),
                      ],
                    ),
                  ),

                  // ---- photo (a card, not the background)
                  if (post.photoPath != null) ...[
                    const SizedBox(height: 14),
                    _PhotoCard(
                      path: post.photoPath!,
                      heroTag: 'detail_photo_${post.id}',
                    ),
                  ],

                  // ---- text
                  if (post.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    DetailPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            switch (post.type) {
                              PostType.equipment =>
                                post.isRequest
                                    ? 'What they need'
                                    : 'About this item',
                              PostType.meal => 'What was on the plate',
                              _ => 'How it went',
                            },
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          MentionText(
                            post.text,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.45,
                              color: kText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ---- where
                  if (loc != null) ...[
                    const SizedBox(height: 14),
                    WherePanel(location: loc),
                  ],

                  // ---- type specific
                  if (post.type == PostType.equipment && !post.isRequest) ...[
                    const SizedBox(height: 14),
                    _BorrowPanel(post: post, mine: _mine),
                  ],
                  if (post.type == PostType.sport && _mine) ...[
                    const SizedBox(height: 14),
                    _OwnerReactions(post: post),
                  ],

                  // ---- comments
                  const SizedBox(height: 24),
                  CommentsSection(
                    post: post,
                    controller: commentController,
                    onSend: onSendComment,
                    onPickMention: onPickMention,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DetailActionBar(child: _bottomAction(ref)),
    );
  }

  Widget _bottomAction(WidgetRef ref) {
    switch (post.type) {
      case PostType.equipment:
        return SizedBox(
          height: 52,
          child: Center(child: EquipmentButton(post: post, expand: true)),
        );
      case PostType.sport:
        if (_mine) return _ownerSummary(withTogether: true);
        final next = post.nextTimeBy.any((n) => n.userId == me.id);
        void toggleNext() =>
            ref.read(postsProvider.notifier).toggleNextTime(post.id, me.id);
        return SizedBox(
          height: 52,
          child: Row(
            children: [
              CheerButton(post: post, cheered: post.cheeredBy.contains(me.id)),
              const SizedBox(width: 12),
              Expanded(
                child: next
                    ? FilledButton.icon(
                        onPressed: toggleNext,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Next time together'),
                      )
                    : OutlinedButton(
                        onPressed: toggleNext,
                        child: const Text('Next time together'),
                      ),
              ),
            ],
          ),
        );
      case PostType.meal:
      case PostType.meetup:
      case PostType.challenge:
        if (_mine) return _ownerSummary(withTogether: false);
        return SizedBox(
          height: 52,
          width: double.infinity,
          child: CheerButton(
            post: post,
            cheered: post.cheeredBy.contains(me.id),
          ),
        );
    }
  }

  /// Cheer counts are visible only to the poster.
  Widget _ownerSummary({required bool withTogether}) {
    final together = post.nextTimeBy.length;
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite, color: kAccentDark, size: 22),
          const SizedBox(width: 8),
          Text(
            '${post.cheeredBy.length} ${post.cheeredBy.length == 1 ? 'cheer' : 'cheers'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (withTogether) ...[
            const SizedBox(width: 18),
            const Icon(Icons.groups_rounded, color: kPrimary, size: 22),
            const SizedBox(width: 8),
            Text(
              '$together want to go together',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }
}

/// Header content that depends on the type of post.
class _HeaderStyle {
  const _HeaderStyle({
    required this.headline,
    required this.icon,
    required this.colors,
    required this.chips,
  });

  final String headline;
  final IconData icon;
  final List<Color> colors;
  final List<Widget> chips;

  static _HeaderStyle of(
    Post p,
    List<EquipmentLoan> loans,
    String meId,
    String? ownerName,
  ) {
    switch (p.type) {
      case PostType.equipment:
        if (p.isRequest) {
          final offered = p.offeredBy != null;
          return _HeaderStyle(
            headline: p.equipmentItem ?? 'Equipment',
            icon: Icons.front_hand_rounded,
            colors: const [Color(0xFFD9A441), kAccentDark],
            chips: [
              HeroChip(
                icon: offered
                    ? Icons.check_circle_outline
                    : Icons.hourglass_top_rounded,
                label: offered ? 'Someone can lend it' : 'Looking for a lender',
              ),
              if (p.startsAt != null)
                HeroChip(
                  icon: Icons.event_rounded,
                  label: 'Needed by ${fmtDate(p.startsAt!)}',
                ),
            ],
          );
        }
        final holder = loans
            .where((l) => l.postId == p.id && l.holdsItem)
            .firstOrNull;
        final mineOpen = loans
            .where((l) => l.postId == p.id && l.borrowerId == meId && l.isOpen)
            .firstOrNull;
        final String status;
        final IconData statusIcon;
        if (mineOpen != null && mineOpen.status == LoanStatus.requested) {
          status = 'You requested it';
          statusIcon = Icons.hourglass_top_rounded;
        } else if (mineOpen != null) {
          status = 'You are borrowing it';
          statusIcon = Icons.inventory_2_outlined;
        } else if (holder != null) {
          status = 'On loan';
          statusIcon = Icons.lock_outline;
        } else {
          status = 'Available';
          statusIcon = Icons.check_circle_outline;
        }
        return _HeaderStyle(
          headline: p.equipmentItem ?? 'Equipment',
          icon: Icons.handyman_rounded,
          colors: const [Color(0xFF7A9E7E), kPrimary],
          chips: [
            HeroChip(icon: statusIcon, label: status),
            const HeroChip(
              icon: Icons.recycling_rounded,
              label: 'Borrow, do not buy',
            ),
          ],
        );
      case PostType.meal:
        return const _HeaderStyle(
          headline: 'Healthy meal',
          icon: Icons.restaurant_rounded,
          colors: [Color(0xFF8DB255), kGreen],
          chips: [
            HeroChip(icon: Icons.eco_rounded, label: 'Healthy lifestyle'),
          ],
        );
      case PostType.sport:
      case PostType.meetup:
      case PostType.challenge:
        return _HeaderStyle(
          headline: p.sport == null ? 'Workout' : '${p.sport!.label} workout',
          icon: sportIcon(p.sport),
          colors: const [kGreen, kPrimary],
          chips: [
            HeroChip(
              icon: sportIcon(p.sport),
              label: p.sport?.label ?? 'Workout',
            ),
            const HeroChip(icon: Icons.bolt_rounded, label: 'Done today'),
          ],
        );
    }
  }
}

/// The photo as a rounded card with a "tap to zoom" hint.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.path, required this.heroTag});

  final String path;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => openPhotoViewer(context, path, heroTag),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Hero(tag: heroTag, child: photoImage(path)),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_out_map_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Tap to zoom',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How borrowing works, plus a shortcut for the owner to manage requests.
class _BorrowPanel extends StatelessWidget {
  const _BorrowPanel({required this.post, required this.mine});

  final Post post;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, String label) => Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: kSurfaceGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    const arrow = Padding(
      padding: EdgeInsets.only(bottom: 22),
      child: Icon(Icons.chevron_right_rounded, color: kMuted),
    );
    return DetailPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How borrowing works',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              step(Icons.send_rounded, 'Request'),
              arrow,
              step(Icons.check_circle_outline_rounded, 'Owner approves'),
              arrow,
              step(Icons.swap_horiz_rounded, 'Pick up and return'),
            ],
          ),
          if (mine) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyEquipmentScreen()),
              ),
              icon: const Icon(Icons.inbox_outlined, size: 20),
              label: const Text('Manage requests'),
            ),
          ],
        ],
      ),
    );
  }
}

/// For the poster of a workout: cheers and who wants to go together.
class _OwnerReactions extends ConsumerWidget {
  const _OwnerReactions({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = [
      for (final n in post.nextTimeBy) ref.watch(userByIdProvider(n.userId)),
    ].whereType<UserProfile>().toList();

    Widget stat(
      IconData icon,
      Color color,
      int value,
      String label,
    ) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
          ],
        ),
      ),
    );

    return DetailPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your reactions',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const Text(
            'Only you can see these.',
            style: TextStyle(color: kMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              stat(
                Icons.favorite,
                kAccentDark,
                post.cheeredBy.length,
                'cheers',
              ),
              const SizedBox(width: 12),
              stat(
                Icons.groups_rounded,
                kPrimary,
                people.length,
                'want to go together',
              ),
            ],
          ),
          if (people.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final u in people)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: UserAvatar(user: u, radius: 20),
                title: Text(
                  u.nickname,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final id = await ref.read(appActionsProvider).startDm(u.id);
                    if (id != null && context.mounted) openChat(context, id);
                  },
                  child: const Text('Message'),
                ),
                onTap: () => openProfile(context, u.id),
              ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'When neighbours tap "Next time together" you will see their names here.',
                style: TextStyle(color: kMuted),
              ),
            ),
        ],
      ),
    );
  }
}

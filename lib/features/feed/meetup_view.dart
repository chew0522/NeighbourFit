import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../core/models/post.dart';
import '../../core/models/user_profile.dart';
import '../../state/actions.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/avatar.dart';
import '../../widgets/comments_section.dart';
import '../../widgets/detail_parts.dart';
import '../../widgets/mention_text.dart';
import '../../widgets/post_photo.dart';
import '../../widgets/tags.dart';
import 'post_card.dart';

/// The meetup page: a big header (the photo, or a green gradient with the
/// sport), then when / where / who cards, and a join bar fixed at the bottom.
class MeetupDetailView extends ConsumerWidget {
  const MeetupDetailView({
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

  static String countdown(DateTime start, DateTime now) {
    final diff = start.difference(now);
    if (diff.isNegative) return 'This meetup has ended';
    if (diff.inMinutes < 60) {
      return 'Starts in ${diff.inMinutes.clamp(1, 59)} min';
    }
    if (diff.inHours < 24) return 'Starts in ${diff.inHours} h';
    final days = DateTime(
      start.year,
      start.month,
      start.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    return days == 1 ? 'Tomorrow' : 'In $days days';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(referenceProvider);
    final loc = data.location(post.locationId);
    final organiser = ref.watch(userByIdProvider(post.authorId));
    final members = [
      for (final id in post.memberIds) ref.watch(userByIdProvider(id)),
    ].whereType<UserProfile>().toList();
    final now = DateTime.now();
    final start = post.startsAt;
    final upcoming = post.isUpcoming(now);
    final isMember = post.memberIds.contains(me.id);
    final isOrganiser = post.authorId == me.id;

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 330,
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: detailBackButton(context),
            leadingWidth: 64,
            titleSpacing: 4,
            title: CollapseFade(
              invert: true,
              child: Text(
                post.title ?? 'Meetup',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(background: _Backdrop(post: post)),
            bottom: detailHeaderEdge(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- when
                  if (start != null)
                    DetailPanel(
                      child: Row(
                        children: [
                          _DateTile(date: start),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE').format(start),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('h:mm a').format(start),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DetailPill(
                                  icon: upcoming
                                      ? Icons.timer_outlined
                                      : Icons.history,
                                  label: countdown(start, now),
                                  background: upcoming
                                      ? kSurfaceGreen
                                      : kBorder,
                                  color: upcoming ? kPrimary : kMuted,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  // ---- where
                  if (loc != null) WherePanel(location: loc),
                  const SizedBox(height: 14),

                  // ---- who is going
                  DetailPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Who's going",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              post.capacity == null
                                  ? '${members.length} going'
                                  : '${members.length}/${post.capacity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (post.capacity != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (members.length / post.capacity!).clamp(
                                0,
                                1,
                              ),
                              minHeight: 10,
                              color: post.isFull ? kAccentDark : kGreen,
                              backgroundColor: kSurfaceGreen,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            post.isFull
                                ? 'Full'
                                : '${post.capacity! - members.length} spots left',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: post.isFull ? kAccentDark : kMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ] else ...[
                          const Text(
                            'Open to everyone, no limit.',
                            style: TextStyle(color: kMuted, fontSize: 14),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final u in members)
                              InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => openProfile(context, u.id),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    4,
                                    12,
                                    4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: u.id == post.authorId
                                        ? kAccentSoft
                                        : kSurfaceGreen,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      UserAvatar(user: u, radius: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                        u.nickname,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (u.id == post.authorId) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: kAccentDark,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ---- about
                  if (post.text.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    DetailPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          MentionText(
                            post.text,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: kText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (post.safeBuddy) ...[
                    const SizedBox(height: 14),
                    const DetailBanner(
                      icon: Icons.shield_outlined,
                      color: kAccentSoft,
                      iconColor: kAccentDark,
                      text:
                          'Safe buddy meetup. Arrive together, look out for each other and let the group know when you are home.',
                    ),
                  ],
                  if (post.accessibilityFriendly) ...[
                    const SizedBox(height: 14),
                    const DetailBanner(
                      icon: Icons.accessible_rounded,
                      color: kSurfaceGreen,
                      iconColor: kPrimary,
                      text:
                          'Accessibility-friendly: step-free route, easy pace, with seating and shade.',
                    ),
                  ],

                  // ---- organiser
                  const SizedBox(height: 14),
                  DetailPanel(
                    child: Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () => openProfile(context, post.authorId),
                          child: UserAvatar(user: organiser, radius: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Organised by',
                                style: TextStyle(color: kMuted, fontSize: 13),
                              ),
                              Text(
                                organiser?.nickname ?? 'Neighbour',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isOrganiser)
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
      bottomNavigationBar: DetailActionBar(
        child: Row(
          children: [
            if (isMember && upcoming && !isOrganiser) ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                onPressed: () => ref.read(appActionsProvider).leaveMeetup(post),
                child: const Text('Leave'),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: MeetupButton(post: post, expand: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The photo, or a green gradient with the sport icon when there is none.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = post.photoPath != null;
    final tag = 'detail_photo_${post.id}';
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasPhoto)
          GestureDetector(
            onTap: () => openPhotoViewer(context, post.photoPath!, tag),
            child: Hero(tag: tag, child: photoImage(post.photoPath!)),
          )
        else
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kGreen, kPrimary],
              ),
            ),
            child: Align(
              alignment: const Alignment(0.7, -0.35),
              child: Icon(
                sportIcon(post.sport),
                size: 190,
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
          ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black45, Colors.transparent, Colors.black87],
                stops: [0.0, 0.45, 1.0],
              ),
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
                post.title ?? 'Meetup',
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
          bottom: 120,
          child: IgnorePointer(
            child: CollapseFade(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  HeroChip(
                    icon: sportIcon(post.sport),
                    label: post.sport?.label ?? 'Sport',
                  ),
                  if (post.level != null)
                    HeroChip(
                      icon: Icons.signal_cellular_alt,
                      label: post.level!.label,
                    ),
                  if (post.safeBuddy)
                    const HeroChip(
                      icon: Icons.shield_outlined,
                      label: 'Safe buddy',
                    ),
                  if (post.accessibilityFriendly)
                    const HeroChip(icon: Icons.accessible, label: 'Accessible'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Container(
    width: 74,
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: kSurfaceGreen,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Text(
          DateFormat('MMM').format(date).toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: kPrimary,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          '${date.day}',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
    ),
  );
}

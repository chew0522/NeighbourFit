import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/equipment_loan.dart';
import '../../core/models/post.dart';
import '../../core/utils/time_utils.dart';
import '../../state/actions.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/avatar.dart';
import '../../widgets/mention_text.dart';
import '../../widgets/post_photo.dart';
import '../../widgets/tags.dart';
import '../chat/chat_screen.dart';
import '../people/user_profile_screen.dart';
import 'post_detail_screen.dart';

/// Opens the DM or group chat with [convId].
void openChat(BuildContext context, String convId) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => ChatScreen(convId: convId)));

void openProfile(BuildContext context, String userId) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)));

void openPost(BuildContext context, String postId) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)));

/// Feed card. At most two buttons; tapping the card opens the detail page.
class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = ref.watch(userByIdProvider(post.authorId));
    final me = ref.watch(currentUserProvider);
    final mine = me?.id == post.authorId;
    final now = DateTime.now();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openPost(context, post.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => openProfile(context, post.authorId),
                      child: Row(
                        children: [
                          UserAvatar(user: author, radius: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  author?.nickname ?? 'Neighbour',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  timeAgo(post.createdAt, now),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: kMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TypeLabel(type: post.type, sport: post.sport),
                ],
              ),
              const SizedBox(height: 10),
              PostBody(post: post),
              if (post.photoPath != null) ...[
                const SizedBox(height: 10),
                PostPhoto(
                  path: post.photoPath!,
                  heroTag: 'card_photo_${post.id}',
                ),
              ],
              const SizedBox(height: 10),
              _Actions(post: post, mine: mine),
            ],
          ),
        ),
      ),
    );
  }
}

/// The type-specific middle part of a card.
class PostBody extends ConsumerWidget {
  const PostBody({super.key, required this.post, this.full = false});

  final Post post;
  final bool full;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(referenceProvider).location(post.locationId);
    final people = post.capacity == null
        ? '${post.memberIds.length} going'
        : '${post.memberIds.length}/${post.capacity} going';
    switch (post.type) {
      case PostType.meetup:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title ?? 'Meetup',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.schedule,
              text: post.startsAt == null ? '' : fmtDateTime(post.startsAt!),
            ),
            if (loc != null)
              _InfoRow(icon: Icons.place_outlined, text: loc.name),
            _InfoRow(icon: Icons.group_outlined, text: people),
            if (post.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                post.text,
                maxLines: full ? null : 2,
                overflow: full ? null : TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                InfoTag(
                  icon: sportIcon(post.sport),
                  label: post.sport?.label ?? 'Sport',
                ),
                if (post.level != null)
                  InfoTag(
                    icon: Icons.signal_cellular_alt,
                    label: post.level!.label,
                  ),
                if (post.safeBuddy)
                  const InfoTag(
                    icon: Icons.shield_outlined,
                    label: 'Safe buddy',
                  ),
                if (post.accessibilityFriendly)
                  const InfoTag(icon: Icons.accessible, label: 'Accessible'),
              ],
            ),
          ],
        );
      case PostType.equipment:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.handyman, color: kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.equipmentItem ?? 'Equipment',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (post.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                post.text,
                maxLines: full ? null : 2,
                overflow: full ? null : TextOverflow.ellipsis,
              ),
            ],
          ],
        );
      case PostType.sport:
      case PostType.meal:
      case PostType.challenge:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MentionText(
              post.text,
              maxLines: full ? null : 4,
              overflow: full ? null : TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, height: 1.35, color: kText),
            ),
            if (loc != null) ...[
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.place_outlined, text: loc.name),
            ],
          ],
        );
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        Icon(icon, size: 18, color: kMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    ),
  );
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.post, required this.mine});

  final Post post;
  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const SizedBox.shrink();
    switch (post.type) {
      case PostType.sport:
        if (mine) {
          return Text(
            _ownerLine(),
            style: const TextStyle(color: kMuted, fontSize: 14),
          );
        }
        final cheered = post.cheeredBy.contains(me.id);
        final next = post.nextTimeBy.any((n) => n.userId == me.id);
        return Row(
          children: [
            CheerButton(post: post, cheered: cheered),
            const SizedBox(width: 8),
            Expanded(
              child: next
                  ? FilledButton.icon(
                      onPressed: () => ref
                          .read(postsProvider.notifier)
                          .toggleNextTime(post.id, me.id),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Next time together'),
                    )
                  : OutlinedButton(
                      onPressed: () => ref
                          .read(postsProvider.notifier)
                          .toggleNextTime(post.id, me.id),
                      child: const Text('Next time together'),
                    ),
            ),
          ],
        );
      case PostType.meal:
        if (mine) {
          return Text(
            _ownerLine(),
            style: const TextStyle(color: kMuted, fontSize: 14),
          );
        }
        return Row(
          children: [
            CheerButton(post: post, cheered: post.cheeredBy.contains(me.id)),
          ],
        );
      case PostType.meetup:
        return MeetupButton(post: post);
      case PostType.equipment:
        return EquipmentButton(post: post);
      case PostType.challenge:
        return const SizedBox.shrink();
    }
  }

  /// Cheer counts are visible only to the poster.
  String _ownerLine() {
    final parts = <String>[];
    if (post.cheeredBy.isNotEmpty) {
      parts.add(
        '${post.cheeredBy.length} ${post.cheeredBy.length == 1 ? 'cheer' : 'cheers'}',
      );
    }
    if (post.type == PostType.sport && post.nextTimeBy.isNotEmpty) {
      parts.add('${post.nextTimeBy.length} would like to go together');
    }
    return parts.isEmpty
        ? 'Only you can see cheers on your posts.'
        : parts.join(' · ');
  }
}

class CheerButton extends ConsumerWidget {
  const CheerButton({super.key, required this.post, required this.cheered});

  final Post post;
  final bool cheered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    void toggle() {
      if (me != null) {
        ref.read(postsProvider.notifier).toggleCheer(post.id, me.id);
      }
    }

    return cheered
        ? FilledButton.icon(
            onPressed: toggle,
            icon: const Icon(Icons.favorite, size: 18),
            label: const Text('Cheered'),
          )
        : OutlinedButton.icon(
            onPressed: toggle,
            icon: const Icon(Icons.favorite_border, size: 18),
            label: const Text('Cheer'),
          );
  }
}

/// I'm in / Open chat / Full / Ended, depending on the user's relation to it.
class MeetupButton extends ConsumerWidget {
  const MeetupButton({
    super.key,
    required this.post,
    this.expand = false,
    this.onJoin,
  });

  final Post post;
  final bool expand;

  /// Called after "I'm in" is tapped (used by the assistant to log the action).
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const SizedBox.shrink();
    final upcoming = post.isUpcoming(DateTime.now());
    final member = post.memberIds.contains(me.id);
    final convs = ref.watch(chatProvider);
    String? convId;
    for (final c in convs) {
      if (c.isGroup && c.sourcePostId == post.id) convId = c.id;
    }

    Widget button;
    if (!upcoming) {
      button = OutlinedButton(onPressed: null, child: const Text('Ended'));
    } else if (member) {
      button = FilledButton.icon(
        onPressed: convId == null ? null : () => openChat(context, convId!),
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: const Text('Open chat'),
      );
    } else if (post.isFull) {
      button = OutlinedButton(onPressed: null, child: const Text('Full'));
    } else {
      button = FilledButton(
        onPressed: () {
          onJoin?.call();
          ref.read(appActionsProvider).joinMeetup(post);
        },
        child: const Text("I'm in"),
      );
    }
    return expand
        ? SizedBox(width: double.infinity, child: button)
        : Align(alignment: Alignment.centerLeft, child: button);
  }
}

/// Borrow / Requested / On loan for equipment posts.
class EquipmentButton extends ConsumerWidget {
  const EquipmentButton({super.key, required this.post, this.expand = false});

  final Post post;
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const SizedBox.shrink();
    final loans = ref.watch(loansProvider);
    final holder = loans
        .where((l) => l.postId == post.id && l.holdsItem)
        .firstOrNull;
    final mineOpen = loans
        .where((l) => l.postId == post.id && l.borrowerId == me.id && l.isOpen)
        .firstOrNull;

    Widget button;
    if (post.authorId == me.id) {
      button = Text(
        holder != null ? 'On loan' : 'Available',
        style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
      );
    } else if (mineOpen != null && mineOpen.status == LoanStatus.requested) {
      button = const OutlinedButton(onPressed: null, child: Text('Requested'));
    } else if (mineOpen != null) {
      button = const OutlinedButton(
        onPressed: null,
        child: Text('You are borrowing'),
      );
    } else if (holder != null) {
      button = const OutlinedButton(onPressed: null, child: Text('On loan'));
    } else {
      button = FilledButton(
        onPressed: () async {
          final id = await ref.read(appActionsProvider).borrow(post);
          if (id != null && context.mounted) openChat(context, id);
        },
        child: const Text('Borrow'),
      );
    }
    return expand
        ? SizedBox(width: double.infinity, child: button)
        : Align(alignment: Alignment.centerLeft, child: button);
  }
}

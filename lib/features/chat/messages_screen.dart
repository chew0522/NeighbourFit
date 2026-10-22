import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/conversation.dart';
import '../../core/utils/time_utils.dart';
import '../../state/app_state.dart';
import '../../widgets/avatar.dart';
import '../feed/post_card.dart';
import 'activity_screens.dart';

/// Messages: three quick icons (Cheers, Mentions, Comments) above the list of
/// DMs and meetup group chats.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final convs =
        ref
            .watch(chatProvider)
            .where(
              (c) =>
                  me != null &&
                  c.memberIds.contains(me.id) &&
                  c.status != 'blocked',
            )
            .toList()
          ..sort(
            (a, b) => (b.lastAt ?? DateTime(2000)).compareTo(
              a.lastAt ?? DateTime(2000),
            ),
          );

    void go(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 130),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InboxIcon(
                  icon: Icons.favorite_rounded,
                  label: 'Cheers',
                  color: kAccentDark,
                  background: kAccentSoft,
                  onTap: () => go(const CheersScreen()),
                ),
                _InboxIcon(
                  icon: Icons.alternate_email_rounded,
                  label: 'Mentions',
                  color: kPrimary,
                  background: kSurfaceGreen,
                  onTap: () => go(const MentionsScreen()),
                ),
                _InboxIcon(
                  icon: Icons.mode_comment_rounded,
                  label: 'Comments',
                  color: kClay,
                  background: kClaySoft,
                  onTap: () => go(const CommentsScreen()),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (convs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                "No messages yet. Tap I'm in on a meetup or message a neighbour.",
                textAlign: TextAlign.center,
                style: TextStyle(color: kMuted),
              ),
            ),
          for (final c in convs) _ConversationTile(conversation: c),
        ],
      ),
    );
  }
}

class _InboxIcon extends StatelessWidget {
  const _InboxIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final c = conversation;
    final otherId = c.memberIds.firstWhere(
      (e) => e != me?.id,
      orElse: () => '',
    );
    final other = ref.watch(userByIdProvider(otherId));
    final last = c.messages.isEmpty ? null : c.messages.last;
    final sender = last == null
        ? null
        : ref.watch(userByIdProvider(last.senderId));
    final preview = last == null
        ? 'No messages yet'
        : (last.isSystem || c.isGroup && sender != null && sender.id != me?.id
              ? (last.isSystem
                    ? last.text
                    : '${sender!.nickname}: ${last.text}')
              : last.text);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: c.isGroup
          ? const CircleAvatar(
              radius: 24,
              backgroundColor: kSurfaceGreen,
              child: Icon(Icons.groups, color: kPrimary),
            )
          : UserAvatar(user: other, radius: 24),
      title: Text(
        c.isGroup
            ? (c.title ?? 'Meetup chat')
            : (other?.nickname ?? 'Neighbour'),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
      ),
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: last == null
          ? null
          : Text(
              timeAgo(last.createdAt, DateTime.now()),
              style: const TextStyle(color: kMuted, fontSize: 12),
            ),
      onTap: () => openChat(context, c.id),
    );
  }
}

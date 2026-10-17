import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/post.dart';
import '../../core/models/user_profile.dart';
import '../../core/utils/mentions.dart';
import '../../core/utils/time_utils.dart';
import '../../state/app_state.dart';
import '../../widgets/avatar.dart';
import '../../widgets/mention_text.dart';
import '../../widgets/ui_helpers.dart';
import '../feed/post_card.dart';

String _what(Post p) {
  switch (p.type) {
    case PostType.sport:
      return 'workout';
    case PostType.meal:
      return 'meal';
    case PostType.meetup:
      return 'meetup';
    case PostType.equipment:
      return 'equipment post';
    case PostType.challenge:
      return 'post';
  }
}

String _snippet(Post p) {
  final raw = p.title ?? p.equipmentItem ?? p.text;
  return raw.length > 60 ? '${raw.substring(0, 57)}...' : raw;
}

String _names(List<UserProfile?> users) {
  final n = users.whereType<UserProfile>().map((u) => u.nickname).toList();
  if (n.isEmpty) return 'Neighbours';
  if (n.length == 1) return n.first;
  if (n.length == 2) return '${n[0]} and ${n[1]}';
  return '${n[0]}, ${n[1]} and ${n.length - 2} other${n.length - 2 == 1 ? '' : 's'}';
}

class _Row extends StatelessWidget {
  const _Row({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 2), subtitle],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      );
}

Widget _page(String title, String intro, List<Widget> rows, IconData emptyIcon, String empty) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: rows.isEmpty
        ? EmptyState(icon: emptyIcon, message: empty)
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(intro, style: const TextStyle(color: kMuted, fontSize: 14)),
              ),
              ...rows,
            ],
          ),
  );
}

/// Who cheered your posts. Cheer counts are visible only to the poster, so
/// this page is the only place they show.
class CheersScreen extends ConsumerWidget {
  const CheersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const Scaffold();
    final users = ref.watch(usersProvider);
    final mine = ref
        .watch(postsProvider)
        .where((p) => p.authorId == me.id && p.cheeredBy.isNotEmpty)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final rows = <Widget>[
      for (final p in mine)
        _Row(
          onTap: () => openPost(context, p.id),
          leading: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Color(0xFFFCEFE9), shape: BoxShape.circle),
            child: const Icon(Icons.favorite, color: kAccent),
          ),
          title: Text(
            '${_names([for (final id in p.cheeredBy) users.where((u) => u.id == id).firstOrNull])} cheered your ${_what(p)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          subtitle: Text(_snippet(p),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted)),
          trailing: Text('${p.cheeredBy.length}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: kAccent, fontSize: 18)),
        ),
    ];
    return _page(
      'Cheers',
      'Only you can see who cheered your posts.',
      rows,
      Icons.favorite_border,
      'No cheers yet. Share a workout and your neighbours can cheer you on.',
    );
  }
}

/// Posts and comments where a neighbour wrote "@YourName".
class MentionsScreen extends ConsumerWidget {
  const MentionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const Scaffold();
    final users = ref.watch(usersProvider);
    UserProfile? byId(String id) => users.where((u) => u.id == id).firstOrNull;

    final items = <({DateTime at, Widget row})>[];
    for (final p in ref.watch(postsProvider)) {
      if (p.authorId != me.id && mentionsNickname(p.text, me.nickname)) {
        final a = byId(p.authorId);
        items.add((
          at: p.createdAt,
          row: _Row(
            onTap: () => openPost(context, p.id),
            leading: UserAvatar(user: a, radius: 22),
            title: Text('${a?.nickname ?? 'Someone'} mentioned you in a ${_what(p)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: MentionText(p.text,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted)),
            trailing: Text(timeAgo(p.createdAt, DateTime.now()),
                style: const TextStyle(color: kMuted, fontSize: 12)),
          ),
        ));
      }
      for (final c in p.comments) {
        if (c.authorId != me.id && mentionsNickname(c.text, me.nickname)) {
          final a = byId(c.authorId);
          items.add((
            at: c.createdAt,
            row: _Row(
              onTap: () => openPost(context, p.id),
              leading: UserAvatar(user: a, radius: 22),
              title: Text('${a?.nickname ?? 'Someone'} mentioned you in a comment',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              subtitle: MentionText(c.text,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted)),
              trailing: Text(timeAgo(c.createdAt, DateTime.now()),
                  style: const TextStyle(color: kMuted, fontSize: 12)),
            ),
          ));
        }
      }
    }
    items.sort((a, b) => b.at.compareTo(a.at));
    return _page(
      'Mentions',
      'Posts and comments where a neighbour wrote @${me.nickname}.',
      [for (final i in items) i.row],
      Icons.alternate_email,
      'No mentions yet. When a neighbour writes @${me.nickname}, it shows up here.',
    );
  }
}

/// Comments neighbours left on your posts.
class CommentsScreen extends ConsumerWidget {
  const CommentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const Scaffold();
    final users = ref.watch(usersProvider);
    final items = <({DateTime at, Widget row})>[];
    for (final p in ref.watch(postsProvider).where((p) => p.authorId == me.id)) {
      for (final c in p.comments.where((c) => c.authorId != me.id)) {
        final a = users.where((u) => u.id == c.authorId).firstOrNull;
        items.add((
          at: c.createdAt,
          row: _Row(
            onTap: () => openPost(context, p.id),
            leading: UserAvatar(user: a, radius: 22),
            title: Text('${a?.nickname ?? 'Someone'} commented on your ${_what(p)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: MentionText(c.text,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted)),
            trailing: Text(timeAgo(c.createdAt, DateTime.now()),
                style: const TextStyle(color: kMuted, fontSize: 12)),
          ),
        ));
      }
    }
    items.sort((a, b) => b.at.compareTo(a.at));
    return _page(
      'Comments',
      'What neighbours said on your posts.',
      [for (final i in items) i.row],
      Icons.mode_comment_outlined,
      'No comments yet.',
    );
  }
}

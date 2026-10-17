import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/post.dart';
import '../../core/models/user_profile.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/time_utils.dart';
import '../../state/actions.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/avatar.dart';
import '../../widgets/mention_text.dart';
import '../../widgets/tags.dart';
import '../../widgets/ui_helpers.dart';
import 'post_card.dart';

/// Everything that is not on the card lives here: full text, comments,
/// Message, map link, member list.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _sendComment(Post post) async {
    final me = ref.read(currentUserProvider);
    final text = _comment.text.trim();
    if (me == null || text.isEmpty) return;
    await ref.read(postsProvider.notifier).addComment(
          post.id,
          Comment(id: newId('c_'), authorId: me.id, text: text, createdAt: DateTime.now()),
        );
    _comment.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  /// Lets the user pick a neighbour and inserts "@Nickname " into the comment.
  Future<void> _pickMention() async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final people = ref
        .read(usersProvider)
        .where((u) =>
            u.id != me.id && u.communityId == me.communityId && !me.blockedUserIds.contains(u.id))
        .toList();
    final picked = await showModalBottomSheet<UserProfile>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Mention a neighbour',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            for (final u in people)
              ListTile(
                leading: UserAvatar(user: u, radius: 18),
                title: Text(u.nickname),
                onTap: () => Navigator.pop(ctx, u),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    final t = _comment.text;
    final add = '@${picked.nickname} ';
    _comment.text = (t.isEmpty || t.endsWith(' ')) ? '$t$add' : '$t $add';
    _comment.selection = TextSelection.collapsed(offset: _comment.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(postByIdProvider(widget.postId));
    final me = ref.watch(currentUserProvider);
    if (post == null || me == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.search_off, message: 'This post is no longer available.'),
      );
    }
    final author = ref.watch(userByIdProvider(post.authorId));
    final mine = post.authorId == me.id;
    final loc = ref.watch(referenceProvider).location(post.locationId);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(_title(post))),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => openProfile(context, post.authorId),
                        child: Row(
                          children: [
                            UserAvatar(user: author, radius: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(author?.nickname ?? 'Neighbour',
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                                  Text(timeAgo(post.createdAt, now),
                                      style: const TextStyle(color: kMuted, fontSize: 13)),
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
                const SizedBox(height: 14),
                PostBody(post: post, full: true),
                if (loc != null) ...[
                  const SizedBox(height: 10),
                  if (loc.accessibilityNotes.isNotEmpty)
                    Text(loc.accessibilityNotes, style: const TextStyle(color: kMuted, fontSize: 14)),
                  TextButton.icon(
                    onPressed: () => openUrl(loc.mapsUrl),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open in Google Maps'),
                  ),
                ],
                const SizedBox(height: 8),
                if (post.isMeetup) ..._meetupSection(post, me.id),
                if (post.type == PostType.equipment) EquipmentButton(post: post, expand: true),
                if (post.type == PostType.sport) ..._sportSection(post, mine, me.id),
                if (post.type == PostType.meal && !mine)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CheerButton(post: post, cheered: post.cheeredBy.contains(me.id)),
                  ),
                if (mine && post.type != PostType.sport && post.cheeredBy.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${post.cheeredBy.length} cheers (only you can see this)',
                        style: const TextStyle(color: kMuted)),
                  ),
                if (!mine) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final id = await ref.read(appActionsProvider).startDm(post.authorId);
                      if (id != null && context.mounted) openChat(context, id);
                    },
                    icon: const Icon(Icons.mail_outline),
                    label: Text('Message ${author?.nickname ?? 'author'}'),
                  ),
                ],
                const Divider(height: 32),
                Text('Comments (${post.comments.length})',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (post.comments.isEmpty)
                  const Text('No comments yet. Say something kind.', style: TextStyle(color: kMuted)),
                for (final c in post.comments) _CommentTile(comment: c),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Mention a neighbour',
                    icon: const Icon(Icons.alternate_email_rounded, color: kPrimary),
                    onPressed: _pickMention,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _comment,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Add a comment'),
                      onSubmitted: (_) => _sendComment(post),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: kAccent, foregroundColor: kText),
                    onPressed: () => _sendComment(post),
                    icon: const Icon(Icons.send),
                    tooltip: 'Send comment',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _title(Post p) {
    switch (p.type) {
      case PostType.meetup:
        return 'Meetup';
      case PostType.equipment:
        return 'Equipment';
      case PostType.meal:
        return 'Healthy meal';
      case PostType.sport:
        return 'Workout';
      case PostType.challenge:
        return 'Challenge';
    }
  }

  List<Widget> _meetupSection(Post post, String meId) {
    final members = post.memberIds
        .map((id) => ref.watch(userByIdProvider(id)))
        .whereType<UserProfile>()
        .toList();
    final isMember = post.memberIds.contains(meId);
    final upcoming = post.isUpcoming(DateTime.now());
    return [
      MeetupButton(post: post, expand: true),
      if (isMember && upcoming && post.authorId != meId)
        TextButton(
          onPressed: () => ref.read(appActionsProvider).leaveMeetup(post),
          child: const Text('Leave this meetup'),
        ),
      const SizedBox(height: 12),
      Text('Who is going (${members.length})',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      for (final u in members)
        ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () => openProfile(context, u.id),
          leading: UserAvatar(user: u, radius: 18),
          title: Text(u.nickname + (u.id == post.authorId ? ' (organiser)' : '')),
          subtitle: u.isVisible('ageGroup') ? Text('Age ${u.ageGroup.label}') : null,
        ),
    ];
  }

  List<Widget> _sportSection(Post post, bool mine, String meId) {
    if (mine) {
      final names = post.nextTimeBy
          .map((n) => ref.watch(userByIdProvider(n.userId)))
          .whereType<UserProfile>()
          .toList();
      return [
        if (post.cheeredBy.isNotEmpty)
          Text('${post.cheeredBy.length} cheers (only you can see this)',
              style: const TextStyle(color: kMuted)),
        const SizedBox(height: 8),
        if (names.isNotEmpty) ...[
          Text('${names.length} neighbours would like to go together',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          for (final u in names)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(user: u, radius: 18),
              title: Text(u.nickname),
              trailing: TextButton(
                onPressed: () async {
                  final id = await ref.read(appActionsProvider).startDm(u.id);
                  if (id != null && mounted) openChat(context, id);
                },
                child: const Text('Message'),
              ),
            ),
        ] else
          const Text('When neighbours tap "Next time together" you will see their names here.',
              style: TextStyle(color: kMuted)),
      ];
    }
    return [
      Row(
        children: [
          CheerButton(post: post, cheered: post.cheeredBy.contains(meId)),
          const SizedBox(width: 8),
          Expanded(
            child: post.nextTimeBy.any((n) => n.userId == meId)
                ? FilledButton.icon(
                    onPressed: () => ref.read(postsProvider.notifier).toggleNextTime(post.id, meId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Next time together'),
                  )
                : OutlinedButton(
                    onPressed: () => ref.read(postsProvider.notifier).toggleNextTime(post.id, meId),
                    child: const Text('Next time together'),
                  ),
          ),
        ],
      ),
    ];
  }
}

class _CommentTile extends ConsumerWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(userByIdProvider(comment.authorId));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(user: u, radius: 15),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u?.nickname ?? 'Neighbour',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                MentionText(comment.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/post.dart';
import '../../core/models/user_profile.dart';
import '../../core/utils/ids.dart';
import '../../state/app_state.dart';
import '../../widgets/avatar.dart';
import '../../widgets/ui_helpers.dart';
import 'meetup_view.dart';
import 'post_detail_view.dart';

/// Opens the right detail page for a post: the meetup page, or the page for
/// workouts, meals and equipment.
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
    await ref
        .read(postsProvider.notifier)
        .addComment(
          post.id,
          Comment(
            id: newId('c_'),
            authorId: me.id,
            text: text,
            createdAt: DateTime.now(),
          ),
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
        .where(
          (u) =>
              u.id != me.id &&
              u.communityId == me.communityId &&
              !me.blockedUserIds.contains(u.id),
        )
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
              child: Text(
                'Mention a neighbour',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
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
        body: const EmptyState(
          icon: Icons.search_off,
          message: 'This post is no longer available.',
        ),
      );
    }
    if (post.isMeetup) {
      return MeetupDetailView(
        post: post,
        me: me,
        commentController: _comment,
        onSendComment: () => _sendComment(post),
        onPickMention: _pickMention,
      );
    }
    return PostDetailView(
      post: post,
      me: me,
      commentController: _comment,
      onSendComment: () => _sendComment(post),
      onPickMention: _pickMention,
    );
  }
}

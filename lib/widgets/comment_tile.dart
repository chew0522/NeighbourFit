import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/post.dart';
import '../state/app_state.dart';
import 'avatar.dart';
import 'mention_text.dart';

class CommentTile extends ConsumerWidget {
  const CommentTile({super.key, required this.comment});

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
                Text(
                  u?.nickname ?? 'Neighbour',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                MentionText(comment.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

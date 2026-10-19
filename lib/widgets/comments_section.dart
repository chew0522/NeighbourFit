import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/models/post.dart';
import 'comment_tile.dart';

/// Heading, input row (with an @ button) and the list of comments.
class CommentsSection extends StatelessWidget {
  const CommentsSection({
    super.key,
    required this.post,
    required this.controller,
    required this.onSend,
    required this.onPickMention,
  });

  final Post post;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPickMention;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments (${post.comments.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              tooltip: 'Mention a neighbour',
              icon: const Icon(Icons.alternate_email_rounded, color: kPrimary),
              onPressed: onPickMention,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Add a comment'),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: onSend,
              icon: const Icon(Icons.send),
              tooltip: 'Send comment',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (post.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No comments yet. Say something kind.',
              style: TextStyle(color: kMuted),
            ),
          ),
        for (final c in post.comments) CommentTile(comment: c),
      ],
    );
  }
}

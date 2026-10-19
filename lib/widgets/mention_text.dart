import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_theme.dart';
import '../core/utils/mentions.dart';
import '../state/app_state.dart';

/// Text where "@Nickname" of a real neighbour is shown bold and green.
class MentionText extends ConsumerWidget {
  const MentionText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final pattern = text.contains('@')
        ? mentionPattern(ref.watch(usersProvider).map((u) => u.nickname))
        : null;
    if (pattern == null) {
      return Text(text, style: base, maxLines: maxLines, overflow: overflow);
    }
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(0),
          style: const TextStyle(fontWeight: FontWeight.w800, color: kPrimary),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

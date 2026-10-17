/// True if [text] contains "@Nickname" for this nickname (case-insensitive,
/// not followed by another letter or digit).
bool mentionsNickname(String text, String nickname) {
  if (nickname.trim().isEmpty) return false;
  return RegExp('@${RegExp.escape(nickname)}(?![A-Za-z0-9])', caseSensitive: false)
      .hasMatch(text);
}

/// One pattern that matches "@" followed by any of the given nicknames
/// (longest first so "Mei Ling" wins over "Mei"). Null if there are none.
RegExp? mentionPattern(Iterable<String> nicknames) {
  final names = nicknames.where((n) => n.trim().isNotEmpty).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  if (names.isEmpty) return null;
  return RegExp('@(?:${names.map(RegExp.escape).join('|')})(?![A-Za-z0-9])',
      caseSensitive: false);
}

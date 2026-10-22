import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/post.dart';
import '../../core/models/user_profile.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/ui_helpers.dart';
import '../feed/post_card.dart';
import '../people/neighbour_row.dart';

const _ideas = ['Running', 'Yoga', 'Walk', 'Mat', 'Badminton', 'Morning'];

/// Search across posts and neighbours in your own community.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _postMatches(Post p, String q, UserProfile? author, String place) {
    final hay = [
      p.title,
      p.text,
      p.equipmentItem,
      p.sport?.label,
      p.type.name,
      place,
      author?.nickname,
    ].whereType<String>().join(' ').toLowerCase();
    return q.split(RegExp(r'\s+')).every(hay.contains);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final q = _q.trim().toLowerCase();
    final users = ref.watch(usersProvider);
    final reference = ref.watch(referenceProvider);
    final suggestions = ref.watch(suggestionsProvider);

    List<Post> posts = const [];
    List<UserProfile> people = const [];
    if (me != null && q.isNotEmpty) {
      posts = ref.watch(postsProvider).where((p) {
        if (p.communityId != me.communityId || p.type == PostType.challenge) {
          return false;
        }
        if (me.blockedUserIds.contains(p.authorId)) return false;
        final author = users.where((u) => u.id == p.authorId).firstOrNull;
        return _postMatches(
          p,
          q,
          author,
          reference.location(p.locationId)?.name ?? '',
        );
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      people = users
          .where(
            (u) =>
                u.id != me.id &&
                u.communityId == me.communityId &&
                !me.blockedUserIds.contains(u.id) &&
                !u.blockedUserIds.contains(me.id) &&
                u.nickname.toLowerCase().contains(q),
          )
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _q = v),
          decoration: InputDecoration(
            hintText: 'Search meetups, equipment, neighbours',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            suffixIcon: _q.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _ctrl.clear();
                      _q = '';
                    }),
                  ),
          ),
          style: const TextStyle(fontSize: 18),
        ),
      ),
      body: q.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Try searching for',
                  style: TextStyle(color: kMuted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final i in _ideas)
                      ActionChip(
                        label: Text(i),
                        onPressed: () => setState(() {
                          _ctrl.text = i;
                          _q = i;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (suggestions.isNotEmpty) ...[
                  const Text(
                    'Neighbours you may like',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Based on the sports, times and age group you chose.',
                    style: TextStyle(color: kMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  for (final s in suggestions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NeighbourRow(
                        user: s.user,
                        subtitle: s.reasons.isEmpty
                            ? 'Lives nearby'
                            : s.reasons.join(' · '),
                        onTap: () => openProfile(context, s.user.id),
                      ),
                    ),
                ],
              ],
            )
          : (posts.isEmpty && people.isEmpty)
          ? const EmptyState(
              icon: Icons.search_off,
              message: 'No results. Try another word.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (people.isNotEmpty) ...[
                  const Text(
                    'Neighbours',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final u in people)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NeighbourRow(
                        user: u,
                        subtitle: u.sports.map((s) => s.label).join(' · '),
                        onTap: () => openProfile(context, u.id),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                if (posts.isNotEmpty) ...[
                  Text(
                    'Posts (${posts.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final p in posts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PostCard(key: ValueKey(p.id), post: p),
                    ),
                ],
              ],
            ),
    );
  }
}

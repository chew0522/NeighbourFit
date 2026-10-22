import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/challenge.dart';
import '../core/models/conversation.dart';
import '../core/models/enums.dart';
import '../core/models/equipment_loan.dart';
import '../core/models/points_entry.dart';
import '../core/models/post.dart';
import '../core/models/recommendation_log.dart';
import '../core/models/reference_models.dart';
import '../core/models/user_profile.dart';
import '../core/utils/ids.dart';
import '../core/utils/time_utils.dart';
import '../data/local/local_repositories.dart';
import '../services/people_matcher.dart';
import 'core_providers.dart';

final _rng = Random();

// ---------------------------------------------------------------- session

class SessionNotifier extends Notifier<String?> {
  @override
  String? build() => ref.read(storeProvider).getString(StoreKeys.session);

  Future<void> signIn(String userId) async {
    state = userId;
    await ref.read(storeProvider).setString(StoreKeys.session, userId);
  }

  Future<void> signOut() async {
    state = null;
    await ref.read(storeProvider).remove(StoreKeys.session);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, String?>(
  SessionNotifier.new,
);

// ------------------------------------------------------------------ users

class UsersNotifier extends Notifier<List<UserProfile>> {
  @override
  List<UserProfile> build() => ref.read(userRepoProvider).load();

  Future<void> _save(List<UserProfile> next) async {
    state = next;
    await ref.read(userRepoProvider).save(next);
  }

  UserProfile? byId(String id) {
    for (final u in state) {
      if (u.id == id) return u;
    }
    return null;
  }

  Future<void> upsert(UserProfile u) async {
    final exists = state.any((e) => e.id == u.id);
    await _save(
      exists ? [for (final e in state) e.id == u.id ? u : e] : [...state, u],
    );
  }

  Future<void> update(String id, UserProfile Function(UserProfile) f) =>
      _save([for (final u in state) u.id == id ? f(u) : u]);

  Future<void> addPoints(String id, int delta) => update(
    id,
    (u) => u.copyWith(points: (u.points + delta).clamp(0, 1 << 30)),
  );

  Future<void> block(String me, String other) => update(
    me,
    (u) => u.blockedUserIds.contains(other)
        ? u
        : u.copyWith(blockedUserIds: [...u.blockedUserIds, other]),
  );

  Future<void> unblock(String me, String other) => update(
    me,
    (u) => u.copyWith(
      blockedUserIds: u.blockedUserIds.where((e) => e != other).toList(),
    ),
  );

  Future<void> dismissSuggestion(String me, String other) => update(
    me,
    (u) => u.dismissedSuggestionIds.contains(other)
        ? u
        : u.copyWith(
            dismissedSuggestionIds: [...u.dismissedSuggestionIds, other],
          ),
  );

  /// Returns the voucher code, or null if the user lacks the points.
  Future<String?> redeem(String userId, Voucher v) async {
    final u = byId(userId);
    if (u == null || u.points < v.pointsCost) return null;
    final code =
        'NF-${v.id.replaceFirst('v_', '').toUpperCase()}-${1000 + _rng.nextInt(9000)}';
    await update(
      userId,
      (x) => x.copyWith(
        points: x.points - v.pointsCost,
        redeemedVouchers: [
          ...x.redeemedVouchers,
          RedeemedVoucher(voucherId: v.id, code: code, at: DateTime.now()),
        ],
      ),
    );
    await ref
        .read(pointsProvider.notifier)
        .add(
          userId: userId,
          delta: -v.pointsCost,
          label: 'Redeemed: ${v.title}',
          refType: 'redeem',
          refId: v.id,
        );
    return code;
  }
}

final usersProvider = NotifierProvider<UsersNotifier, List<UserProfile>>(
  UsersNotifier.new,
);

final currentUserProvider = Provider<UserProfile?>((ref) {
  final id = ref.watch(sessionProvider);
  if (id == null) return null;
  for (final u in ref.watch(usersProvider)) {
    if (u.id == id) return u;
  }
  return null;
});

final userByIdProvider = Provider.family<UserProfile?, String>((ref, id) {
  for (final u in ref.watch(usersProvider)) {
    if (u.id == id) return u;
  }
  return null;
});

// ------------------------------------------------------------------ posts

class PostsNotifier extends Notifier<List<Post>> {
  @override
  List<Post> build() => ref.read(postRepoProvider).load();

  Future<void> _save(List<Post> next) async {
    state = next;
    await ref.read(postRepoProvider).save(next);
  }

  Post? byId(String id) {
    for (final p in state) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _change(String id, Post Function(Post) f) =>
      _save([for (final p in state) p.id == id ? f(p) : p]);

  Future<void> add(Post p) async {
    await _save([p, ...state]);
    final me = ref.read(sessionProvider);
    if (p.authorId != me) return;
    if (p.type == PostType.sport) _mockNextTimeReactions(p);
    if (p.type == PostType.equipment && !p.isRequest) _mockBorrowRequest(p);
  }

  Future<void> toggleCheer(String postId, String userId) =>
      _change(postId, (p) {
        final has = p.cheeredBy.contains(userId);
        return p.copyWith(
          cheeredBy: has
              ? p.cheeredBy.where((e) => e != userId).toList()
              : [...p.cheeredBy, userId],
        );
      });

  Future<void> addComment(String postId, Comment c) =>
      _change(postId, (p) => p.copyWith(comments: [...p.comments, c]));

  Future<void> toggleNextTime(String postId, String userId) =>
      _change(postId, (p) {
        final has = p.nextTimeBy.any((n) => n.userId == userId);
        return p.copyWith(
          nextTimeBy: has
              ? p.nextTimeBy.where((n) => n.userId != userId).toList()
              : [...p.nextTimeBy, NextTime(userId: userId, at: DateTime.now())],
        );
      });

  /// false if the meetup is full or the user is already in.
  Future<bool> join(String postId, String userId) async {
    final p = byId(postId);
    if (p == null || p.memberIds.contains(userId) || p.isFull) return false;
    await _change(
      postId,
      (x) => x.copyWith(memberIds: [...x.memberIds, userId]),
    );
    return true;
  }

  Future<void> leave(String postId, String userId) => _change(
    postId,
    (p) =>
        p.copyWith(memberIds: p.memberIds.where((e) => e != userId).toList()),
  );

  /// A neighbour says "I can lend" on a request. false if it is not a
  /// request or somebody already offered.
  Future<bool> offer(String postId, String userId) async {
    final p = byId(postId);
    if (p == null || !p.isRequest || p.offeredBy != null) return false;
    await _change(postId, (x) => x.copyWith(offeredBy: userId));
    return true;
  }

  // MOCK: a few seconds after you share a workout, two neighbours say
  // "next time together" so the poster-only list can be demonstrated.
  void _mockNextTimeReactions(Post post) {
    Future.delayed(const Duration(seconds: 4), () async {
      try {
        final others =
            ref
                .read(usersProvider)
                .where(
                  (u) =>
                      u.id != post.authorId &&
                      u.communityId == post.communityId,
                )
                .toList()
              ..shuffle(_rng);
        final picks = others.take(2).toList();
        if (picks.isEmpty) return;
        await _change(
          post.id,
          (p) => p.copyWith(
            nextTimeBy: [
              ...p.nextTimeBy,
              for (final u in picks)
                NextTime(
                  userId: u.id,
                  note: 'Would love to join you!',
                  at: DateTime.now(),
                ),
            ],
          ),
        );
      } catch (_) {}
    });
  }

  // MOCK: a neighbour asks to borrow the item you just listed.
  void _mockBorrowRequest(Post post) {
    Future.delayed(const Duration(seconds: 6), () async {
      try {
        final others = ref
            .read(usersProvider)
            .where(
              (u) => u.id != post.authorId && u.communityId == post.communityId,
            )
            .toList();
        if (others.isEmpty) return;
        final who = others[_rng.nextInt(others.length)];
        await ref.read(loansProvider.notifier).request(post, who.id);
      } catch (_) {}
    });
  }
}

final postsProvider = NotifierProvider<PostsNotifier, List<Post>>(
  PostsNotifier.new,
);

final postByIdProvider = Provider.family<Post?, String>((ref, id) {
  for (final p in ref.watch(postsProvider)) {
    if (p.id == id) return p;
  }
  return null;
});

// ------------------------------------------------------------------- chat

const _cannedDm = [
  'Sounds good!',
  'Sure, what time works for you?',
  'Thanks for reaching out. Happy to meet at the park.',
  'I usually go in the morning. Does that suit you?',
  'Great, see you soon!',
];

const _cannedGroup = [
  'See you there!',
  'I will be about 5 minutes late.',
  'Still going if it rains?',
  'Which entrance are we meeting at?',
  'I will bring some water for everyone.',
];

class ChatNotifier extends Notifier<List<Conversation>> {
  @override
  List<Conversation> build() => ref.read(chatRepoProvider).load();

  Future<void> _save(List<Conversation> next) async {
    state = next;
    await ref.read(chatRepoProvider).save(next);
  }

  Conversation? byId(String id) {
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
  }

  Conversation? groupFor(String postId) {
    for (final c in state) {
      if (c.isGroup && c.sourcePostId == postId) return c;
    }
    return null;
  }

  Future<void> _change(String id, Conversation Function(Conversation) f) =>
      _save([for (final c in state) c.id == id ? f(c) : c]);

  Message _system(String text) => Message(
    id: newId('m_'),
    senderId: 'system',
    text: text,
    createdAt: DateTime.now(),
    isSystem: true,
  );

  /// Returns the id of the DM with [other], creating it if needed.
  Future<String> dmWith(String me, String other) async {
    for (final c in state) {
      if (!c.isGroup &&
          c.memberIds.length == 2 &&
          c.memberIds.contains(me) &&
          c.memberIds.contains(other)) {
        return c.id;
      }
    }
    final c = Conversation(
      id: newId('conv_'),
      type: 'dm',
      memberIds: [me, other],
    );
    await _save([...state, c]);
    return c.id;
  }

  Future<String> ensureGroup(Post post) async {
    final existing = groupFor(post.id);
    if (existing != null) return existing.id;
    final author = ref.read(usersProvider.notifier).byId(post.authorId);
    final c = Conversation(
      id: 'conv_g_${post.id}',
      type: 'group',
      memberIds: List<String>.from(post.memberIds),
      sourcePostId: post.id,
      title: post.title,
      messages: [
        _system('${author?.nickname ?? 'Someone'} started this meetup'),
      ],
    );
    await _save([...state, c]);
    return c.id;
  }

  Future<void> addMember(Post post, UserProfile user) async {
    final id = await ensureGroup(post);
    await _change(
      id,
      (c) => c.copyWith(
        memberIds: c.memberIds.contains(user.id)
            ? c.memberIds
            : [...c.memberIds, user.id],
        messages: [
          ...c.messages,
          _system('${user.nickname} is in: ${post.title ?? 'this meetup'}'),
        ],
      ),
    );
  }

  Future<void> removeMember(
    String postId,
    UserProfile user, {
    bool announce = true,
  }) async {
    final c = groupFor(postId);
    if (c == null) return;
    await _change(
      c.id,
      (x) => x.copyWith(
        memberIds: x.memberIds.where((e) => e != user.id).toList(),
        messages: announce
            ? [...x.messages, _system('${user.nickname} left')]
            : x.messages
                  .where(
                    (m) =>
                        !(m.isSystem &&
                            m.text.startsWith('${user.nickname} is in')),
                  )
                  .toList(),
      ),
    );
  }

  Future<void> systemMessage(String convId, String text) => _change(
    convId,
    (c) => c.copyWith(messages: [...c.messages, _system(text)]),
  );

  Future<void> send(String convId, String senderId, String text) async {
    final c = byId(convId);
    if (c == null || c.status == 'blocked') return;
    await _change(
      convId,
      (x) => x.copyWith(
        messages: [
          ...x.messages,
          Message(
            id: newId('m_'),
            senderId: senderId,
            text: text,
            createdAt: DateTime.now(),
          ),
        ],
      ),
    );
    _mockReply(convId, senderId);
  }

  // MOCK: neighbours reply with canned messages (chat is local and simulated).
  void _mockReply(String convId, String me) {
    Future.delayed(const Duration(milliseconds: 1800), () async {
      try {
        final c = byId(convId);
        if (c == null || c.status == 'blocked') return;
        final others = c.memberIds.where((e) => e != me).toList();
        if (others.isEmpty) return;
        final from = others[_rng.nextInt(others.length)];
        final lines = c.isGroup ? _cannedGroup : _cannedDm;
        await _change(
          convId,
          (x) => x.copyWith(
            messages: [
              ...x.messages,
              Message(
                id: newId('m_'),
                senderId: from,
                text: lines[_rng.nextInt(lines.length)],
                createdAt: DateTime.now(),
              ),
            ],
          ),
        );
      } catch (_) {}
    });
  }

  Future<void> markBlocked(String convId) =>
      _change(convId, (c) => c.copyWith(status: 'blocked'));
}

final chatProvider = NotifierProvider<ChatNotifier, List<Conversation>>(
  ChatNotifier.new,
);

// ------------------------------------------------------------- challenges

class ChallengesNotifier extends Notifier<List<Challenge>> {
  @override
  List<Challenge> build() => ref.read(challengeRepoProvider).load();

  Future<void> _save(List<Challenge> next) async {
    state = next;
    await ref.read(challengeRepoProvider).save(next);
  }

  Future<void> _change(String id, Challenge Function(Challenge) f) =>
      _save([for (final c in state) c.id == id ? f(c) : c]);

  Future<void> join(String id, String userId) => _change(
    id,
    (c) => c.participantIds.contains(userId)
        ? c
        : c.copyWith(participantIds: [...c.participantIds, userId]),
  );

  /// One check-in per day. Returns false if already checked in today.
  Future<bool> checkIn(String id, String userId, int amount) async {
    final today = ymd(DateTime.now());
    final c = state.firstWhere((e) => e.id == id);
    if (c.checkedInOn(userId, today)) return false;
    await _change(
      id,
      (x) => x.copyWith(
        participantIds: x.participantIds.contains(userId)
            ? x.participantIds
            : [...x.participantIds, userId],
        checkIns: [
          ...x.checkIns,
          CheckIn(userId: userId, amount: amount, date: today),
        ],
      ),
    );
    await ref.read(usersProvider.notifier).addPoints(userId, 10);
    await ref
        .read(pointsProvider.notifier)
        .add(
          userId: userId,
          delta: 10,
          label: 'Check-in: ${c.title}',
          refType: 'checkin',
          refId: id,
        );
    return true;
  }

  // MOCK (demo tool): fills the community total to the target so the
  // "reward unlocked" state can be shown.
  Future<void> fillToTarget(String id) => _change(
    id,
    (c) => c.copyWith(
      seedProgress: c.seedProgress + (c.target - c.progress).clamp(0, 1 << 30),
    ),
  );
}

final challengesProvider =
    NotifierProvider<ChallengesNotifier, List<Challenge>>(
      ChallengesNotifier.new,
    );

/// Active challenges of the current user's community, closest to the goal
/// first among those not yet unlocked.
final myChallengesProvider = Provider<List<Challenge>>((ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  final now = DateTime.now();
  final list = ref
      .watch(challengesProvider)
      .where((c) => c.communityId == me.communityId && c.isActive(now))
      .toList();
  list.sort((a, b) => a.id.compareTo(b.id));
  return list;
});

// ------------------------------------------------------------------ loans

class LoansNotifier extends Notifier<List<EquipmentLoan>> {
  @override
  List<EquipmentLoan> build() => ref.read(loanRepoProvider).load();

  Future<void> _save(List<EquipmentLoan> next) async {
    state = next;
    await ref.read(loanRepoProvider).save(next);
  }

  EquipmentLoan? holderOf(String postId) {
    for (final l in state) {
      if (l.postId == postId && l.holdsItem) return l;
    }
    return null;
  }

  EquipmentLoan? openRequestBy(String postId, String userId) {
    for (final l in state) {
      if (l.postId == postId && l.borrowerId == userId && l.isOpen) return l;
    }
    return null;
  }

  /// Creates a request and a system message in the DM with the owner.
  Future<EquipmentLoan> request(Post post, String borrowerId) async {
    final loan = EquipmentLoan(
      id: newId('loan_'),
      postId: post.id,
      ownerId: post.authorId,
      borrowerId: borrowerId,
      requestedAt: DateTime.now(),
    );
    await _save([...state, loan]);
    final chat = ref.read(chatProvider.notifier);
    final convId = await chat.dmWith(borrowerId, post.authorId);
    final borrower = ref.read(usersProvider.notifier).byId(borrowerId);
    await chat.systemMessage(
      convId,
      '${borrower?.nickname ?? 'A neighbour'} would like to borrow: ${post.equipmentItem ?? 'your item'}',
    );
    // MOCK: seeded owners approve a few seconds later.
    if (borrowerId == ref.read(sessionProvider)) {
      Future.delayed(const Duration(seconds: 4), () async {
        try {
          final current = state.where((l) => l.id == loan.id).firstOrNull;
          if (current == null || current.status != LoanStatus.requested) return;
          await setStatus(loan.id, LoanStatus.approved);
          final owner = ref.read(usersProvider.notifier).byId(post.authorId);
          await chat.systemMessage(
            convId,
            '${owner?.nickname ?? 'The owner'} approved your request. Agree a pick-up time here.',
          );
        } catch (_) {}
      });
    }
    return loan;
  }

  Future<void> setStatus(String loanId, LoanStatus next) => _save([
    for (final l in state)
      l.id == loanId ? l.withStatus(next, DateTime.now()) : l,
  ]);
}

final loansProvider = NotifierProvider<LoansNotifier, List<EquipmentLoan>>(
  LoansNotifier.new,
);

// ----------------------------------------------------------------- points

class PointsNotifier extends Notifier<List<PointsEntry>> {
  @override
  List<PointsEntry> build() => ref.read(pointsRepoProvider).load();

  Future<void> _save(List<PointsEntry> next) async {
    state = next;
    await ref.read(pointsRepoProvider).save(next);
  }

  Future<void> add({
    required String userId,
    required int delta,
    required String label,
    String? refType,
    String? refId,
  }) => _save([
    ...state,
    PointsEntry(
      id: newId('pt_'),
      userId: userId,
      delta: delta,
      label: label,
      at: DateTime.now(),
      refType: refType,
      refId: refId,
    ),
  ]);

  /// Removes entries made for one thing, for example when a join is undone.
  Future<void> removeRef(String userId, String refType, String refId) => _save(
    state
        .where(
          (e) =>
              !(e.userId == userId && e.refType == refType && e.refId == refId),
        )
        .toList(),
  );
}

final pointsProvider = NotifierProvider<PointsNotifier, List<PointsEntry>>(
  PointsNotifier.new,
);

/// The current user's points history, newest first.
final myPointsHistoryProvider = Provider<List<PointsEntry>>((ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  final list =
      ref.watch(pointsProvider).where((e) => e.userId == me.id).toList()
        ..sort((a, b) => b.at.compareTo(a.at));
  return list;
});

// ------------------------------------------------------------------- logs

class LogsNotifier extends Notifier<List<RecommendationLog>> {
  @override
  List<RecommendationLog> build() => ref.read(logRepoProvider).load();

  Future<void> add(RecommendationLog log) async {
    state = [...state, log];
    await ref.read(logRepoProvider).save(state);
  }

  Future<void> addAction(String logId, Map<String, dynamic> action) async {
    state = [for (final l in state) l.id == logId ? l.withAction(action) : l];
    await ref.read(logRepoProvider).save(state);
  }
}

final logsProvider = NotifierProvider<LogsNotifier, List<RecommendationLog>>(
  LogsNotifier.new,
);

// ------------------------------------------------------------- feed state

/// Top tabs of the home feed. Add new values here to add a tab.
enum FeedFilter {
  forYou('For You'),
  equipment('Equipment'),
  meetup('Meetup');

  const FeedFilter(this.label);
  final String label;
}

class FeedFilterNotifier extends Notifier<FeedFilter> {
  @override
  FeedFilter build() => FeedFilter.forYou;
  void set(FeedFilter f) => state = f;
}

final feedFilterProvider = NotifierProvider<FeedFilterNotifier, FeedFilter>(
  FeedFilterNotifier.new,
);

/// The two sides of the Equipment tab.
enum EquipmentSide {
  lending('Available'),
  requests('Requests');

  const EquipmentSide(this.label);
  final String label;
}

class EquipmentSideNotifier extends Notifier<EquipmentSide> {
  @override
  EquipmentSide build() => EquipmentSide.lending;
  void set(EquipmentSide s) => state = s;
}

final equipmentSideProvider =
    NotifierProvider<EquipmentSideNotifier, EquipmentSide>(
      EquipmentSideNotifier.new,
    );

/// How many days of posts the feed shows (starts at 7, +7 per tap).
class FeedWindowNotifier extends Notifier<int> {
  @override
  int build() => 7;
  void more() => state += 7;
  void reset() => state = 7;
}

final feedWindowProvider = NotifierProvider<FeedWindowNotifier, int>(
  FeedWindowNotifier.new,
);

class FeedData {
  const FeedData(this.posts, this.hasOlder);
  final List<Post> posts;
  final bool hasOlder;
}

/// Posts from the user's own community for one tab, inside the date window,
/// newest first. Upcoming meetups always stay visible.
final feedProvider = Provider.family<FeedData, FeedFilter>((ref, filter) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const FeedData([], false);
  final days = ref.watch(feedWindowProvider);
  final now = DateTime.now();
  final cutoff = now.subtract(Duration(days: days));

  bool matches(Post p) {
    switch (filter) {
      case FeedFilter.forYou:
        return p.type != PostType.challenge;
      case FeedFilter.equipment:
        return p.type == PostType.equipment;
      case FeedFilter.meetup:
        return p.type == PostType.meetup;
    }
  }

  final mine = ref.watch(postsProvider).where((p) {
    if (p.communityId != me.communityId) return false;
    if (me.blockedUserIds.contains(p.authorId)) return false;
    return matches(p);
  }).toList();

  final visible = <Post>[];
  var older = false;
  for (final p in mine) {
    final upcoming = p.isMeetup && p.isUpcoming(now);
    if (upcoming || p.createdAt.isAfter(cutoff)) {
      visible.add(p);
    } else {
      older = true;
    }
  }
  visible.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return FeedData(visible, older);
});

// ------------------------------------------------------- people suggestions

final suggestionsProvider = Provider<List<PersonSuggestion>>((ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.watch(peopleMatcherProvider).suggest(me, ref.watch(usersProvider));
});

// ---------------------------------------------------------------- utility

/// Re-reads everything from storage after a reset or reseed.
void invalidateAllData(Ref ref) {
  ref.invalidate(sessionProvider);
  ref.invalidate(usersProvider);
  ref.invalidate(postsProvider);
  ref.invalidate(chatProvider);
  ref.invalidate(challengesProvider);
  ref.invalidate(loansProvider);
  ref.invalidate(logsProvider);
  ref.invalidate(pointsProvider);
  ref.invalidate(feedFilterProvider);
  ref.invalidate(equipmentSideProvider);
  ref.invalidate(feedWindowProvider);
}

final resetDemoDataProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(seedLoaderProvider).reset();
    invalidateAllData(ref);
  };
});

/// Number of distinct neighbours the user attended past meetups with.
final neighboursMetProvider = Provider<int>((ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return 0;
  final now = DateTime.now();
  final met = <String>{};
  for (final p in ref.watch(postsProvider)) {
    if (!p.isMeetup || p.startsAt == null || p.startsAt!.isAfter(now)) continue;
    if (now.difference(p.startsAt!).inDays > 30) continue;
    if (!p.memberIds.contains(me.id)) continue;
    met.addAll(p.memberIds.where((e) => e != me.id));
  }
  return met.length;
});

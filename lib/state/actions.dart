import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/equipment_loan.dart';
import '../core/models/post.dart';
import '../core/models/recommendation_log.dart';
import '../core/utils/ids.dart';
import '../services/people_matcher.dart';
import '../widgets/ui_helpers.dart';
import 'app_state.dart';
import 'core_providers.dart';

/// Multi-step user actions that touch several notifiers. Kept out of widgets
/// so the same logic serves the feed, detail pages and the assistant.
class AppActions {
  AppActions(this._ref);

  final Ref _ref;

  static const joinPoints = 20;

  /// "I'm in": joins immediately, adds the user to the group chat and shows an
  /// Undo snackbar.
  Future<void> joinMeetup(Post post) async {
    final me = _ref.read(currentUserProvider);
    if (me == null) return;
    final posts = _ref.read(postsProvider.notifier);
    if (post.isFull) {
      showSnack('This meetup is full.');
      return;
    }
    final ok = await posts.join(post.id, me.id);
    if (!ok) return;
    final fresh = posts.byId(post.id)!;
    await _ref.read(chatProvider.notifier).addMember(fresh, me);

    var awarded = false;
    if (!me.joinAwardIds.contains(post.id)) {
      await _ref.read(usersProvider.notifier).update(
            me.id,
            (u) => u.copyWith(
              points: u.points + joinPoints,
              joinAwardIds: [...u.joinAwardIds, post.id],
            ),
          );
      awarded = true;
      await _ref.read(pointsProvider.notifier).add(
            userId: me.id,
            delta: joinPoints,
            label: 'Joined: ${fresh.title ?? 'a meetup'}',
            refType: 'join',
            refId: post.id,
          );
    }
    showSnack(
      "You're in${awarded ? ' (+$joinPoints points)' : ''}",
      actionLabel: 'Undo',
      onAction: () => undoJoin(post, awarded),
    );
  }

  Future<void> undoJoin(Post post, bool awarded) async {
    final me = _ref.read(currentUserProvider);
    if (me == null) return;
    await _ref.read(postsProvider.notifier).leave(post.id, me.id);
    await _ref
        .read(chatProvider.notifier)
        .removeMember(post.id, me, announce: false);
    if (awarded) {
      await _ref.read(pointsProvider.notifier).removeRef(me.id, 'join', post.id);
      await _ref.read(usersProvider.notifier).update(
            me.id,
            (u) => u.copyWith(
              points: (u.points - joinPoints).clamp(0, 1 << 30),
              joinAwardIds: u.joinAwardIds.where((e) => e != post.id).toList(),
            ),
          );
    }
  }

  Future<void> leaveMeetup(Post post) async {
    final me = _ref.read(currentUserProvider);
    if (me == null) return;
    await _ref.read(postsProvider.notifier).leave(post.id, me.id);
    await _ref.read(chatProvider.notifier).removeMember(post.id, me);
    showSnack('You left this meetup.');
  }

  /// Starts (or reuses) a DM and returns its id.
  Future<String?> startDm(String otherId) async {
    final me = _ref.read(currentUserProvider);
    if (me == null) return null;
    return _ref.read(chatProvider.notifier).dmWith(me.id, otherId);
  }

  /// Borrow: creates a loan request and a DM with the owner.
  /// Returns the DM id, or null if there is nothing to do.
  Future<String?> borrow(Post post) async {
    final me = _ref.read(currentUserProvider);
    if (me == null) return null;
    final loans = _ref.read(loansProvider.notifier);
    if (loans.holderOf(post.id) != null) {
      showSnack('This item is on loan right now.');
      return null;
    }
    if (loans.openRequestBy(post.id, me.id) == null) {
      await loans.request(post, me.id);
      showSnack('Request sent to the owner.');
    }
    return _ref.read(chatProvider.notifier).dmWith(me.id, post.authorId);
  }

  Future<void> setLoanStatus(String loanId, LoanStatus s) =>
      _ref.read(loansProvider.notifier).setStatus(loanId, s);

  /// Message from a neighbour's profile page. If the person is one the app
  /// would suggest, the action is logged for later weight calibration.
  Future<String?> messageNeighbour(String otherId) async {
    final me = _ref.read(currentUserProvider);
    final other = _ref.read(usersProvider.notifier).byId(otherId);
    if (me == null || other == null) return null;
    final s = _ref.read(peopleMatcherProvider).scorePair(me, other);
    if (s != null) {
      await _ref.read(logsProvider.notifier).add(RecommendationLog(
            id: newId('log_'),
            userId: me.id,
            kind: 'person',
            results: [
              {'userId': other.id, 'score': s.score, 'factors': s.fits}
            ],
            actions: [
              {'userId': other.id, 'action': 'messaged', 'at': DateTime.now().toIso8601String()}
            ],
            createdAt: DateTime.now(),
          ));
    }
    return startDm(otherId);
  }

  Future<void> dismissSuggestion(PersonSuggestion s) async {
    final me = _ref.read(currentUserProvider);
    if (me == null) return;
    await _ref.read(usersProvider.notifier).dismissSuggestion(me.id, s.user.id);
    await _ref.read(logsProvider.notifier).add(RecommendationLog(
          id: newId('log_'),
          userId: me.id,
          kind: 'person',
          results: [
            {'userId': s.user.id, 'score': s.score, 'factors': s.fits}
          ],
          actions: [
            {'userId': s.user.id, 'action': 'dismissed', 'at': DateTime.now().toIso8601String()}
          ],
          createdAt: DateTime.now(),
        ));
  }
}

final appActionsProvider = Provider<AppActions>((ref) => AppActions(ref));

import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourfit/config/matching_config.dart';
import 'package:neighbourfit/core/models/enums.dart';
import 'package:neighbourfit/core/models/reference_models.dart';
import 'package:neighbourfit/core/models/user_profile.dart';
import 'package:neighbourfit/services/people_matcher.dart';

void main() {
  final now = DateTime(2026, 10, 16);
  const ref = ReferenceData(
    communities: [
      Community(id: 'c1', name: 'One', lat: 3.1000, lng: 101.6000),
      Community(id: 'c2', name: 'Two', lat: 3.1080, lng: 101.6090),
    ],
    locations: [],
    vouchers: [],
    residentCodes: [],
  );
  final matcher = PeopleMatcher(MatchingConfig.defaults(), ref);

  UserProfile u(
    String id, {
    String community = 'c1',
    List<Sport> sports = const [Sport.running],
    List<TimeSlot> slots = const [TimeSlot.morning, TimeSlot.evening],
    AgeGroup age = AgeGroup.g18_29,
    Level level = Level.beginner,
    List<String> langs = const ['en'],
    String agePref = 'same',
    Map<String, FieldVisibility>? vis,
  }) =>
      UserProfile(
        id: id,
        nickname: id,
        communityId: community,
        sports: sports,
        timeSlots: slots,
        ageGroup: age,
        level: level,
        languages: langs,
        agePref: agePref,
        visibility: vis ??
            const {
              'ageGroup': FieldVisibility.community,
              'gender': FieldVisibility.onlyMe,
              'level': FieldVisibility.community,
              'timeSlots': FieldVisibility.community,
            },
        createdAt: now,
      );

  test('identical profile in the same community scores 100', () {
    final s = matcher.scorePair(u('me'), u('a'))!;
    expect(s.score, closeTo(100, 1e-6));
    expect(s.reasons, isNotEmpty);
    expect(s.reasons.length, lessThanOrEqualTo(2));
  });

  test('worked example: half the time slots overlap', () {
    final me = u('me', slots: const [TimeSlot.morning, TimeSlot.weekend], langs: const ['en', 'zh']);
    final other = u('a', langs: const ['ms', 'en']);
    // sport 35 + time 0.5*20 + age 20 + distance 15 + level/lang 10 = 90
    expect(matcher.scorePair(me, other)!.score, closeTo(90, 1e-6));
  });

  test('age factor is dropped when agePref is any; weights renormalise', () {
    final me = u('me', agePref: 'any');
    final far = u('a', age: AgeGroup.g60plus);
    final s = matcher.scorePair(me, far)!;
    expect(s.fits.containsKey('age'), isFalse);
    expect(s.score, closeTo(100, 1e-6));
  });

  test('age factor is dropped when the other hides their age group', () {
    final me = u('me');
    final hidden = u('a',
        age: AgeGroup.g60plus,
        vis: const {
          'ageGroup': FieldVisibility.onlyMe,
          'gender': FieldVisibility.onlyMe,
          'level': FieldVisibility.community,
          'timeSlots': FieldVisibility.community,
        });
    expect(matcher.scorePair(me, hidden)!.fits.containsKey('age'), isFalse);
  });

  test('similar exercise ranks above similar age only', () {
    final me = u('me');
    final sameSport = u('a', age: AgeGroup.g50_59);
    final sameAgeOnly = u('b', sports: const [Sport.badminton]);
    final list = matcher.suggest(me, [sameAgeOnly, sameSport]);
    expect(list.first.user.id, 'a');
  });

  group('hard filters', () {
    test('self, blocked either way and dismissed are excluded', () {
      final me = u('me');
      expect(matcher.scorePair(me, me), isNull);
      expect(matcher.scorePair(me.copyWith(blockedUserIds: ['a']), u('a')), isNull);
      expect(matcher.scorePair(me, u('a').copyWith(blockedUserIds: ['me'])), isNull);
      expect(matcher.scorePair(me.copyWith(dismissedSuggestionIds: ['a']), u('a')), isNull);
    });

    test('score below the minimum is not suggested', () {
      final me = u('me', slots: const [TimeSlot.morning], agePref: 'same');
      final poor = u('a',
          community: 'c2',
          sports: const [Sport.badminton],
          slots: const [TimeSlot.evening],
          age: AgeGroup.g60plus,
          level: Level.advanced,
          langs: const ['ta']);
      expect(matcher.suggest(me, [poor]), isEmpty);
    });

    test('returns at most peopleMax suggestions', () {
      final me = u('me');
      final many = [for (var i = 0; i < 12; i++) u('x$i')];
      expect(matcher.suggest(me, many).length, 5);
    });
  });
}

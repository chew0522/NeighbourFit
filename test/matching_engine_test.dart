import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourfit/config/matching_config.dart';
import 'package:neighbourfit/core/models/enums.dart';
import 'package:neighbourfit/core/models/equipment_loan.dart';
import 'package:neighbourfit/core/models/parsed_query.dart';
import 'package:neighbourfit/core/models/post.dart';
import 'package:neighbourfit/core/models/reference_models.dart';
import 'package:neighbourfit/core/models/user_profile.dart';
import 'package:neighbourfit/services/matching_engine.dart';

void main() {
  final cfg = MatchingConfig.defaults();

  group('scoreActivity (worked example, docs/MATCHING.md section 4)', () {
    const ctx = ActivityContext(
      wantedSport: Sport.running,
      wantedSlots: {TimeSlot.morning, TimeSlot.weekend},
      userAge: AgeGroup.g18_29,
      userLevel: Level.beginner,
      userLanguages: {'en', 'zh'},
    );

    test('Aiman scores about 80.8', () {
      const aiman = ActivityFit(
        sport: Sport.running,
        slots: {TimeSlot.morning, TimeSlot.evening},
        km: 0.5,
        ageGroup: AgeGroup.g18_29,
        level: Level.beginner,
        languages: {'ms', 'en'},
      );
      expect(scoreActivity(aiman, ctx, cfg).total, closeTo(80.8, 0.2));
    });

    test('Siti scores about 50.5', () {
      const siti = ActivityFit(
        sport: Sport.walking,
        slots: {TimeSlot.morning},
        km: 2,
        ageGroup: AgeGroup.g30_39,
        level: Level.intermediate,
        languages: {'ms', 'en'},
      );
      expect(scoreActivity(siti, ctx, cfg).total, closeTo(50.5, 0.2));
    });
  });

  group('weights', () {
    test('dynamic weights are renormalised to 100', () {
      final w = dynamicWeights(
        cfg,
        sameGroup: true,
        nearMe: true,
        slotExplicit: true,
      );
      expect(w.values.fold<double>(0, (a, b) => a + b), closeTo(100, 1e-9));
      expect(w['age']! > cfg.weights['age']!, isTrue);
    });

    test('default weights add up to 100', () {
      expect(cfg.weights.values.fold<double>(0, (a, b) => a + b), 100);
    });
  });

  group('fit helpers', () {
    test('age fit: same 1, adjacent 0.5, further 0', () {
      expect(ageFit(AgeGroup.g18_29, AgeGroup.g18_29), 1);
      expect(ageFit(AgeGroup.g18_29, AgeGroup.g30_39), 0.5);
      expect(ageFit(AgeGroup.g18_29, AgeGroup.g40_49), 0);
    });

    test('sport fit: same 1, related 0.5, different 0', () {
      expect(cfg.sportFit(Sport.running, Sport.running), 1);
      expect(cfg.sportFit(Sport.running, Sport.walking), 0.5);
      expect(cfg.sportFit(Sport.walking, Sport.running), 0.5);
      expect(cfg.sportFit(Sport.running, Sport.badminton), 0);
    });
  });

  group('MatchingEngine hard filters', () {
    final now = DateTime(2026, 10, 16, 10); // Friday
    const ref = ReferenceData(
      communities: [Community(id: 'c1', name: 'One', lat: 3.1, lng: 101.6)],
      locations: [
        PresetLocation(
          id: 'l1',
          name: 'Park',
          communityId: 'c1',
          lat: 3.1,
          lng: 101.6,
        ),
      ],
      vouchers: [],
      residentCodes: [],
    );
    UserProfile user(String id, {Gender g = Gender.female}) => UserProfile(
      id: id,
      nickname: id,
      communityId: 'c1',
      gender: g,
      sports: const [Sport.running],
      timeSlots: const [TimeSlot.morning],
      visibility: const {
        'ageGroup': FieldVisibility.everyone,
        'gender': FieldVisibility.everyone,
        'level': FieldVisibility.everyone,
        'timeSlots': FieldVisibility.everyone,
      },
      createdAt: now,
    );
    Post meetup(
      String id,
      String author,
      DateTime start, {
      int? cap,
      List<String> members = const [],
    }) => Post(
      id: id,
      type: PostType.meetup,
      authorId: author,
      communityId: 'c1',
      locationId: 'l1',
      startsAt: start,
      sport: Sport.running,
      level: Level.beginner,
      capacity: cap,
      memberIds: members.isEmpty ? [author] : members,
      createdAt: now,
    );

    EngineData data(
      UserProfile me,
      List<UserProfile> users,
      List<Post> posts,
    ) => EngineData(
      me: me,
      users: users,
      posts: posts,
      challenges: const [],
      loans: const <EquipmentLoan>[],
      ref: ref,
      now: now,
    );

    final engine = MatchingEngine(cfg);
    final tomorrowMorning = DateTime(2026, 10, 17, 6, 30);

    test('excludes full, past, own and already-joined meetups', () {
      final me = user('me');
      final a = user('a');
      final posts = [
        meetup('ok', 'a', tomorrowMorning),
        meetup('full', 'a', tomorrowMorning, cap: 1),
        meetup('past', 'a', DateTime(2026, 10, 15, 6)),
        meetup('own', 'me', tomorrowMorning),
        meetup('joined', 'a', tomorrowMorning, members: ['a', 'me']),
      ];
      final r = engine.recommend(const ParsedQuery(), data(me, [me, a], posts));
      expect(r.map((e) => e.post!.id), ['ok']);
    });

    test('date filter keeps only that day', () {
      final me = user('me');
      final a = user('a');
      final posts = [
        meetup('tomorrow', 'a', tomorrowMorning),
        meetup('later', 'a', DateTime(2026, 10, 19, 6, 30)),
      ];
      final r = engine.recommend(
        ParsedQuery(date: DateTime(2026, 10, 17)),
        data(me, [me, a], posts),
      );
      expect(r.map((e) => e.post!.id), ['tomorrow']);
    });

    test('time slot filter excludes other parts of the day', () {
      final me = user('me');
      final a = user('a');
      final posts = [
        meetup('am', 'a', tomorrowMorning),
        meetup('pm', 'a', DateTime(2026, 10, 17, 19, 30)),
      ];
      final r = engine.recommend(
        const ParsedQuery(timeSlot: TimeSlot.morning),
        data(me, [me, a], posts),
      );
      expect(r.map((e) => e.post!.id), ['am']);
    });

    test('women-only needs a disclosed female organiser', () {
      final me = user('me');
      final f = user('f');
      final m = user('m', g: Gender.male);
      final posts = [
        meetup('byF', 'f', tomorrowMorning),
        meetup('byM', 'm', tomorrowMorning),
      ];
      final r = engine.recommend(
        const ParsedQuery(genderFilter: 'women_only'),
        data(me, [me, f, m], posts),
      );
      expect(r.map((e) => e.post!.id), ['byF']);
    });

    test('blocked organiser is excluded', () {
      final me = user('me').copyWith(blockedUserIds: ['a']);
      final a = user('a');
      final r = engine.recommend(
        const ParsedQuery(),
        data(me, [me, a], [meetup('x', 'a', tomorrowMorning)]),
      );
      expect(r, isEmpty);
    });

    test('equipment search skips requests', () {
      final me = user('me');
      final a = user('a');
      Post equipment(String id, {required bool request}) => Post(
        id: id,
        type: PostType.equipment,
        authorId: 'a',
        communityId: 'c1',
        equipmentItem: 'Yoga mat',
        isRequest: request,
        createdAt: now,
      );
      final r = engine.recommend(
        const ParsedQuery(
          intent: QueryIntent.findEquipment,
          equipmentItem: 'yoga mat',
        ),
        data(
          me,
          [me, a],
          [equipment('lend', request: false), equipment('ask', request: true)],
        ),
      );
      expect(r.map((e) => e.post!.id), ['lend']);
    });

    test('a request keeps its flag and offer through json', () {
      final p = Post(
        id: 'r',
        type: PostType.equipment,
        authorId: 'a',
        communityId: 'c1',
        equipmentItem: 'Foam roller',
        isRequest: true,
        startsAt: now,
        createdAt: now,
      ).copyWith(offeredBy: 'b');
      final back = Post.fromJson(p.toJson());
      expect(back.isRequest, isTrue);
      expect(back.offeredBy, 'b');
      expect(back.startsAt, now);
    });
  });
}

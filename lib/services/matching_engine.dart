import '../config/matching_config.dart';
import '../core/models/challenge.dart';
import '../core/models/enums.dart';
import '../core/models/equipment_loan.dart';
import '../core/models/parsed_query.dart';
import '../core/models/post.dart';
import '../core/models/reference_models.dart';
import '../core/models/user_profile.dart';
import '../core/utils/geo.dart';
import '../core/utils/time_utils.dart';

/// Attributes of one candidate meetup, already reduced to scoring inputs.
class ActivityFit {
  const ActivityFit({
    required this.sport,
    required this.slots,
    required this.km,
    this.ageGroup,
    this.level,
    this.languages = const {},
  });

  final Sport sport;
  final Set<TimeSlot> slots;
  final double km;
  final AgeGroup? ageGroup;
  final Level? level;
  final Set<String> languages;
}

/// What the user asked for plus the parts of their profile used for scoring.
class ActivityContext {
  const ActivityContext({
    this.wantedSport,
    this.profileSports = const {},
    this.wantedSlots = const {},
    this.slotExplicit = false,
    this.userAge,
    this.userLevel,
    this.userLanguages = const {},
    this.sameGroup = false,
    this.nearMe = false,
  });

  final Sport? wantedSport;
  final Set<Sport> profileSports;
  final Set<TimeSlot> wantedSlots;
  final bool slotExplicit;
  final AgeGroup? userAge;
  final Level? userLevel;
  final Set<String> userLanguages;
  final bool sameGroup;
  final bool nearMe;
}

class ScoreBreakdown {
  const ScoreBreakdown(this.total, this.fits, this.weights);

  final double total;
  final Map<String, double> fits;
  final Map<String, double> weights;

  double contribution(String key) => (fits[key] ?? 0) * (weights[key] ?? 0);
}

/// Scales weights so they add up to 100.
Map<String, double> normaliseWeights(Map<String, double> w) {
  final sum = w.values.fold<double>(0, (a, b) => a + b);
  if (sum <= 0) return w;
  return w.map((k, v) => MapEntry(k, v * 100 / sum));
}

Map<String, double> dynamicWeights(
  MatchingConfig cfg, {
  bool sameGroup = false,
  bool nearMe = false,
  bool slotExplicit = false,
}) {
  final w = Map<String, double>.from(cfg.weights);
  if (sameGroup) w['age'] = cfg.sameGroupAgeWeight;
  if (nearMe) w['distance'] = cfg.nearMeDistanceWeight;
  if (slotExplicit) w['time'] = cfg.timeStatedWeight;
  return normaliseWeights(w);
}

double ageFit(AgeGroup? a, AgeGroup? b) {
  if (a == null || b == null) return 0.5;
  final d = (a.index - b.index).abs();
  return d == 0 ? 1 : (d == 1 ? 0.5 : 0);
}

double levelFit(Level? a, Level? b) {
  if (a == null || b == null) return 1;
  final d = (a.index - b.index).abs();
  return d == 0 ? 1 : (d == 1 ? 0.5 : 0);
}

double languageFit(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0.5;
  return a.intersection(b).isNotEmpty ? 1 : 0;
}

/// Weighted sum 0-100 for one candidate. Pure function so it can be unit tested
/// against the worked example in docs/MATCHING.md section 4.
ScoreBreakdown scoreActivity(
  ActivityFit c,
  ActivityContext x,
  MatchingConfig cfg,
) {
  double sport;
  if (x.wantedSport != null) {
    sport = cfg.sportFit(x.wantedSport!, c.sport);
  } else if (x.profileSports.isNotEmpty) {
    sport = x.profileSports
        .map((s) => cfg.sportFit(s, c.sport))
        .reduce((a, b) => a > b ? a : b);
  } else {
    sport = 0.5;
  }

  double time;
  if (x.wantedSlots.isEmpty) {
    time = 0.5;
  } else {
    time = c.slots.intersection(x.wantedSlots).length / x.wantedSlots.length;
  }

  final distance = 1 / (1 + c.km);
  final age = x.userAge == null ? 0.5 : ageFit(x.userAge, c.ageGroup);
  final levelLang = (levelFit(x.userLevel, c.level) +
          languageFit(x.userLanguages, c.languages)) /
      2;

  final fits = {
    'sport': sport,
    'time': time,
    'distance': distance,
    'age': age,
    'levelLanguage': levelLang,
  };
  final weights = dynamicWeights(
    cfg,
    sameGroup: x.sameGroup,
    nearMe: x.nearMe,
    slotExplicit: x.slotExplicit,
  );
  var total = 0.0;
  for (final k in MatchingConfig.keys) {
    total += (fits[k] ?? 0) * (weights[k] ?? 0);
  }
  return ScoreBreakdown(total, fits, weights);
}

class ScoredResult {
  const ScoredResult({
    this.post,
    this.challenge,
    required this.score,
    this.fits = const {},
    this.facts = const [],
  });

  final Post? post;
  final Challenge? challenge;
  final double score;
  final Map<String, double> fits;

  /// Plain facts behind the score, strongest first. Used for explanations.
  final List<String> facts;
}

class EngineData {
  const EngineData({
    required this.me,
    required this.users,
    required this.posts,
    required this.challenges,
    required this.loans,
    required this.ref,
    required this.now,
  });

  final UserProfile me;
  final List<UserProfile> users;
  final List<Post> posts;
  final List<Challenge> challenges;
  final List<EquipmentLoan> loans;
  final ReferenceData ref;
  final DateTime now;
}

class MatchingEngine {
  const MatchingEngine(this.config);

  final MatchingConfig config;

  List<ScoredResult> recommend(ParsedQuery q, EngineData d, {int limit = 3}) {
    switch (q.intent) {
      case QueryIntent.findActivity:
        return _activities(q, d, limit);
      case QueryIntent.findEquipment:
        return _equipment(q, d, limit);
      case QueryIntent.challengeInfo:
        return d.challenges
            .where((c) => c.isActive(d.now) && c.communityId == d.me.communityId)
            .map((c) => ScoredResult(challenge: c, score: 100 * c.fraction))
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));
      case QueryIntent.other:
        return const [];
    }
  }

  UserProfile? _user(EngineData d, String id) {
    for (final u in d.users) {
      if (u.id == id) return u;
    }
    return null;
  }

  double _kmFromHome(EngineData d, double lat, double lng) {
    final home = d.ref.community(d.me.communityId);
    if (home == null) return 1;
    return haversineKm(home.lat, home.lng, lat, lng);
  }

  List<ScoredResult> _activities(ParsedQuery q, EngineData d, int limit) {
    final me = d.me;
    final weekendDates = upcomingWeekendDates(d.now);
    final results = <ScoredResult>[];

    for (final p in d.posts) {
      if (!p.isMeetup || p.startsAt == null) continue;
      final start = p.startsAt!;
      // Hard filters: can these two people actually meet?
      if (!start.isAfter(d.now)) continue;
      if (p.authorId == me.id || p.memberIds.contains(me.id)) continue;
      if (me.blockedUserIds.contains(p.authorId)) continue;
      final author = _user(d, p.authorId);
      if (author != null && author.blockedUserIds.contains(me.id)) continue;
      if (p.isFull) continue;
      if (q.date != null && !sameDay(start, q.date!)) continue;
      if (q.date == null && q.thisWeekend) {
        if (!weekendDates.any((w) => sameDay(w, start))) continue;
      }
      if (q.timeSlot != null && !slotsFor(start).contains(q.timeSlot)) continue;
      if (q.needsAccessibility &&
          !p.accessibilityFriendly) {
        continue;
      }
      if (q.genderFilter != 'none') {
        final want = q.genderFilter == 'women_only' ? Gender.female : Gender.male;
        if (author == null || !author.isVisible('gender') || author.gender != want) {
          continue;
        }
      }

      final loc = d.ref.location(p.locationId);
      final km = loc == null ? 1.0 : _kmFromHome(d, loc.lat, loc.lng);

      // Age group: most common among members (hidden ages are skipped).
      final counts = <AgeGroup, int>{};
      final langs = <String>{};
      for (final id in p.memberIds) {
        final m = _user(d, id);
        if (m == null) continue;
        langs.addAll(m.languages);
        if (m.isVisible('ageGroup')) {
          counts[m.ageGroup] = (counts[m.ageGroup] ?? 0) + 1;
        }
      }
      AgeGroup? age;
      var best = 0;
      counts.forEach((g, n) {
        if (n > best) {
          best = n;
          age = g;
        }
      });

      final fit = ActivityFit(
        sport: p.sport ?? Sport.other,
        slots: slotsFor(start),
        km: km,
        ageGroup: age,
        level: p.level,
        languages: langs,
      );
      final slotExplicit = q.timeSlot != null;
      final ctx = ActivityContext(
        wantedSport: q.sport,
        profileSports: me.sports.toSet(),
        wantedSlots: slotExplicit ? {q.timeSlot!} : me.timeSlots.toSet(),
        slotExplicit: slotExplicit,
        userAge: me.ageGroup,
        userLevel: q.level ?? me.level,
        userLanguages: me.languages.toSet(),
        sameGroup: q.sameGroupAge,
        nearMe: q.nearMe,
      );
      final s = scoreActivity(fit, ctx, config);
      results.add(ScoredResult(
        post: p,
        score: s.total,
        fits: s.fits,
        facts: _facts(s, q, km, p, age),
      ));
    }

    results.sort((a, b) {
      final c = b.score.compareTo(a.score);
      if (c != 0) return c;
      return a.post!.startsAt!.compareTo(b.post!.startsAt!);
    });
    return results.take(limit).toList();
  }

  List<String> _facts(
    ScoreBreakdown s,
    ParsedQuery q,
    double km,
    Post p,
    AgeGroup? age,
  ) {
    final entries = s.fits.entries.where((e) => e.value >= 0.5).toList()
      ..sort((a, b) => s.contribution(b.key).compareTo(s.contribution(a.key)));
    final out = <String>[];
    for (final e in entries) {
      switch (e.key) {
        case 'sport':
          out.add(e.value >= 1 ? 'same sport' : 'a similar activity');
        case 'time':
          out.add(q.timeSlot != null
              ? '${q.timeSlot!.label.toLowerCase()} slot matches'
              : 'fits your usual times');
        case 'distance':
          out.add('only ${km.toStringAsFixed(1)} km away');
        case 'age':
          out.add(age == null ? 'similar age group' : 'mostly ${age.label} year olds');
        case 'levelLanguage':
          out.add(p.level == null
              ? 'open to all levels'
              : '${p.level!.label.toLowerCase()} level fits');
      }
    }
    if (p.accessibilityFriendly && (q.needsAccessibility)) {
      out.insert(0, 'accessibility-friendly');
    }
    return out.take(3).toList();
  }

  List<ScoredResult> _equipment(ParsedQuery q, EngineData d, int limit) {
    final item = q.equipmentItem?.toLowerCase();
    final tokens = item == null
        ? <String>[]
        : item.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();
    final results = <ScoredResult>[];
    for (final p in d.posts) {
      if (p.type != PostType.equipment) continue;
      if (p.authorId == d.me.id) continue;
      if (d.me.blockedUserIds.contains(p.authorId)) continue;
      if (d.loans.any((l) => l.postId == p.id && l.holdsItem)) continue;
      final name = (p.equipmentItem ?? '').toLowerCase();
      double match = 1;
      if (item != null) {
        final hits = tokens.where((t) => name.contains(t)).length;
        match = name.contains(item) || item.contains(name)
            ? 1
            : (tokens.isEmpty ? 0 : hits / tokens.length);
        if (match == 0) continue;
      }
      final author = _user(d, p.authorId);
      final other = d.ref.community(author?.communityId ?? '');
      final home = d.ref.community(d.me.communityId);
      final km = (other == null || home == null)
          ? 1.0
          : haversineKm(home.lat, home.lng, other.lat, other.lng);
      results.add(ScoredResult(
        post: p,
        score: match * 100 - km,
        facts: [
          if (match >= 1) 'matches what you asked for' else 'partly matches',
          if (km < 0.5) 'in your community' else '${km.toStringAsFixed(1)} km away',
        ],
      ));
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }
}

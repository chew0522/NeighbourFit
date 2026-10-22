import '../config/matching_config.dart';
import '../core/models/constants.dart';
import '../core/models/reference_models.dart';
import '../core/models/user_profile.dart';
import '../core/utils/geo.dart';
import 'matching_engine.dart';

class PersonSuggestion {
  const PersonSuggestion({
    required this.user,
    required this.score,
    required this.reasons,
    required this.fits,
  });

  final UserProfile user;
  final double score;
  final List<String> reasons;
  final Map<String, double> fits;
}

/// "Neighbours you may like": person-to-person suggestions. Similar exercise
/// and similar age count most. Runs on-device with no AI call
/// (see DECISIONS.md section 2.1).
class PeopleMatcher {
  const PeopleMatcher(this.config, this.ref);

  final MatchingConfig config;
  final ReferenceData ref;

  List<PersonSuggestion> suggest(UserProfile me, List<UserProfile> users) {
    final out = <PersonSuggestion>[];
    for (final u in users) {
      final s = scorePair(me, u);
      if (s != null && s.score >= config.peopleMinScore) out.add(s);
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out.take(config.peopleMax).toList();
  }

  /// null = excluded by a hard filter.
  PersonSuggestion? scorePair(UserProfile me, UserProfile other) {
    if (other.id == me.id) return null;
    if (me.blockedUserIds.contains(other.id) ||
        other.blockedUserIds.contains(me.id)) {
      return null;
    }
    if (me.dismissedSuggestionIds.contains(other.id)) return null;
    final hidden =
        !other.isVisible('ageGroup') &&
        !other.isVisible('level') &&
        !other.isVisible('timeSlots');
    if (hidden) return null;

    // Each factor is null when it cannot be computed or the field is hidden;
    // weights are renormalised over the factors that remain.
    final fits = <String, double?>{};

    String? sharedSport;
    var relatedSport = false;
    if (me.sports.isNotEmpty && other.sports.isNotEmpty) {
      var best = 0.0;
      for (final a in me.sports) {
        for (final b in other.sports) {
          final f = config.sportFit(a, b);
          if (f > best) {
            best = f;
            sharedSport = b.label;
            relatedSport = f < 1;
          }
        }
      }
      fits['sport'] = best;
    } else {
      fits['sport'] = null;
    }

    if (other.isVisible('timeSlots') &&
        me.timeSlots.isNotEmpty &&
        other.timeSlots.isNotEmpty) {
      final overlap = me.timeSlots
          .toSet()
          .intersection(other.timeSlots.toSet())
          .length;
      final minLen = me.timeSlots.length < other.timeSlots.length
          ? me.timeSlots.length
          : other.timeSlots.length;
      fits['time'] = overlap / minLen;
    } else {
      fits['time'] = null;
    }

    fits['age'] = (me.agePref == 'any' || !other.isVisible('ageGroup'))
        ? null
        : ageFit(me.ageGroup, other.ageGroup);

    final a = ref.community(me.communityId);
    final b = ref.community(other.communityId);
    fits['distance'] = (a == null || b == null)
        ? null
        : 1 / (1 + haversineKm(a.lat, a.lng, b.lat, b.lng));

    final parts = <double>[];
    if (other.isVisible('level')) parts.add(levelFit(me.level, other.level));
    if (me.languages.isNotEmpty && other.languages.isNotEmpty) {
      parts.add(languageFit(me.languages.toSet(), other.languages.toSet()));
    }
    fits['levelLanguage'] = parts.isEmpty
        ? null
        : parts.reduce((x, y) => x + y) / parts.length;

    final used = {
      for (final k in MatchingConfig.keys)
        if (fits[k] != null) k: config.peopleWeights[k] ?? 0,
    };
    if (used.isEmpty) return null;
    final weights = normaliseWeights(used);
    var score = 0.0;
    final cleanFits = <String, double>{};
    for (final k in used.keys) {
      cleanFits[k] = fits[k]!;
      score += fits[k]! * weights[k]!;
    }

    // Reasons: the two strongest factors that actually fit well.
    final ranked = cleanFits.entries.where((e) => e.value >= 0.5).toList()
      ..sort(
        (x, y) =>
            (y.value * weights[y.key]!).compareTo(x.value * weights[x.key]!),
      );
    final reasons = <String>[];
    for (final e in ranked) {
      switch (e.key) {
        case 'sport':
          reasons.add(
            relatedSport
                ? 'Also into ${sharedSport?.toLowerCase() ?? 'staying active'}'
                : 'Both into ${sharedSport?.toLowerCase() ?? 'the same sport'}',
          );
        case 'time':
          reasons.add('Free at similar times');
        case 'age':
          reasons.add('Similar age group');
        case 'distance':
          reasons.add(
            other.communityId == me.communityId
                ? 'Lives in your community'
                : 'Lives nearby',
          );
        case 'levelLanguage':
          final shared = me.languages.toSet().intersection(
            other.languages.toSet(),
          );
          reasons.add(
            other.isVisible('level') && me.level == other.level
                ? 'Similar level'
                : (shared.isNotEmpty
                      ? 'Also speaks ${languageLabels[shared.first] ?? shared.first}'
                      : 'Similar level'),
          );
      }
      if (reasons.length == 2) break;
    }

    return PersonSuggestion(
      user: other,
      score: score,
      reasons: reasons,
      fits: cleanFits,
    );
  }
}

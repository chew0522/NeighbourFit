import '../core/models/enums.dart';

/// Weights and related-sport table. Loaded from assets/config/matching_config.json.
class MatchingConfig {
  const MatchingConfig({
    required this.weights,
    required this.sameGroupAgeWeight,
    required this.nearMeDistanceWeight,
    required this.timeStatedWeight,
    required this.peopleWeights,
    required this.peopleMinScore,
    required this.peopleMax,
    required this.related,
  });

  static const keys = ['sport', 'time', 'distance', 'age', 'levelLanguage'];

  final Map<String, double> weights;
  final double sameGroupAgeWeight;
  final double nearMeDistanceWeight;
  final double timeStatedWeight;
  final Map<String, double> peopleWeights;
  final double peopleMinScore;
  final int peopleMax;

  /// sport name -> {other sport name -> fit 0..1}
  final Map<String, Map<String, double>> related;

  /// Same sport = 1, related = table value (either direction), else 0.
  double sportFit(Sport a, Sport b) {
    if (a == b) return 1;
    return related[a.name]?[b.name] ?? related[b.name]?[a.name] ?? 0;
  }

  static MatchingConfig defaults() => const MatchingConfig(
    weights: {
      'sport': 30,
      'time': 25,
      'distance': 20,
      'age': 10,
      'levelLanguage': 15,
    },
    sameGroupAgeWeight: 30,
    nearMeDistanceWeight: 35,
    timeStatedWeight: 35,
    peopleWeights: {
      'sport': 35,
      'time': 20,
      'age': 20,
      'distance': 15,
      'levelLanguage': 10,
    },
    peopleMinScore: 30,
    peopleMax: 5,
    related: {
      'running': {'walking': 0.5, 'cycling': 0.25},
      'walking': {'yoga': 0.25},
    },
  );

  factory MatchingConfig.fromJson(Map<String, dynamic> j) {
    Map<String, double> dm(Object? v) => v is Map
        ? v.map((k, x) => MapEntry(k.toString(), (x as num).toDouble()))
        : <String, double>{};
    final dynamicW = (j['dynamic'] as Map?) ?? const {};
    final rel = <String, Map<String, double>>{};
    final raw = j['related'];
    if (raw is Map) {
      raw.forEach((k, v) => rel[k.toString()] = dm(v));
    }
    final d = defaults();
    return MatchingConfig(
      weights: dm(j['weights']).isEmpty ? d.weights : dm(j['weights']),
      sameGroupAgeWeight:
          (dynamicW['sameGroupAge'] as num?)?.toDouble() ??
          d.sameGroupAgeWeight,
      nearMeDistanceWeight:
          (dynamicW['nearMeDistance'] as num?)?.toDouble() ??
          d.nearMeDistanceWeight,
      timeStatedWeight:
          (dynamicW['timeStated'] as num?)?.toDouble() ?? d.timeStatedWeight,
      peopleWeights: dm(j['peopleWeights']).isEmpty
          ? d.peopleWeights
          : dm(j['peopleWeights']),
      peopleMinScore: (j['peopleMinScore'] as num?)?.toDouble() ?? 30,
      peopleMax: (j['peopleMax'] as num?)?.toInt() ?? 5,
      related: rel.isEmpty ? d.related : rel,
    );
  }
}

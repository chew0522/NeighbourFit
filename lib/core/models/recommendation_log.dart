import 'json_utils.dart';

/// Logs what the assistant (or the people suggester) recommended and what the
/// user did next. Used later to calibrate matching weights.
class RecommendationLog {
  const RecommendationLog({
    required this.id,
    required this.userId,
    required this.kind,
    this.query = '',
    this.parsed = const {},
    this.results = const [],
    this.actions = const [],
    required this.createdAt,
  });

  final String id;
  final String userId;

  /// 'activity' or 'person'
  final String kind;
  final String query;
  final Map<String, dynamic> parsed;
  final List<Map<String, dynamic>> results;
  final List<Map<String, dynamic>> actions;
  final DateTime createdAt;

  RecommendationLog withAction(Map<String, dynamic> action) =>
      RecommendationLog(
        id: id,
        userId: userId,
        kind: kind,
        query: query,
        parsed: parsed,
        results: results,
        actions: [...actions, action],
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'kind': kind,
    'query': query,
    'parsed': parsed,
    'results': results,
    'actions': actions,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RecommendationLog.fromJson(Map<String, dynamic> j) =>
      RecommendationLog(
        id: j['id'] as String,
        userId: j['userId'] as String? ?? '',
        kind: j['kind'] as String? ?? 'activity',
        query: j['query'] as String? ?? '',
        parsed: asMap(j['parsed']),
        results: mapList(j['results']),
        actions: mapList(j['actions']),
        createdAt: parseDt(j['createdAt']),
      );
}

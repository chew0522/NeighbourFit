import 'enums.dart';

enum QueryIntent {
  findActivity('find_activity'),
  findEquipment('find_equipment'),
  challengeInfo('challenge_info'),
  other('other');

  const QueryIntent(this.json);
  final String json;

  static QueryIntent parse(Object? v) {
    for (final i in QueryIntent.values) {
      if (i.json == v) return i;
    }
    return QueryIntent.other;
  }
}

/// Structured version of the user's sentence. See docs/MATCHING.md section 2.
class ParsedQuery {
  const ParsedQuery({
    this.intent = QueryIntent.findActivity,
    this.sport,
    this.timeSlot,
    this.date,
    this.thisWeekend = false,
    this.sameGroupAge = false,
    this.genderFilter = 'none',
    this.level,
    this.nearMe = false,
    this.equipmentItem,
  });

  final QueryIntent intent;
  final Sport? sport;
  final TimeSlot? timeSlot;

  /// Date only (time ignored). Never in the past.
  final DateTime? date;
  final bool thisWeekend;
  final bool sameGroupAge;

  /// 'none', 'women_only' or 'men_only'
  final String genderFilter;
  final Level? level;
  final bool nearMe;
  final String? equipmentItem;

  Map<String, dynamic> toJson() => {
    'intent': intent.json,
    'sport': sport?.name,
    'timeSlot': timeSlot?.name,
    'date': date == null
        ? null
        : '${date!.year.toString().padLeft(4, '0')}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
    'dayHint': thisWeekend ? 'this_weekend' : null,
    'agePref': sameGroupAge ? 'same_group' : 'any',
    'genderFilter': genderFilter,
    'level': level?.name,
    'nearMe': nearMe,
    'equipmentItem': equipmentItem,
  };

  /// Validates AI output: unknown values become null / defaults, dates in the
  /// past are ignored, unknown fields are dropped.
  factory ParsedQuery.fromAiJson(Map<String, dynamic> j, DateTime now) {
    DateTime? date;
    final raw = j['date'];
    if (raw is String) {
      final d = DateTime.tryParse(raw);
      if (d != null) {
        final day = DateTime(d.year, d.month, d.day);
        final today = DateTime(now.year, now.month, now.day);
        if (!day.isBefore(today)) date = day;
      }
    }
    final gf = j['genderFilter'];
    final item = j['equipmentItem'];
    return ParsedQuery(
      intent: QueryIntent.parse(j['intent']),
      sport: enumByName(Sport.values, j['sport']),
      timeSlot: enumByName(TimeSlot.values, j['timeSlot']),
      date: date,
      thisWeekend: j['dayHint'] == 'this_weekend',
      sameGroupAge: j['agePref'] == 'same_group',
      genderFilter: (gf == 'women_only' || gf == 'men_only')
          ? gf as String
          : 'none',
      level: enumByName(Level.values, j['level']),
      nearMe: j['nearMe'] == true,
      equipmentItem: item is String && item.trim().isNotEmpty
          ? item.trim()
          : null,
    );
  }
}

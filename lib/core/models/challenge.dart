import 'json_utils.dart';

class CheckIn {
  const CheckIn({
    required this.userId,
    required this.amount,
    required this.date,
  });

  final String userId;
  final int amount;

  /// yyyy-MM-dd
  final String date;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'amount': amount,
    'date': date,
  };

  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
    userId: j['userId'] as String? ?? '',
    amount: (j['amount'] as num?)?.toInt() ?? 0,
    date: j['date'] as String? ?? '',
  );
}

class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.unit,
    required this.target,
    required this.seedProgress,
    required this.startsAt,
    required this.endsAt,
    required this.reward,
    required this.communityId,
    this.kind = 'steps',
    this.quickAmount = 10000,
    this.participantIds = const [],
    this.checkIns = const [],
  });

  final String id;
  final String title;
  final String unit;
  final int target;
  final int seedProgress;
  final DateTime startsAt;
  final DateTime endsAt;
  final String reward;
  final String communityId;

  /// 'steps', 'walk', 'cycle', 'time' or 'swim'. Picks the icon.
  final String kind;

  /// Amount added by the one-tap "I did it today" check-in.
  final int quickAmount;
  final List<String> participantIds;
  final List<CheckIn> checkIns;

  /// Community total: seeded neighbours plus everyone's check-ins.
  int get progress =>
      seedProgress + checkIns.fold<int>(0, (sum, c) => sum + c.amount);

  double get fraction => target == 0 ? 0 : (progress / target).clamp(0, 1);
  bool get unlocked => progress >= target;
  bool isActive(DateTime now) =>
      !now.isBefore(startsAt) && !now.isAfter(endsAt);

  int myContribution(String userId) => checkIns
      .where((c) => c.userId == userId)
      .fold<int>(0, (sum, c) => sum + c.amount);

  bool checkedInOn(String userId, String ymd) =>
      checkIns.any((c) => c.userId == userId && c.date == ymd);

  Challenge copyWith({
    int? seedProgress,
    List<String>? participantIds,
    List<CheckIn>? checkIns,
  }) => Challenge(
    id: id,
    title: title,
    unit: unit,
    target: target,
    seedProgress: seedProgress ?? this.seedProgress,
    startsAt: startsAt,
    endsAt: endsAt,
    reward: reward,
    communityId: communityId,
    kind: kind,
    quickAmount: quickAmount,
    participantIds: participantIds ?? this.participantIds,
    checkIns: checkIns ?? this.checkIns,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'unit': unit,
    'target': target,
    'seedProgress': seedProgress,
    'startsAt': startsAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
    'reward': reward,
    'communityId': communityId,
    'kind': kind,
    'quickAmount': quickAmount,
    'participantIds': participantIds,
    'checkIns': checkIns.map((e) => e.toJson()).toList(),
  };

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    unit: j['unit'] as String? ?? 'steps',
    target: (j['target'] as num?)?.toInt() ?? 1,
    seedProgress: (j['seedProgress'] as num?)?.toInt() ?? 0,
    startsAt: parseDt(j['startsAt']),
    endsAt: parseDt(j['endsAt']),
    reward: j['reward'] as String? ?? '',
    communityId: j['communityId'] as String? ?? 'c_lakeside',
    kind: j['kind'] as String? ?? 'steps',
    quickAmount: (j['quickAmount'] as num?)?.toInt() ?? 10000,
    participantIds: strList(j['participantIds']),
    checkIns: mapList(j['checkIns']).map(CheckIn.fromJson).toList(),
  );
}

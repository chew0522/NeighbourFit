import 'json_utils.dart';

/// One line of a user's points history (earned or spent).
class PointsEntry {
  const PointsEntry({
    required this.id,
    required this.userId,
    required this.delta,
    required this.label,
    required this.at,
    this.refType,
    this.refId,
  });

  final String id;
  final String userId;

  /// Positive when earned, negative when spent.
  final int delta;
  final String label;
  final DateTime at;

  /// What caused it: 'join' (refId = meetup id), 'checkin' (challenge id),
  /// 'redeem' (voucher id) or 'seed'.
  final String? refType;
  final String? refId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'delta': delta,
        'label': label,
        'at': at.toIso8601String(),
        'refType': refType,
        'refId': refId,
      };

  factory PointsEntry.fromJson(Map<String, dynamic> j) => PointsEntry(
        id: j['id'] as String,
        userId: j['userId'] as String? ?? '',
        delta: (j['delta'] as num?)?.toInt() ?? 0,
        label: j['label'] as String? ?? '',
        at: parseDt(j['at']),
        refType: j['refType'] as String?,
        refId: j['refId'] as String?,
      );
}

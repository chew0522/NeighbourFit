import 'enums.dart';
import 'json_utils.dart';

enum LoanStatus { requested, approved, pickedUp, returned, declined, cancelled }

/// A borrow request for an equipment post (see DECISIONS.md 2.2).
class EquipmentLoan {
  const EquipmentLoan({
    required this.id,
    required this.postId,
    required this.ownerId,
    required this.borrowerId,
    this.status = LoanStatus.requested,
    required this.requestedAt,
    this.approvedAt,
    this.pickedUpAt,
    this.returnedAt,
  });

  final String id;
  final String postId;
  final String ownerId;
  final String borrowerId;
  final LoanStatus status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? pickedUpAt;
  final DateTime? returnedAt;

  /// The item is out of circulation while approved or picked up.
  bool get holdsItem =>
      status == LoanStatus.approved || status == LoanStatus.pickedUp;

  bool get isOpen => holdsItem || status == LoanStatus.requested;

  EquipmentLoan withStatus(LoanStatus next, DateTime now) => EquipmentLoan(
        id: id,
        postId: postId,
        ownerId: ownerId,
        borrowerId: borrowerId,
        status: next,
        requestedAt: requestedAt,
        approvedAt: next == LoanStatus.approved ? now : approvedAt,
        pickedUpAt: next == LoanStatus.pickedUp ? now : pickedUpAt,
        returnedAt: next == LoanStatus.returned ? now : returnedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'ownerId': ownerId,
        'borrowerId': borrowerId,
        'status': status.name,
        'requestedAt': requestedAt.toIso8601String(),
        'approvedAt': approvedAt?.toIso8601String(),
        'pickedUpAt': pickedUpAt?.toIso8601String(),
        'returnedAt': returnedAt?.toIso8601String(),
      };

  factory EquipmentLoan.fromJson(Map<String, dynamic> j) => EquipmentLoan(
        id: j['id'] as String,
        postId: j['postId'] as String? ?? '',
        ownerId: j['ownerId'] as String? ?? '',
        borrowerId: j['borrowerId'] as String? ?? '',
        status:
            enumByName(LoanStatus.values, j['status']) ?? LoanStatus.requested,
        requestedAt: parseDt(j['requestedAt']),
        approvedAt: parseDtOrNull(j['approvedAt']),
        pickedUpAt: parseDtOrNull(j['pickedUpAt']),
        returnedAt: parseDtOrNull(j['returnedAt']),
      );
}

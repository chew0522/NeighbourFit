import '../../core/models/challenge.dart';
import '../../core/models/conversation.dart';
import '../../core/models/equipment_loan.dart';
import '../../core/models/points_entry.dart';
import '../../core/models/post.dart';
import '../../core/models/recommendation_log.dart';
import '../../core/models/reference_models.dart';
import '../../core/models/user_profile.dart';

/// Collection-style storage. The UI never touches storage directly: it goes
/// through providers that wrap these interfaces, so a cloud backend can
/// replace the local implementation later.
abstract class Repository<T> {
  List<T> load();
  Future<void> save(List<T> items);
}

abstract class UserRepository implements Repository<UserProfile> {}

abstract class PostRepository implements Repository<Post> {}

abstract class ChatRepository implements Repository<Conversation> {}

abstract class ChallengeRepository implements Repository<Challenge> {}

abstract class EquipmentLoanRepository implements Repository<EquipmentLoan> {}

abstract class PointsRepository implements Repository<PointsEntry> {}

abstract class RecommendationLogRepository
    implements Repository<RecommendationLog> {}

abstract class LocationRepository {
  List<Community> communities();
  List<PresetLocation> locations();
}

abstract class RewardRepository {
  List<Voucher> vouchers();
}

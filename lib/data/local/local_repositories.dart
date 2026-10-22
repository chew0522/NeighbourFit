import '../../core/models/challenge.dart';
import '../../core/models/conversation.dart';
import '../../core/models/equipment_loan.dart';
import '../../core/models/points_entry.dart';
import '../../core/models/post.dart';
import '../../core/models/recommendation_log.dart';
import '../../core/models/reference_models.dart';
import '../../core/models/user_profile.dart';
import '../repositories/repositories.dart';
import 'local_store.dart';

/// Storage keys. Also used by the seed loader.
class StoreKeys {
  static const users = 'nf_users';
  static const posts = 'nf_posts';
  static const conversations = 'nf_conversations';
  static const challenges = 'nf_challenges';
  static const loans = 'nf_loans';
  static const logs = 'nf_logs';
  static const session = 'nf_session_user';
  static const points = 'nf_points';
  static const auth = 'nf_auth';
  static const seedVersion = 'nf_seed_version';
  static const all = [
    users,
    posts,
    conversations,
    challenges,
    loans,
    logs,
    points,
    auth,
  ];
}

class LocalRepository<T> implements Repository<T> {
  LocalRepository(this.store, this.key, this.fromJson, this.toJson);

  final LocalStore store;
  final String key;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  @override
  List<T> load() => store.readList(key).map(fromJson).toList();

  @override
  Future<void> save(List<T> items) =>
      store.writeList(key, items.map(toJson).toList());
}

class LocalUserRepository extends LocalRepository<UserProfile>
    implements UserRepository {
  LocalUserRepository(LocalStore s)
    : super(s, StoreKeys.users, UserProfile.fromJson, (e) => e.toJson());
}

class LocalPostRepository extends LocalRepository<Post>
    implements PostRepository {
  LocalPostRepository(LocalStore s)
    : super(s, StoreKeys.posts, Post.fromJson, (e) => e.toJson());
}

class LocalChatRepository extends LocalRepository<Conversation>
    implements ChatRepository {
  LocalChatRepository(LocalStore s)
    : super(
        s,
        StoreKeys.conversations,
        Conversation.fromJson,
        (e) => e.toJson(),
      );
}

class LocalChallengeRepository extends LocalRepository<Challenge>
    implements ChallengeRepository {
  LocalChallengeRepository(LocalStore s)
    : super(s, StoreKeys.challenges, Challenge.fromJson, (e) => e.toJson());
}

class LocalEquipmentLoanRepository extends LocalRepository<EquipmentLoan>
    implements EquipmentLoanRepository {
  LocalEquipmentLoanRepository(LocalStore s)
    : super(s, StoreKeys.loans, EquipmentLoan.fromJson, (e) => e.toJson());
}

class LocalPointsRepository extends LocalRepository<PointsEntry>
    implements PointsRepository {
  LocalPointsRepository(LocalStore s)
    : super(s, StoreKeys.points, PointsEntry.fromJson, (e) => e.toJson());
}

class LocalRecommendationLogRepository
    extends LocalRepository<RecommendationLog>
    implements RecommendationLogRepository {
  LocalRecommendationLogRepository(LocalStore s)
    : super(s, StoreKeys.logs, RecommendationLog.fromJson, (e) => e.toJson());
}

/// Locations and communities come from assets and never change at runtime.
class AssetLocationRepository implements LocationRepository {
  AssetLocationRepository(this.data);
  final ReferenceData data;

  @override
  List<Community> communities() => data.communities;

  @override
  List<PresetLocation> locations() => data.locations;
}

class AssetRewardRepository implements RewardRepository {
  AssetRewardRepository(this.data);
  final ReferenceData data;

  @override
  List<Voucher> vouchers() => data.vouchers;
}

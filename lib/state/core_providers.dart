import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../config/ai_config.dart';
import '../config/matching_config.dart';
import '../core/models/reference_models.dart';
import '../data/local/auth_repository.dart';
import '../data/local/local_repositories.dart';
import '../data/local/local_store.dart';
import '../data/repositories/repositories.dart';
import '../data/seed_loader.dart';
import '../services/ai_service.dart';
import '../services/matching_engine.dart';
import '../services/people_matcher.dart';

/// Root navigator key so the AI bubble (above all routes) can open dialogs.
final rootNavigatorKey = GlobalKey<NavigatorState>();
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Overridden in main() after async start-up work.
final storeProvider = Provider<LocalStore>((ref) => throw UnimplementedError());
final referenceProvider =
    Provider<ReferenceData>((ref) => throw UnimplementedError());
final matchingConfigProvider =
    Provider<MatchingConfig>((ref) => MatchingConfig.defaults());
final aiConfigProvider = Provider<AiConfig>((ref) => AiConfig.fromEnv());

final seedLoaderProvider =
    Provider<SeedLoader>((ref) => SeedLoader(ref.watch(storeProvider)));

final userRepoProvider = Provider<UserRepository>(
    (ref) => LocalUserRepository(ref.watch(storeProvider)));
final postRepoProvider = Provider<PostRepository>(
    (ref) => LocalPostRepository(ref.watch(storeProvider)));
final chatRepoProvider = Provider<ChatRepository>(
    (ref) => LocalChatRepository(ref.watch(storeProvider)));
final challengeRepoProvider = Provider<ChallengeRepository>(
    (ref) => LocalChallengeRepository(ref.watch(storeProvider)));
final loanRepoProvider = Provider<EquipmentLoanRepository>(
    (ref) => LocalEquipmentLoanRepository(ref.watch(storeProvider)));
final pointsRepoProvider = Provider<PointsRepository>(
    (ref) => LocalPointsRepository(ref.watch(storeProvider)));
final logRepoProvider = Provider<RecommendationLogRepository>(
    (ref) => LocalRecommendationLogRepository(ref.watch(storeProvider)));
final locationRepoProvider = Provider<LocationRepository>(
    (ref) => AssetLocationRepository(ref.watch(referenceProvider)));
final rewardRepoProvider = Provider<RewardRepository>(
    (ref) => AssetRewardRepository(ref.watch(referenceProvider)));

final authRepoProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(storeProvider)));

final aiServiceProvider =
    Provider<AiService>((ref) => AiService(ref.watch(aiConfigProvider)));
final matchingEngineProvider = Provider<MatchingEngine>(
    (ref) => MatchingEngine(ref.watch(matchingConfigProvider)));
final peopleMatcherProvider = Provider<PeopleMatcher>((ref) => PeopleMatcher(
    ref.watch(matchingConfigProvider), ref.watch(referenceProvider)));

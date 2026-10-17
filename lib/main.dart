import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config/matching_config.dart';
import 'core/models/reference_models.dart';
import 'data/local/local_store.dart';
import 'data/seed_loader.dart';
import 'state/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The AI is optional: with no .env or no key the app uses the offline parser.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  final store = LocalStore(await SharedPreferences.getInstance());
  await SeedLoader(store).ensureSeeded();

  final reference = ReferenceData.fromJson(
    await SeedLoader.loadLocations(rootBundle),
    await SeedLoader.loadVouchers(rootBundle),
  );

  var matching = MatchingConfig.defaults();
  try {
    matching = MatchingConfig.fromJson(
      jsonDecode(await rootBundle.loadString('assets/config/matching_config.json'))
          as Map<String, dynamic>,
    );
  } catch (_) {}

  runApp(ProviderScope(
    overrides: [
      storeProvider.overrideWithValue(store),
      referenceProvider.overrideWithValue(reference),
      matchingConfigProvider.overrideWithValue(matching),
    ],
    child: const NeighbourFitApp(),
  ));
}

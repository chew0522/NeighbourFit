import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourfit/core/models/constants.dart';
import 'package:neighbourfit/core/models/reference_models.dart';
import 'package:neighbourfit/data/local/local_store.dart';
import 'package:neighbourfit/features/onboarding/wizard_screen.dart';
import 'package:neighbourfit/state/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('nothing is preselected and every step needs a choice', (tester) async {
    tester.view.physicalSize = const Size(900, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    const reference = ReferenceData(
      communities: [Community(id: 'c1', name: 'Lakeside Residences', lat: 3.1, lng: 101.6)],
      locations: [],
      vouchers: [],
      residentCodes: [],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
        referenceProvider.overrideWithValue(reference),
      ],
      child: const MaterialApp(home: WizardScreen()),
    ));

    int selectedChips() => tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .where((c) => c.selected)
        .length;
    int selectedFilters() => tester
        .widgetList<FilterChip>(find.byType(FilterChip))
        .where((c) => c.selected)
        .length;
    Future<void> next(String expectedError) async {
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text(expectedError), findsOneWidget);
    }

    // Step 1: about you. No age group, residence or avatar chosen.
    expect(selectedChips(), 0);
    await next('Please enter a nickname.');
    await tester.enterText(find.byType(TextField).first, 'Test');
    await next('Please pick an avatar colour.');
    await tester.tap(find.byKey(ValueKey('avatar_${avatarColors.first}')));
    await tester.pump();
    await next('Please choose your age group.');
    await tester.tap(find.text('18-29'));
    await tester.pump();
    expect(find.text('Birth year'), findsNothing);
    await next('Please choose your community.');
    await tester.tap(find.text('Lakeside Residences'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();

    // Step 2: sports and level, nothing chosen.
    expect(selectedFilters(), 0);
    expect(selectedChips(), 0);
    await next('Pick at least one sport.');
    await tester.tap(find.text('Running'));
    await tester.pump();
    await next('Please choose your level.');
    await tester.tap(find.text('Beginner'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();

    // Step 3: times and languages, nothing chosen (English is not preselected).
    expect(selectedFilters(), 0);
    await next('Pick at least one time.');
    await tester.tap(find.text('Morning'));
    await tester.pump();
    await next('Pick at least one language.');
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();

    // Step 4: every row needs an answer, and there is no Skip.
    expect(selectedChips(), 0);
    expect(find.text('Skip'), findsNothing);
    expect(find.textContaining('accessibility'), findsNothing);
    await next('Please choose an option for gender.');
    await tester.tap(find.text('Female'));
    await tester.pump();
    await next('Please choose your age preference.');
    await tester.tap(find.text('Any age'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();

    // Done screen.
    expect(find.text("You're all set!"), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_theme.dart';
import 'features/assistant/assistant_bubble.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/shell/home_shell.dart';
import 'state/app_state.dart';
import 'state/core_providers.dart';

class NeighbourFitApp extends ConsumerWidget {
  const NeighbourFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserProvider) != null;
    return MaterialApp(
      title: 'NeighbourFit',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      navigatorKey: rootNavigatorKey,
      scaffoldMessengerKey: rootMessengerKey,
      // The AI bubble sits above every route.
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          if (signedIn) const AssistantBubble(),
        ],
      ),
      home: signedIn ? const HomeShell() : const WelcomeScreen(),
    );
  }
}

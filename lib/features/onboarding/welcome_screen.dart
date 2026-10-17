import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/avatar.dart';
import 'wizard_screen.dart';

/// Step 1 of onboarding: pick a demo account (or create a new profile) and
/// enter the resident code. The code is mock-validated against seeded codes.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _createNew = '__new__';
  String? _choice;
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final ref = this.ref;
    final codes = ref.read(referenceProvider).residentCodes
        .map((c) => c.toLowerCase())
        .toList();
    if (!codes.contains(_code.text.trim().toLowerCase())) {
      setState(() => _error = 'That resident code was not recognised. Try NF-2026.');
      return;
    }
    setState(() => _error = null);
    if (_choice == _createNew) {
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WizardScreen()));
    } else if (_choice != null) {
      await ref.read(sessionProvider.notifier).signIn(_choice!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demos = ref.watch(usersProvider).where((u) => u.isDemo).toList();
    final ref0 = ref.watch(referenceProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.directions_walk, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text('NeighbourFit',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Social media keeps people inside their screens. NeighbourFit gets them out the door.',
              style: TextStyle(fontSize: 18, height: 1.35),
            ),
            const SizedBox(height: 24),
            const Text('Who are you today?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Pick a demo account, or create your own profile.',
                style: TextStyle(color: kMuted)),
            const SizedBox(height: 12),
            for (final u in demos)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChoiceTile(
                  selected: _choice == u.id,
                  onTap: () => setState(() => _choice = u.id),
                  leading: UserAvatar(user: u, radius: 22),
                  title: u.nickname,
                  subtitle:
                      '${u.ageGroup.label} · ${ref0.community(u.communityId)?.name ?? ''}',
                ),
              ),
            _ChoiceTile(
              selected: _choice == _createNew,
              onTap: () => setState(() => _choice = _createNew),
              leading: const CircleAvatar(
                radius: 22,
                backgroundColor: kSurfaceGreen,
                child: Icon(Icons.person_add, color: kPrimary),
              ),
              title: 'Create a new profile',
              subtitle: 'Takes about a minute',
            ),
            const SizedBox(height: 20),
            const Text('Resident code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. NF-2026',
                errorText: _error,
                prefixIcon: const Icon(Icons.verified_user_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            const Text('For residents only. This is a demo, so any seeded code works.',
                style: TextStyle(color: kMuted, fontSize: 14)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: (_choice != null && _code.text.trim().isNotEmpty) ? _continue : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? kPrimary : Colors.transparent, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    Text(subtitle, style: const TextStyle(color: kMuted)),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle, color: kPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

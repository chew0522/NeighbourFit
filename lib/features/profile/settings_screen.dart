import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/enums.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/ui_helpers.dart';
import '../auth/preset_accounts.dart';

/// Privacy controls, match preferences, blocked neighbours and demo tools.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const Scaffold();
    final users = ref.read(usersProvider.notifier);
    final blocked = me.blockedUserIds
        .map((id) => ref.watch(userByIdProvider(id)))
        .whereType<dynamic>()
        .toList();
    final ai = ref.watch(aiConfigProvider);
    final open =
        ref.watch(myChallengesProvider).where((c) => !c.unlocked).toList()
          ..sort((a, b) => b.fraction.compareTo(a.fraction));
    final pinned = open.isEmpty ? null : open.first;

    Widget header(String t) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 6),
      child: Text(
        t,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          header('Who can see my details'),
          const _SwitchLegend(),
          const SizedBox(height: 12),
          for (final f in visibilityFields)
            _VisibilityTile(
              field: f,
              visible: me.visibilityOf(f) == FieldVisibility.everyone,
              onChanged: (on) => users.update(
                me.id,
                (u) => u.copyWith(
                  visibility: {
                    ...u.visibility,
                    f: on ? FieldVisibility.everyone : FieldVisibility.onlyMe,
                  },
                ),
              ),
            ),
          header('Matching'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Prefer neighbours of a similar age'),
            subtitle: Text(
              me.agePref == 'same'
                  ? 'On: suggestions and the assistant favour neighbours in your age group.'
                  : 'Off: suggestions and the assistant do not look at age.',
            ),
            value: me.agePref == 'same',
            onChanged: (v) => users.update(
              me.id,
              (u) => u.copyWith(agePref: v ? 'same' : 'any'),
            ),
          ),
          header('Blocked neighbours'),
          if (blocked.isEmpty)
            const Text(
              'You have not blocked anyone.',
              style: TextStyle(color: kMuted),
            ),
          for (final u in blocked)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(u.nickname as String),
              trailing: TextButton(
                onPressed: () => users.unblock(me.id, u.id as String),
                child: const Text('Unblock'),
              ),
            ),
          header('Account'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () async {
              await ref.read(sessionProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
          ),
          header('Demo tools'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.switch_account_outlined),
            title: const Text('Switch to a preset account'),
            subtitle: const Text(
              'For the team: jump between Mei Ling, Siti, Raj and others.',
            ),
            onTap: () => showPresetAccounts(context, ref),
          ),
          Text(
            ai.hasKey
                ? 'AI assistant: live (${ai.model}), with offline fallback.'
                : 'AI assistant: offline mode (no API key in .env). The keyword fallback is used.',
            style: const TextStyle(color: kMuted),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.refresh),
            title: const Text('Reset demo data'),
            subtitle: const Text(
              'Reloads seed data with fresh dates. Do this before a demo.',
            ),
            onTap: () async {
              final ok = await confirmDialog(
                context,
                title: 'Reset demo data?',
                message:
                    'All posts, chats and changes made on this device will be replaced.',
                confirmLabel: 'Reset',
              );
              if (!ok) return;
              await ref.read(resetDemoDataProvider)();
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
              showSnack('Demo data reset.');
            },
          ),
          if (pinned != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Fill the closest challenge'),
              subtitle: const Text(
                'Demo shortcut to show the unlocked reward.',
              ),
              onTap: () async {
                await ref
                    .read(challengesProvider.notifier)
                    .fillToTarget(pinned.id);
                showSnack('Challenge goal reached (demo).');
              },
            ),
        ],
      ),
    );
  }
}

/// One line above the toggles; the toggles themselves say Public / Private.
class _SwitchLegend extends StatelessWidget {
  const _SwitchLegend();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: kSurfaceGreen,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text(
      'Public: neighbours can see it and it is used for matching. '
      'Private: only you see it.',
      style: TextStyle(fontSize: 13, height: 1.35),
    ),
  );
}

/// One detail with a Public / Private toggle.
class _VisibilityTile extends StatelessWidget {
  const _VisibilityTile({
    required this.field,
    required this.visible,
    required this.onChanged,
  });

  final String field;
  final bool visible;
  final ValueChanged<bool> onChanged;

  static const _labels = {
    'ageGroup': 'Age group',
    'gender': 'Gender',
    'level': 'Fitness level',
    'timeSlots': 'Usual times',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _labels[field] ?? field,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          _PublicPrivateToggle(value: visible, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Pill toggle: "O Private" when off, "Public O" when on. The O is the knob.
class _PublicPrivateToggle extends StatelessWidget {
  const _PublicPrivateToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const w = 112.0, h = 40.0, knob = 32.0;
    return Semantics(
      toggled: value,
      label: value ? 'Public' : 'Private',
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: value ? kPrimary : kBorder,
            borderRadius: BorderRadius.circular(h / 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerLeft : Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    value ? 'Public' : 'Private',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: value ? Colors.white : kMuted,
                    ),
                  ),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all((h - knob) / 2),
                  width: knob,
                  height: knob,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

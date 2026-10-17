import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/enums.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/ui_helpers.dart';

/// Privacy controls, match preferences, blocked neighbours and demo tools.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _fieldLabels = {
    'ageGroup': 'Age group',
    'gender': 'Gender',
    'level': 'Level',
    'timeSlots': 'Usual times',
  };

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
    final open = ref.watch(myChallengesProvider).where((c) => !c.unlocked).toList()
      ..sort((a, b) => b.fraction.compareTo(a.fraction));
    final pinned = open.isEmpty ? null : open.first;

    Widget header(String t) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 6),
          child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          header('Who can see my details'),
          for (final f in visibilityFields)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_fieldLabels[f] ?? f),
              trailing: DropdownButton<FieldVisibility>(
                value: me.visibilityOf(f),
                underline: const SizedBox.shrink(),
                items: [
                  for (final v in FieldVisibility.values)
                    DropdownMenuItem(value: v, child: Text(v.label)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  users.update(me.id, (u) => u.copyWith(visibility: {...u.visibility, f: v}));
                },
              ),
            ),
          const Text('Details set to "Only me" are not used when neighbours are matched with you.',
              style: TextStyle(color: kMuted, fontSize: 14)),
          header('Matching'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Prefer neighbours of a similar age'),
            value: me.agePref == 'same',
            onChanged: (v) =>
                users.update(me.id, (u) => u.copyWith(agePref: v ? 'same' : 'any')),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('I need accessibility support'),
            subtitle: const Text('The assistant will only suggest accessible activities.'),
            value: me.needsAccessibility,
            onChanged: (v) => users.update(me.id, (u) => u.copyWith(needsAccessibility: v)),
          ),
          header('Blocked neighbours'),
          if (blocked.isEmpty)
            const Text('You have not blocked anyone.', style: TextStyle(color: kMuted)),
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
            title: const Text('Switch account'),
            onTap: () async {
              await ref.read(sessionProvider.notifier).signOut();
              if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          header('Demo tools'),
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
            subtitle: const Text('Reloads seed data with fresh dates. Do this before a demo.'),
            onTap: () async {
              final ok = await confirmDialog(
                context,
                title: 'Reset demo data?',
                message: 'All posts, chats and changes made on this device will be replaced.',
                confirmLabel: 'Reset',
              );
              if (!ok) return;
              await ref.read(resetDemoDataProvider)();
              if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              showSnack('Demo data reset.');
            },
          ),
          if (pinned != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Fill the closest challenge'),
              subtitle: const Text('Demo shortcut to show the unlocked reward.'),
              onTap: () async {
                await ref.read(challengesProvider.notifier).fillToTarget(pinned.id);
                showSnack('Challenge goal reached (demo).');
              },
            ),
        ],
      ),
    );
  }
}

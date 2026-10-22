import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/constants.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/avatar.dart';
import '../onboarding/wizard_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const Scaffold();
    final community =
        ref.watch(referenceProvider).community(me.communityId)?.name ?? '';

    Widget row(String label, String value, {String? field}) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: kMuted, fontSize: 14)),
      subtitle: Text(value, style: const TextStyle(fontSize: 17, color: kText)),
      trailing: field == null
          ? null
          : Tooltip(
              message: 'Visible to: ${me.visibilityOf(field).label}',
              child: Chip(
                label: Text(
                  me.visibilityOf(field).label,
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: UserAvatar(user: me, radius: 40)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              me.nickname,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          row('Community', community),
          row('Age group', me.ageGroup.label, field: 'ageGroup'),
          row('Gender', me.gender.label, field: 'gender'),
          row('Sports', me.sports.map((s) => s.label).join(', ')),
          row('Level', me.level.label, field: 'level'),
          row(
            'Usual times',
            me.timeSlots.map((t) => t.label).join(', '),
            field: 'timeSlots',
          ),
          row(
            'Languages',
            me.languages.map((l) => languageLabels[l] ?? l).join(', '),
          ),
          row('Prefers similar age', me.agePref == 'same' ? 'Yes' : 'No'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => WizardScreen(editing: me)),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Edit profile'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Change who can see each detail in Privacy & settings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

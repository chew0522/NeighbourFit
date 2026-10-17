import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/avatar.dart';
import 'my_equipment_screen.dart';
import 'profile_screen.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';

/// Me tab: four big tiles.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final met = ref.watch(neighboursMetProvider);
    final community = ref.watch(referenceProvider).community(me?.communityId ?? '')?.name ?? '';
    void go(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(title: const Text('Me')),
      body: me == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        UserAvatar(user: me, radius: 32),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(me.nickname,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                              Text(community, style: const TextStyle(color: kMuted)),
                              const SizedBox(height: 6),
                              Text(
                                "Neighbours you've exercised with this month: $met",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _Tile(
                      icon: Icons.person,
                      label: 'Profile',
                      onTap: () => go(const ProfileScreen()),
                    ),
                    _Tile(
                      icon: Icons.card_giftcard,
                      label: 'Points & rewards',
                      detail: '${me.points} points',
                      onTap: () => go(const RewardsScreen()),
                    ),
                    _Tile(
                      icon: Icons.handyman,
                      label: 'My equipment',
                      onTap: () => go(const MyEquipmentScreen()),
                    ),
                    _Tile(
                      icon: Icons.shield_outlined,
                      label: 'Privacy & settings',
                      onTap: () => go(const SettingsScreen()),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap, this.detail});

  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: kSurfaceGreen, shape: BoxShape.circle),
                child: Icon(icon, size: 30, color: kPrimary),
              ),
              const SizedBox(height: 10),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              if (detail != null)
                Text(detail!, style: const TextStyle(color: kMuted, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

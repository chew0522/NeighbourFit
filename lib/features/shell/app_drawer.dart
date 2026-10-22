import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/avatar.dart';
import '../profile/my_equipment_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/rewards_screen.dart';
import '../profile/settings_screen.dart';

/// Left drawer opened from the hamburger icon on Home.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final community =
        ref.watch(referenceProvider).community(me?.communityId ?? '')?.name ??
        '';

    void go(Widget page) {
      Navigator.of(context).pop(); // close the drawer
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    return Drawer(
      backgroundColor: kBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  UserAvatar(user: me, radius: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          me?.nickname ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(community, style: const TextStyle(color: kMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () => go(const ProfileScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Points & rewards'),
              trailing: Text(
                '${me?.points ?? 0}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: kPrimary,
                ),
              ),
              onTap: () => go(const RewardsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.handyman_outlined),
              title: const Text('My equipment'),
              onTap: () => go(const MyEquipmentScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Privacy & settings'),
              onTap: () => go(const SettingsScreen()),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(sessionProvider.notifier).signOut();
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  AppLogo(size: 32),
                  SizedBox(width: 10),
                  Text(
                    'NeighbourFit · prototype',
                    style: TextStyle(color: kMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/avatar.dart';

/// Team entrance: sign straight into a preset (seeded) account, no password.
/// Opened by tapping the logo five times on the login page, and from
/// Privacy & settings > Demo tools.
Future<void> showPresetAccounts(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final current = ref.watch(sessionProvider);
        final all = ref.watch(usersProvider);
        final community = ref.watch(referenceProvider);
        // Demo accounts first, then everyone else for quick testing.
        final users = [
          ...all.where((u) => u.isDemo),
          ...all.where((u) => !u.isDemo),
        ];
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Demo accounts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pick a resident to explore the app. No password needed.',
                      style: TextStyle(color: kMuted),
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final u in users)
                        ListTile(
                          leading: UserAvatar(user: u, radius: 22),
                          title: Text(
                            u.nickname,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${u.ageGroup.label} · ${community.community(u.communityId)?.name ?? ''}'
                            '${u.isDemo ? '' : ' · neighbour'}',
                          ),
                          trailing: u.id == current
                              ? const Icon(Icons.check_circle, color: kPrimary)
                              : null,
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            await ref
                                .read(sessionProvider.notifier)
                                .signIn(u.id);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

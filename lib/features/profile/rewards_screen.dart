import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/reference_models.dart';
import '../../core/utils/time_utils.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/ui_helpers.dart';

/// Minimal rewards: points balance, seeded vouchers, mock redeem.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const Scaffold();
    final ref0 = ref.watch(referenceProvider);
    final challenges = ref.watch(myChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Points & rewards')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: kSurfaceGreen,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text('Your points', style: TextStyle(color: kMuted)),
                  Text('${me.points}',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: kPrimary)),
                  const SizedBox(height: 4),
                  const Text('+10 per challenge check-in · +20 per meetup you join',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          if (challenges.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Community rewards',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final c in challenges)
              Card(
                child: ListTile(
                  leading: Icon(c.unlocked ? Icons.lock_open : Icons.lock_outline,
                      color: c.unlocked ? kPrimary : kMuted),
                  title: Text(c.reward, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(c.unlocked
                      ? 'Unlocked: ${c.title}'
                      : '${c.title} · ${(c.fraction * 100).round()}%'),
                ),
              ),
          ],
          const SizedBox(height: 20),
          const Text('Vouchers from local businesses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final v in ref0.vouchers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
                  leading: const Icon(Icons.storefront, color: kPrimary, size: 30),
                  title: Text(v.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${v.merchant} · ${v.pointsCost} points'),
                  trailing: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
                    onPressed: me.points >= v.pointsCost ? () => _redeem(context, ref, v) : null,
                    child: const Text('Redeem'),
                  ),
                ),
              ),
            ),
          if (me.redeemedVouchers.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('My vouchers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final r in me.redeemedVouchers.reversed)
              Card(
                color: kSurfaceGreen,
                child: ListTile(
                  leading: const Icon(Icons.confirmation_number_outlined, color: kPrimary),
                  title: Text(ref0.voucher(r.voucherId)?.title ?? 'Voucher',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Code ${r.code} · ${fmtDate(r.at)}'),
                ),
              ),
          ],
          const SizedBox(height: 12),
          const Text('Vouchers are a demo. No real merchant system is connected.',
              textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _redeem(BuildContext context, WidgetRef ref, Voucher v) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final ok = await confirmDialog(
      context,
      title: 'Redeem ${v.title}?',
      message: 'This uses ${v.pointsCost} points.',
      confirmLabel: 'Redeem',
    );
    if (!ok) return;
    // MOCK: the code is generated locally, no merchant system.
    final code = await ref.read(usersProvider.notifier).redeem(me.id, v);
    if (code == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(v.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(v.merchant, style: const TextStyle(color: kMuted)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: kSurfaceGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(code,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
            const SizedBox(height: 10),
            const Text('Show this code at the shop (demo only).',
                textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
      ),
    );
  }
}

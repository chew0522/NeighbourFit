import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../core/models/challenge.dart';
import '../../core/utils/time_utils.dart';
import '../../state/app_state.dart';
import '../../widgets/ui_helpers.dart';

final _num = NumberFormat.decimalPattern();

/// Shared community progress and the user's own contribution. No rankings.
class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final c = ref
        .watch(challengesProvider)
        .where((e) => e.id == challengeId)
        .firstOrNull;
    if (c == null || me == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off,
          message: 'Challenge not found.',
        ),
      );
    }
    final joined = c.participantIds.contains(me.id);
    final today = ymd(DateTime.now());
    final doneToday = c.checkedInOn(me.id, today);
    final mine = c.myContribution(me.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Community challenge')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            c.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${daysLeft(c.endsAt, DateTime.now())} days left · ${c.participantIds.length} neighbours joined',
            style: const TextStyle(color: kMuted),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our community so far',
                    style: TextStyle(fontSize: 15, color: kMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_num.format(c.progress)} ${c.unit}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: c.fraction,
                      minHeight: 16,
                      color: kGreen,
                      backgroundColor: kSurfaceGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Goal: ${_num.format(c.target)} ${c.unit}  ·  ${(c.fraction * 100).round()}%',
                  ),
                  const Divider(height: 28),
                  Row(
                    children: [
                      const Icon(Icons.person, color: kPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mine > 0
                              ? 'You added ${_num.format(mine)} ${c.unit}. Thank you!'
                              : 'Your contribution will show here.',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: c.unlocked ? kSurfaceGreen : Colors.white,
            child: ListTile(
              leading: Icon(
                c.unlocked ? Icons.lock_open : Icons.lock_outline,
                color: c.unlocked ? kPrimary : kMuted,
                size: 28,
              ),
              title: Text(
                c.unlocked
                    ? 'Unlocked: ${c.reward}'
                    : 'Community reward: ${c.reward}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                c.unlocked
                    ? 'Your community did it together!'
                    : 'Unlocks when we reach ${_num.format(c.target)} ${c.unit}.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!joined)
            FilledButton(
              onPressed: () async {
                await ref.read(challengesProvider.notifier).join(c.id, me.id);
                showSnack("You've joined. Check in each day.");
              },
              child: const Text('Join the challenge'),
            )
          else if (doneToday)
            const OutlinedButton(
              onPressed: null,
              child: Text("Checked in today. See you tomorrow!"),
            )
          else ...[
            FilledButton(
              onPressed: () => _checkIn(ref, c, c.quickAmount),
              child: Text(
                'I did it today (+${_num.format(c.quickAmount)} ${c.unit})',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _enterAmount(context, ref, c),
              child: const Text('Enter my steps'),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Check-ins earn +10 points. Only community totals are shown, never a ranking.',
            style: TextStyle(color: kMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _checkIn(WidgetRef ref, Challenge c, int amount) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final ok = await ref
        .read(challengesProvider.notifier)
        .checkIn(c.id, me.id, amount);
    showSnack(
      ok
          ? 'Checked in: +$amount ${c.unit}, +10 points'
          : 'You already checked in today.',
    );
  }

  Future<void> _enterAmount(
    BuildContext context,
    WidgetRef ref,
    Challenge c,
  ) async {
    final ctrl = TextEditingController(text: '${c.quickAmount}');
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('How many ${c.unit} today?'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(suffixText: c.unit),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text.trim())),
            child: const Text('Check in'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (amount != null && amount > 0 && amount <= 1000000) {
      await _checkIn(ref, c, amount);
    }
  }
}

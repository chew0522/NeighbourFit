import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../core/models/challenge.dart';
import '../../core/utils/time_utils.dart';
import '../../state/app_state.dart';
import '../../widgets/ui_helpers.dart';
import 'challenge_detail_screen.dart';

final _num = NumberFormat.decimalPattern();

IconData challengeIcon(String kind) {
  switch (kind) {
    case 'walk':
      return Icons.hiking;
    case 'cycle':
      return Icons.directions_bike;
    case 'time':
      return Icons.timer_outlined;
    case 'swim':
      return Icons.pool;
    default:
      return Icons.directions_walk;
  }
}

/// All active challenges for the user's community, each with its own reward.
class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final list = ref.watch(myChallengesProvider);
    final joined = list
        .where((c) => me != null && c.participantIds.contains(me.id))
        .length;
    final unlocked = list.where((c) => c.unlocked).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
        children: [
          const Text(
            'Move together and unlock rewards for the whole community. Only community totals are shown, never a ranking.',
            style: TextStyle(color: kMuted, fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(label: 'Joined', value: '$joined'),
              const SizedBox(width: 10),
              _Stat(label: 'Rewards unlocked', value: '$unlocked'),
              const SizedBox(width: 10),
              _Stat(label: 'My points', value: '${me?.points ?? 0}'),
            ],
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const SizedBox(
              height: 240,
              child: EmptyState(
                icon: Icons.emoji_events_outlined,
                message: 'No active challenges right now. Check back soon.',
              ),
            ),
          for (final c in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChallengeTile(challenge: c),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: kSurfaceGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kPrimary,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: kText),
          ),
        ],
      ),
    ),
  );
}

class _ChallengeTile extends ConsumerWidget {
  const _ChallengeTile({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final c = challenge;
    final joined = me != null && c.participantIds.contains(me.id);
    final doneToday = me != null && c.checkedInOn(me.id, ymd(DateTime.now()));
    final left = daysLeft(c.endsAt, DateTime.now());

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChallengeDetailScreen(challengeId: c.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: kSurfaceGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(challengeIcon(c.kind), color: kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$left days left · ${c.participantIds.length} neighbours',
                          style: const TextStyle(color: kMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: c.fraction,
                  minHeight: 10,
                  color: c.unlocked ? kPrimary : kGreen,
                  backgroundColor: kSurfaceGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_num.format(c.progress)} / ${_num.format(c.target)} ${c.unit}  ·  ${(c.fraction * 100).round()}%',
                style: const TextStyle(fontSize: 13, color: kMuted),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: c.unlocked ? kSurfaceGreen : kAccentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      c.unlocked ? Icons.lock_open : Icons.card_giftcard,
                      size: 20,
                      color: c.unlocked ? kPrimary : kAccentDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.unlocked
                            ? 'Unlocked: ${c.reward}'
                            : 'Reward: ${c.reward}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(110, 42),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChallengeDetailScreen(challengeId: c.id),
                    ),
                  ),
                  child: Text(
                    doneToday ? 'Done today' : (joined ? 'Check in' : 'Join'),
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

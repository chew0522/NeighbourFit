import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/challenge.dart';
import '../../core/models/reference_models.dart';
import '../../core/utils/time_utils.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/ui_helpers.dart';
import '../challenges/challenge_detail_screen.dart';
import '../challenges/challenges_screen.dart' show challengeIcon;

/// Points & rewards with a small bottom bar: Rewards, Vouchers, History.
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  int _tab = 0;
  static const _titles = ['Rewards', 'Vouchers', 'History'];

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kSurfaceGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, size: 18, color: kPrimary),
                  const SizedBox(width: 6),
                  Text('${me.points}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: kPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _RewardsTab(onViewWallet: () => setState(() => _tab = 1)),
          _VouchersTab(onBrowse: () => setState(() => _tab = 0)),
          const _HistoryTab(),
        ],
      ),
      bottomNavigationBar: _MiniBar(
        index: _tab,
        walletCount: me.redeemedVouchers.length,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// Small bar with three icons and short labels.
class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.index, required this.onTap, this.walletCount = 0});

  final int index;
  final int walletCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.card_giftcard_rounded, 'Rewards'),
      (Icons.confirmation_number_rounded, 'Vouchers'),
      (Icons.history_rounded, 'History'),
    ];
    return Material(
      color: Colors.white,
      elevation: 10,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Badge(
                          isLabelVisible: i == 1 && walletCount > 0,
                          label: Text('$walletCount'),
                          backgroundColor: kAccent,
                          textColor: kText,
                          child: Icon(items[i].$1,
                              size: 24, color: i == index ? kPrimary : kMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(items[i].$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == index ? FontWeight.w800 : FontWeight.w500,
                              color: i == index ? kPrimary : kMuted,
                            )),
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

// ----------------------------------------------------------------- rewards

Widget _sectionHeader(String title, String subtitle) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 14)),
        ],
      ),
    );

/// Points, community rewards (shared, swipe row) and the voucher store.
class _RewardsTab extends ConsumerWidget {
  const _RewardsTab({required this.onViewWallet});

  final VoidCallback onViewWallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final challenges = ref.watch(myChallengesProvider);
    final data = ref.watch(referenceProvider);
    if (me == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          color: kSurfaceGreen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              children: [
                const Text('Your points', style: TextStyle(color: kMuted, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${me.points}',
                    style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: kPrimary)),
                const SizedBox(height: 6),
                const Text('+10 per challenge check-in · +20 per meetup you join',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Community rewards', 'Unlocked together. Tap one to open its challenge.'),
        if (challenges.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('No active challenges right now.', style: TextStyle(color: kMuted)),
          )
        else
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: challenges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _CommunityRewardCard(challenge: challenges[i]),
            ),
          ),
        const SizedBox(height: 28),
        _sectionHeader('Voucher store', 'Spend your points on deals from local businesses.'),
        for (final v in data.vouchers)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration:
                          const BoxDecoration(color: kSurfaceGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.storefront, color: kPrimary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(v.merchant, style: const TextStyle(color: kMuted, fontSize: 14)),
                          const SizedBox(height: 6),
                          _PriceTag(
                            cost: v.pointsCost,
                            short: me.points < v.pointsCost ? v.pointsCost - me.points : 0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(84, 44)),
                      onPressed: me.points >= v.pointsCost
                          ? () => _redeem(context, ref, v, onViewWallet)
                          : null,
                      child: const Text('Redeem'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        const Text('Vouchers are a demo. No real merchant system is connected.',
            textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13)),
      ],
    );
  }

  Future<void> _redeem(BuildContext context, WidgetRef ref, Voucher v, VoidCallback view) async {
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
    if (code == null) return;
    showSnack('Added to your vouchers', actionLabel: 'View', onAction: view);
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.cost, required this.short});

  final int cost;
  final int short;

  @override
  Widget build(BuildContext context) {
    final affordable = short == 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: affordable ? kSurfaceGreen : kAccentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars_rounded, size: 15, color: affordable ? kPrimary : kAccentDark),
              const SizedBox(width: 4),
              Text('$cost points',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: affordable ? kPrimary : kAccentDark)),
            ],
          ),
        ),
        if (!affordable) ...[
          const SizedBox(width: 8),
          Text('$short to go', style: const TextStyle(color: kMuted, fontSize: 12)),
        ],
      ],
    );
  }
}

/// Compact card in the swipe row. Not purchasable: it only links to its challenge.
class _CommunityRewardCard extends StatelessWidget {
  const _CommunityRewardCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    return SizedBox(
      width: 250,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChallengeDetailScreen(challengeId: c.id))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.unlocked ? kSurfaceGreen : kAccentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(c.unlocked ? Icons.lock_open : challengeIcon(c.kind),
                          size: 22, color: c.unlocked ? kPrimary : kAccentDark),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: kMuted),
                  ],
                ),
                const SizedBox(height: 10),
                Text(c.reward,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kMuted, fontSize: 13)),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: c.fraction,
                    minHeight: 8,
                    color: c.unlocked ? kPrimary : kGreen,
                    backgroundColor: kSurfaceGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(c.unlocked ? 'Unlocked!' : '${(c.fraction * 100).round()}% there',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: c.unlocked ? FontWeight.w800 : FontWeight.w500,
                        color: c.unlocked ? kPrimary : kMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- vouchers

/// The wallet: only vouchers you have already redeemed.
class _VouchersTab extends ConsumerWidget {
  const _VouchersTab({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final data = ref.watch(referenceProvider);
    if (me == null) return const SizedBox.shrink();
    final mine = me.redeemedVouchers.reversed.toList();

    if (mine.isEmpty) {
      return EmptyState(
        icon: Icons.confirmation_number_outlined,
        message: 'No vouchers yet. Spend your points in the voucher store.',
        actionLabel: 'Browse the store',
        onAction: onBrowse,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _sectionHeader('My vouchers', 'Show the code at the shop (demo only).'),
        for (final r in mine)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration:
                              const BoxDecoration(color: kSurfaceGreen, shape: BoxShape.circle),
                          child: const Icon(Icons.confirmation_number_outlined, color: kPrimary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.voucher(r.voucherId)?.title ?? 'Voucher',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text('${data.voucher(r.voucherId)?.merchant ?? ''} · ${fmtDate(r.at)}',
                                  style: const TextStyle(color: kMuted, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: kSurfaceGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        r.code,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------- history

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(myPointsHistoryProvider);
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        message: 'No points yet. Join a meetup or check in to a challenge to start earning.',
      );
    }
    final earned = entries.where((e) => e.delta > 0).fold<int>(0, (a, e) => a + e.delta);
    final spent = entries.where((e) => e.delta < 0).fold<int>(0, (a, e) => a - e.delta);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            _Summary(label: 'Earned', value: '+$earned', color: kPrimary),
            const SizedBox(width: 12),
            _Summary(label: 'Spent', value: '-$spent', color: kAccentDark),
          ],
        ),
        const SizedBox(height: 18),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: e.delta > 0 ? kSurfaceGreen : kAccentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        e.delta > 0 ? Icons.add_rounded : Icons.remove_rounded,
                        color: e.delta > 0 ? kPrimary : kAccentDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(timeAgo(e.at, DateTime.now()),
                              style: const TextStyle(color: kMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text('${e.delta > 0 ? '+' : ''}${e.delta}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: e.delta > 0 ? kPrimary : kAccentDark,
                        )),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: const TextStyle(color: kMuted, fontSize: 13)),
            ],
          ),
        ),
      );
}

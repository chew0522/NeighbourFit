import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/equipment_loan.dart';
import '../../core/utils/time_utils.dart';
import '../../state/actions.dart';
import '../../state/app_state.dart';
import '../feed/post_card.dart';

String _statusLabel(LoanStatus s) {
  switch (s) {
    case LoanStatus.requested:
      return 'Requested';
    case LoanStatus.approved:
      return 'Approved, waiting for pick-up';
    case LoanStatus.pickedUp:
      return 'Picked up';
    case LoanStatus.returned:
      return 'Returned';
    case LoanStatus.declined:
      return 'Declined';
    case LoanStatus.cancelled:
      return 'Cancelled';
  }
}

/// Items I lend, requests for them, and items I am borrowing.
class MyEquipmentScreen extends ConsumerWidget {
  const MyEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const Scaffold();
    final posts = ref.watch(postsProvider);
    final loans = ref.watch(loansProvider);
    final actions = ref.read(appActionsProvider);

    final mine = posts.where((p) => p.type == PostType.equipment && p.authorId == me.id).toList();
    final incoming = loans.where((l) => l.ownerId == me.id && l.isOpen).toList();
    final borrowing = loans.where((l) => l.borrowerId == me.id && l.isOpen).toList();
    final past = loans
        .where((l) => (l.ownerId == me.id || l.borrowerId == me.id) && !l.isOpen)
        .toList();

    String itemName(String postId) =>
        posts.where((p) => p.id == postId).firstOrNull?.equipmentItem ?? 'Item';
    String name(String id) => ref.watch(userByIdProvider(id))?.nickname ?? 'Neighbour';

    Widget header(String t) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('My equipment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          header('Requests for my items'),
          if (incoming.isEmpty)
            const Text('No requests right now.', style: TextStyle(color: kMuted)),
          for (final l in incoming)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${name(l.borrowerId)} · ${itemName(l.postId)}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    Text(_statusLabel(l.status), style: const TextStyle(color: kMuted)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (l.status == LoanStatus.requested) ...[
                          FilledButton(
                            onPressed: () => actions.setLoanStatus(l.id, LoanStatus.approved),
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => actions.setLoanStatus(l.id, LoanStatus.declined),
                            child: const Text('Decline'),
                          ),
                        ],
                        if (l.status == LoanStatus.approved)
                          FilledButton(
                            onPressed: () => actions.setLoanStatus(l.id, LoanStatus.pickedUp),
                            child: const Text('Mark picked up'),
                          ),
                        if (l.status == LoanStatus.pickedUp)
                          FilledButton(
                            onPressed: () => actions.setLoanStatus(l.id, LoanStatus.returned),
                            child: const Text('Mark returned'),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final id = await actions.startDm(l.borrowerId);
                            if (id != null && context.mounted) openChat(context, id);
                          },
                          child: const Text('Message'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          header('Items I lend'),
          if (mine.isEmpty)
            const Text('Tap ＋ then "Lend equipment" to list something.',
                style: TextStyle(color: kMuted)),
          for (final p in mine)
            Card(
              child: ListTile(
                leading: const Icon(Icons.handyman, color: kPrimary),
                title: Text(p.equipmentItem ?? 'Item',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(loans.any((l) => l.postId == p.id && l.holdsItem)
                    ? 'On loan'
                    : 'Available'),
                onTap: () => openPost(context, p.id),
              ),
            ),
          header("I'm borrowing"),
          if (borrowing.isEmpty)
            const Text('Nothing borrowed right now.', style: TextStyle(color: kMuted)),
          for (final l in borrowing)
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: kPrimary),
                title: Text('${itemName(l.postId)} from ${name(l.ownerId)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_statusLabel(l.status)),
                trailing: l.status == LoanStatus.requested
                    ? TextButton(
                        onPressed: () => actions.setLoanStatus(l.id, LoanStatus.cancelled),
                        child: const Text('Cancel'),
                      )
                    : null,
                onTap: () async {
                  final id = await actions.startDm(l.ownerId);
                  if (id != null && context.mounted) openChat(context, id);
                },
              ),
            ),
          if (past.isNotEmpty) ...[
            header('Past'),
            for (final l in past)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(itemName(l.postId)),
                subtitle: Text(
                    '${_statusLabel(l.status)} · ${fmtDate(l.returnedAt ?? l.requestedAt)}'),
              ),
          ],
        ],
      ),
    );
  }
}

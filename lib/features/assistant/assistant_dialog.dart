import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/post.dart';
import '../../core/utils/time_utils.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/tags.dart';
import '../challenges/challenge_detail_screen.dart';
import '../feed/post_card.dart';
import 'assistant_bubble.dart';
import 'assistant_controller.dart';

/// Opens the chat window so it grows out of the floating bubble. Tapping the
/// dimmed area outside closes it, and it shrinks back into the bubble.
Future<void> showAssistantDialog(BuildContext context) {
  assistantOpen.value = true;
  final origin = assistantBubbleCenter.value;
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Close assistant',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (_, __, ___) => const AssistantDialog(),
    transitionBuilder: (ctx, anim, _, child) {
      final size = MediaQuery.of(ctx).size;
      final from = origin ?? Offset(size.width - 40, size.height - 220);
      // The window is 85% x 68% of the screen, centred. Express the bubble's
      // position in the window's own coordinates so the scale starts there.
      final align = Alignment(
        (from.dx - size.width / 2) / (size.width * 0.425),
        (from.dy - size.height / 2) / (size.height * 0.34),
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
          alignment: align,
          child: child,
        ),
      );
    },
  ).whenComplete(() => assistantOpen.value = false);
}

const _examples = [
  'Run tomorrow morning with people my age',
  'Slow walk with seating this weekend',
  'Evening walk, women only, beginner',
  'Borrow a yoga mat',
  'How is the steps challenge going?',
];

/// Centred popup chat over a dimmed background. Text only.
class AssistantDialog extends ConsumerStatefulWidget {
  const AssistantDialog({super.key});

  @override
  ConsumerState<AssistantDialog> createState() => _AssistantDialogState();
}

class _AssistantDialogState extends ConsumerState<AssistantDialog> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  Animation<double>? _routeAnim;

  // As soon as the window starts shrinking, bring the bubble back so it pops
  // in right where the window is collapsing to.
  void _onRouteStatus(AnimationStatus st) {
    if (st == AnimationStatus.reverse) assistantOpen.value = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnim == null) {
      _routeAnim = ModalRoute.of(context)?.animation;
      _routeAnim?.addStatusListener(_onRouteStatus);
    }
  }

  @override
  void dispose() {
    _routeAnim?.removeStatusListener(_onRouteStatus);
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _ask(String text) async {
    if (text.trim().isEmpty) return;
    _input.clear();
    final f = ref.read(assistantProvider.notifier).ask(text);
    _toBottom();
    await f;
    _toBottom();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(assistantProvider);
    final size = MediaQuery.of(context).size;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.075, vertical: 40),
      backgroundColor: kBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: size.height * 0.68,
        child: Column(
          children: [
            Container(
              color: kPrimary,
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: kAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Ask NeighbourFit',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: st.messages.isEmpty
                  ? _Welcome(onPick: _ask)
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final m in st.messages) _MessageView(message: m, onSearchAgain: () => _focus.requestFocus()),
                        if (st.busy)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 10),
                                Text('Looking for neighbours…'),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _ask,
                      decoration: const InputDecoration(hintText: 'What would you like to do?'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
                    onPressed: st.busy ? null : () => _ask(_input.text),
                    icon: const Icon(Icons.send),
                    tooltip: 'Send',
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

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Hi! Tell me what you feel like doing and I will find neighbours to do it with.',
            style: TextStyle(fontSize: 17, height: 1.35)),
        const SizedBox(height: 14),
        const Text('Try one of these:', style: TextStyle(color: kMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in _examples)
              ActionChip(label: Text(e, style: const TextStyle(fontSize: 14)), onPressed: () => onPick(e)),
          ],
        ),
      ],
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, required this.onSearchAgain});

  final AssistantMessage message;
  final VoidCallback onSearchAgain;

  @override
  Widget build(BuildContext context) {
    if (message.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
          decoration: BoxDecoration(color: kSurfaceGreen, borderRadius: BorderRadius.circular(16)),
          child: Text(message.text, style: const TextStyle(fontSize: 16)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Text(message.text, style: const TextStyle(fontSize: 16, height: 1.3)),
        ),
        for (final r in message.results)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ResultCard(result: r, logId: message.logId),
          ),
        if (message.results.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onSearchAgain,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Search again'),
            ),
          ),
        if (message.note != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(message.note!, style: const TextStyle(color: kMuted, fontSize: 12)),
          ),
      ],
    );
  }
}

/// Compact version of the original post with one button. Tap = detail page.
class _ResultCard extends ConsumerWidget {
  const _ResultCard({required this.result, required this.logId});

  final AssistantResult result;
  final String? logId;

  void _log(WidgetRef ref, String action) {
    final id = logId;
    if (id == null) return;
    final r = result.result;
    ref.read(logsProvider.notifier).addAction(id, {
      if (r.post != null) 'postId': r.post!.id,
      if (r.challenge != null) 'challengeId': r.challenge!.id,
      'action': action,
      'at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = result.result;
    final liveTop = r.post == null ? null : ref.watch(postByIdProvider(r.post!.id));
    final Post? p = liveTop ?? r.post;

    if (r.challenge != null) {
      final c = ref.watch(challengesProvider).where((e) => e.id == r.challenge!.id).firstOrNull ?? r.challenge!;
      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChallengeDetailScreen(challengeId: c.id))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                      value: c.fraction, minHeight: 10, color: kGreen, backgroundColor: kSurfaceGreen),
                ),
                const SizedBox(height: 4),
                Text('${NumberFormat.decimalPattern().format(c.progress)} / ${NumberFormat.decimalPattern().format(c.target)} ${c.unit}',
                    style: const TextStyle(fontSize: 13, color: kMuted)),
              ],
            ),
          ),
        ),
      );
    }
    if (p == null) return const SizedBox.shrink();

    final author = ref.watch(userByIdProvider(p.authorId));
    final loc = ref.watch(referenceProvider).location(p.locationId);
    final isMeetup = p.type == PostType.meetup;
    final people = p.capacity == null ? '${p.memberIds.length} going' : '${p.memberIds.length}/${p.capacity} going';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _log(ref, 'viewed');
          openPost(context, p.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isMeetup ? sportIcon(p.sport) : Icons.handyman, size: 20, color: kPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isMeetup ? (p.title ?? 'Meetup') : (p.equipmentItem ?? 'Equipment'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (isMeetup && p.startsAt != null)
                Text(fmtDateTime(p.startsAt!), style: const TextStyle(fontSize: 14)),
              if (loc != null) Text(loc.name, style: const TextStyle(fontSize: 14, color: kMuted)),
              if (isMeetup) Text(people, style: const TextStyle(fontSize: 14, color: kMuted)),
              if (!isMeetup) Text('Owner: ${author?.nickname ?? 'Neighbour'}', style: const TextStyle(fontSize: 14, color: kMuted)),
              if (isMeetup && (p.safeBuddy || p.accessibilityFriendly)) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    if (p.safeBuddy) const InfoTag(icon: Icons.shield_outlined, label: 'Safe buddy'),
                    if (p.accessibilityFriendly) const InfoTag(icon: Icons.accessible, label: 'Accessible'),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(result.explanation,
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, height: 1.3)),
              const SizedBox(height: 8),
              if (isMeetup) MeetupButton(post: p, onJoin: () => _log(ref, 'joined')),
              if (!isMeetup) EquipmentButton(post: p),
            ],
          ),
        ),
      ),
    );
  }
}

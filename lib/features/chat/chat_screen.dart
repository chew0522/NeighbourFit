import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/conversation.dart';
import '../../core/utils/time_utils.dart';
import '../../services/privacy_guard.dart';
import '../../state/actions.dart';
import '../../state/app_state.dart';
import '../../widgets/avatar.dart';
import '../../widgets/ui_helpers.dart';
import '../feed/post_card.dart';

/// DM or meetup group chat. Chat is local and simulated: neighbours reply with
/// canned messages (MOCK).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.convId});

  final String convId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(Conversation c) async {
    final me = ref.read(currentUserProvider);
    final text = _input.text.trim();
    if (me == null || text.isEmpty) return;
    if (PrivacyGuard.looksSensitive(text)) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Share personal details?'),
          content: const Text(
            'This looks like a phone number or an address. For your safety, keep personal details out of chat until you know each other.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Edit message')),
            OutlinedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send anyway')),
          ],
        ),
      );
      if (go != true) return;
    }
    _input.clear();
    await ref.read(chatProvider.notifier).send(c.id, me.id, text);
  }

  Future<void> _report() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Report this chat'),
        children: [
          for (final r in ['Spam or ads', 'Rude or unkind', 'Feels unsafe', 'Something else'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: Text(r, style: const TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
    // MOCK: nothing is sent anywhere in the prototype.
    if (reason != null) showSnack('Thanks. The township team will take a look.');
  }

  Future<void> _block(Conversation c, String otherId, String name) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final ok = await confirmDialog(
      context,
      title: 'Block $name?',
      message: "You won't see their posts or messages, and they won't appear in suggestions.",
      confirmLabel: 'Block',
    );
    if (!ok) return;
    await ref.read(usersProvider.notifier).block(me.id, otherId);
    await ref.read(chatProvider.notifier).markBlocked(c.id);
    if (mounted) Navigator.of(context).pop();
    showSnack('$name is blocked.');
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final c = ref.watch(chatProvider).where((e) => e.id == widget.convId).firstOrNull;
    if (c == null || me == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.chat_bubble_outline, message: 'This chat is not available.'),
      );
    }
    final otherId = c.memberIds.firstWhere((e) => e != me.id, orElse: () => '');
    final other = ref.watch(userByIdProvider(otherId));
    final post = c.sourcePostId == null ? null : ref.watch(postByIdProvider(c.sourcePostId!));
    final ended = c.isGroup &&
        post?.startsAt != null &&
        DateTime.now().isAfter(post!.startsAt!.add(const Duration(hours: 3)));
    final title = c.isGroup ? (c.title ?? 'Meetup chat') : (other?.nickname ?? 'Neighbour');
    final msgs = c.messages.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(c.isGroup ? '${c.memberIds.length} members' : 'Direct message',
                style: const TextStyle(fontSize: 12, color: kMuted)),
          ],
        ),
        actions: [
          if (post != null)
            IconButton(
              tooltip: 'Open meetup',
              icon: const Icon(Icons.event),
              onPressed: () => openPost(context, post.id),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'report') _report();
              if (v == 'block') _block(c, otherId, other?.nickname ?? 'this neighbour');
              if (v == 'leave' && post != null) {
                ref.read(appActionsProvider).leaveMeetup(post);
                Navigator.of(context).pop();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'report', child: Text('Report')),
              if (!c.isGroup) const PopupMenuItem(value: 'block', child: Text('Block')),
              if (c.isGroup && post != null && post.authorId != me.id && !ended)
                const PopupMenuItem(value: 'leave', child: Text('Leave meetup')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: msgs.isEmpty
                ? const EmptyState(
                    icon: Icons.waving_hand_outlined,
                    message: 'Say hello! Keep it friendly and keep personal details private.')
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) => _Bubble(message: msgs[i], isGroup: c.isGroup),
                  ),
          ),
          if (ended)
            Container(
              width: double.infinity,
              color: kSurfaceGreen,
              padding: const EdgeInsets.all(14),
              child: const Text('This meetup has ended. The chat is read-only.',
                  textAlign: TextAlign.center),
            )
          else
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(hintText: 'Write a message'),
                        onSubmitted: (_) => _send(c),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
                      onPressed: () => _send(c),
                      icon: const Icon(Icons.send),
                      tooltip: 'Send message',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.message, required this.isGroup});

  final Message message;
  final bool isGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(message.text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted, fontSize: 13)),
        ),
      );
    }
    final me = ref.watch(currentUserProvider);
    final mine = message.senderId == me?.id;
    final sender = ref.watch(userByIdProvider(message.senderId));
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine && isGroup)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(user: sender, radius: 9),
                  const SizedBox(width: 6),
                  Text(sender?.nickname ?? 'Neighbour',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPrimary)),
                ],
              ),
            Text(message.text,
                style: TextStyle(fontSize: 16, color: mine ? Colors.white : kText)),
            const SizedBox(height: 2),
            Text(fmtTime(message.createdAt),
                style: TextStyle(fontSize: 11, color: mine ? Colors.white70 : kMuted)),
          ],
        ),
      ),
    );
  }
}

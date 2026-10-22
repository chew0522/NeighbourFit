import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/parsed_query.dart';
import '../../core/models/recommendation_log.dart';
import '../../core/utils/ids.dart';
import '../../services/ai_service.dart';
import '../../services/keyword_parser.dart';
import '../../services/matching_engine.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';

class AssistantResult {
  const AssistantResult(this.result, this.explanation);

  final ScoredResult result;
  final String explanation;
}

class AssistantMessage {
  const AssistantMessage({
    required this.fromUser,
    required this.text,
    this.results = const [],
    this.logId,
    this.note,
    this.requestItem,
    required this.at,
  });

  final bool fromUser;
  final String text;
  final List<AssistantResult> results;
  final String? logId;

  /// Small grey line, e.g. when the offline parser was used.
  final String? note;

  /// Set when nobody can lend the item: the chat offers to post a request.
  /// May be empty when the item is unknown.
  final String? requestItem;
  final DateTime at;
}

class AssistantState {
  const AssistantState({this.messages = const [], this.busy = false});

  final List<AssistantMessage> messages;
  final bool busy;
}

/// Orchestrates one question: understand (AI or keyword fallback), filter and
/// score on-device, explain (AI or template), log. The AI never ranks.
class AssistantNotifier extends Notifier<AssistantState> {
  @override
  AssistantState build() => const AssistantState();

  void clear() => state = const AssistantState();

  Future<void> ask(String raw) async {
    final text = raw.trim();
    final me = ref.read(currentUserProvider);
    if (me == null || text.isEmpty || state.busy) return;
    final now = DateTime.now();
    state = AssistantState(
      messages: [
        ...state.messages,
        AssistantMessage(fromUser: true, text: text, at: now),
      ],
      busy: true,
    );

    final ai = ref.read(aiServiceProvider);
    ParsedQuery q;
    var usedAi = false;
    String? note;
    try {
      if (!ai.available) throw AiException('No key');
      q = await ai.parseQuery(text, now);
      usedAi = true;
    } catch (_) {
      q = const KeywordParser().parse(text, now);
      note = ai.available
          ? 'The AI was slow or unavailable, so I used simple matching.'
          : 'Offline mode: using simple matching.';
    }

    final data = EngineData(
      me: me,
      users: ref.read(usersProvider),
      posts: ref.read(postsProvider),
      challenges: ref.read(challengesProvider),
      loans: ref.read(loansProvider),
      ref: ref.read(referenceProvider),
      now: now,
    );
    final results = ref.read(matchingEngineProvider).recommend(q, data);

    // Explanations: AI wording when possible, otherwise from the facts.
    var explanations = results.map(_template).toList();
    if (usedAi &&
        results.isNotEmpty &&
        (q.intent == QueryIntent.findActivity ||
            q.intent == QueryIntent.findEquipment)) {
      try {
        explanations = await ai.explainResults(q, [
          for (final r in results)
            ExplainItem(
              label: _label(r),
              facts: r.facts,
              score: r.score.round(),
            ),
        ]);
      } catch (_) {
        // keep the template explanations
      }
    }

    String? logId;
    if (q.intent != QueryIntent.other) {
      logId = newId('log_');
      await ref
          .read(logsProvider.notifier)
          .add(
            RecommendationLog(
              id: logId,
              userId: me.id,
              kind: 'activity',
              query: text,
              parsed: q.toJson(),
              results: [
                for (final r in results)
                  {
                    if (r.post != null) 'postId': r.post!.id,
                    if (r.challenge != null) 'challengeId': r.challenge!.id,
                    'score': r.score,
                    'factors': r.fits,
                  },
              ],
              createdAt: now,
            ),
          );
    }

    final reply = AssistantMessage(
      fromUser: false,
      text: _intro(q, results.length),
      results: [
        for (var i = 0; i < results.length; i++)
          AssistantResult(results[i], explanations[i]),
      ],
      logId: logId,
      note: note,
      requestItem: q.intent == QueryIntent.findEquipment && results.isEmpty
          ? (q.equipmentItem ?? '')
          : null,
      at: DateTime.now(),
    );
    state = AssistantState(messages: [...state.messages, reply], busy: false);
  }

  String _label(ScoredResult r) =>
      r.post?.title ?? r.post?.equipmentItem ?? r.challenge?.title ?? 'Result';

  String _template(ScoredResult r) {
    final facts = r.facts.take(2).join(', ');
    return facts.isEmpty ? '${_label(r)}.' : '${_label(r)}: $facts.';
  }

  String _intro(ParsedQuery q, int count) {
    switch (q.intent) {
      case QueryIntent.findActivity:
        return count == 0
            ? 'I could not find a meetup that fits. Try another day or time, or start your own with the ＋ button.'
            : (count == 1
                  ? 'I found one good match:'
                  : 'Here are your top $count matches:');
      case QueryIntent.findEquipment:
        return count == 0
            ? 'Nobody is lending that right now. You can ask your neighbours with a request.'
            : 'These neighbours can lend it:';
      case QueryIntent.challengeInfo:
        return count == 0
            ? 'There is no active community challenge right now.'
            : 'Here is the community challenge:';
      case QueryIntent.other:
        return 'I can help you find meetups, borrow equipment, or check the community challenge. '
            'Try "run tomorrow morning with people my age".';
    }
  }
}

final assistantProvider = NotifierProvider<AssistantNotifier, AssistantState>(
  AssistantNotifier.new,
);

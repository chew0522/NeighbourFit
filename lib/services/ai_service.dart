import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/ai_config.dart';
import '../core/models/json_utils.dart';
import '../core/models/parsed_query.dart';

class AiException implements Exception {
  AiException(this.message);
  final String message;

  @override
  String toString() => 'AiException: $message';
}

/// One recommendation reduced to plain facts for the explanation call.
class ExplainItem {
  const ExplainItem({
    required this.label,
    required this.facts,
    required this.score,
  });

  final String label;
  final List<String> facts;
  final int score;
}

/// DeepSeek (OpenAI-compatible) client. It only translates between plain
/// language and structured data. It never ranks anything. Callers must catch
/// [AiException] and fall back.
class AiService {
  AiService(this.config, {http.Client? client})
    : _client = client ?? http.Client();

  final AiConfig config;
  final http.Client _client;

  bool get available => config.hasKey;

  static const _parseSystem = '''
You are a parser for a neighbourhood exercise app. Today's date is {today}. Convert the user's message into JSON that exactly matches this schema. Output JSON only, no explanation. Use null when the user did not specify a field. Use "same_group" for agePref only if they ask for people of a similar age. Use genderFilter only if they explicitly ask for women-only or men-only.

Schema:
{
  "intent": "find_activity | find_equipment | challenge_info | other",
  "sport": "running | walking | cycling | badminton | yoga | swimming | gym | other | null",
  "timeSlot": "morning | afternoon | evening | weekend | null",
  "date": "YYYY-MM-DD | null",
  "dayHint": "this_weekend | null",
  "agePref": "same_group | any",
  "genderFilter": "women_only | men_only | none",
  "level": "beginner | intermediate | advanced | null",
  "nearMe": false,
  "equipmentItem": "string | null"
}
Intent guide:
- find_activity: wants to exercise or join a workout, run, walk, class or meetup.
- find_equipment: wants to borrow or lend equipment (racket, mat, bike, weights).
- challenge_info: asks about community challenges, points, streaks, rewards, vouchers or progress, e.g. "how do I unlock the 7-day streak reward", "how many points do I need", "how is the steps challenge going".
- other: anything unrelated to exercise, equipment or challenges.
Convert "today", "tomorrow", "next Saturday" or "24 Oct" into a concrete ISO date. Use dayHint "this_weekend" only for the vague phrase "this weekend".''';

  static const _explainSystem = '''
You write short, friendly explanations for neighbourhood exercise recommendations. Use only the facts and scores provided. Do not invent people, times or places. Maximum 2 sentences per recommendation. Friendly, concise English.
Respond with JSON only: {"explanations": ["...", "..."]} with one entry per recommendation, in the same order.''';

  Future<String> _chat(String system, String user) async {
    if (!available) throw AiException('No API key configured');
    final uri = Uri.parse('${config.baseUrl}/chat/completions');
    final http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.apiKey}',
            },
            body: jsonEncode({
              'model': config.model,
              'temperature': 0.1,
              'response_format': {'type': 'json_object'},
              'messages': [
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': user},
              ],
            }),
          )
          .timeout(config.timeout);
    } on TimeoutException {
      throw AiException('Timed out');
    } catch (e) {
      throw AiException('Network error: $e');
    }
    if (res.statusCode != 200) throw AiException('HTTP ${res.statusCode}');
    try {
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      return content;
    } catch (_) {
      throw AiException('Unexpected response');
    }
  }

  Map<String, dynamic> _decode(String content) {
    final cleaned = content.replaceAll(RegExp(r'```(?:json)?'), '').trim();
    try {
      final v = jsonDecode(cleaned);
      if (v is Map) return Map<String, dynamic>.from(v);
    } catch (_) {}
    throw AiException('Invalid JSON');
  }

  /// Text -> structured query. Throws [AiException] on any failure.
  Future<ParsedQuery> parseQuery(String text, DateTime now) async {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final today =
        '${weekdays[now.weekday - 1]} ${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final content = await _chat(
      _parseSystem.replaceAll('{today}', today),
      text,
    );
    return ParsedQuery.fromAiJson(_decode(content), now);
  }

  /// Friendly sentence per result, from the computed facts only. Throws on
  /// failure; callers use a template instead.
  Future<List<String>> explainResults(
    ParsedQuery q,
    List<ExplainItem> items,
  ) async {
    final payload = jsonEncode({
      'request': q.toJson(),
      'recommendations': items
          .map((e) => {'title': e.label, 'score': e.score, 'facts': e.facts})
          .toList(),
    });
    final json = _decode(await _chat(_explainSystem, payload));
    final list = json['explanations'];
    if (list is! List || list.length < items.length) {
      throw AiException('Explanation count mismatch');
    }
    return strList(list).take(items.length).toList();
  }
}

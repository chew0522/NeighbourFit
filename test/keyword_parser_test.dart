import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourfit/core/models/enums.dart';
import 'package:neighbourfit/core/models/parsed_query.dart';
import 'package:neighbourfit/services/keyword_parser.dart';

void main() {
  const parser = KeywordParser();
  final now = DateTime(2026, 10, 16, 10); // Friday

  test('"run tomorrow morning with people my age"', () {
    final q = parser.parse('run tomorrow morning with people my age', now);
    expect(q.intent, QueryIntent.findActivity);
    expect(q.sport, Sport.running);
    expect(q.timeSlot, TimeSlot.morning);
    expect(q.date, DateTime(2026, 10, 17));
    expect(q.sameGroupAge, isTrue);
  });

  test('"evening walk, women only, beginner"', () {
    final q = parser.parse('evening walk, women only, beginner', now);
    expect(q.sport, Sport.walking);
    expect(q.timeSlot, TimeSlot.evening);
    expect(q.genderFilter, 'women_only');
    expect(q.level, Level.beginner);
  });

  test('"borrow a badminton racket"', () {
    final q = parser.parse('borrow a badminton racket', now);
    expect(q.intent, QueryIntent.findEquipment);
    expect(q.equipmentItem, 'badminton racket');
  });

  test('weekend phrases set the weekend hint', () {
    final q = parser.parse('yoga this weekend', now);
    expect(q.sport, Sport.yoga);
    expect(q.thisWeekend, isTrue);
    expect(q.timeSlot, TimeSlot.weekend);
  });

  test('challenge questions', () {
    final q = parser.parse('how is the steps challenge going', now);
    expect(q.intent, QueryIntent.challengeInfo);
  });

  test('nonsense falls back to "other"', () {
    final q = parser.parse('what is the weather like', now);
    expect(q.intent, QueryIntent.other);
  });

  group('AI output validation', () {
    test('past dates and unknown values are ignored', () {
      final q = ParsedQuery.fromAiJson({
        'intent': 'find_activity',
        'sport': 'curling',
        'timeSlot': 'noon',
        'date': '2020-01-01',
        'genderFilter': 'robots_only',
        'level': 'expert',
        'extra': 'ignored',
      }, now);
      expect(q.sport, isNull);
      expect(q.timeSlot, isNull);
      expect(q.date, isNull);
      expect(q.genderFilter, 'none');
      expect(q.level, isNull);
    });

    test('valid future date and fields are kept', () {
      final q = ParsedQuery.fromAiJson({
        'intent': 'find_activity',
        'sport': 'running',
        'timeSlot': 'morning',
        'date': '2026-10-17',
        'agePref': 'same_group',
      }, now);
      expect(q.sport, Sport.running);
      expect(q.date, DateTime(2026, 10, 17));
      expect(q.sameGroupAge, isTrue);
    });
  });
}

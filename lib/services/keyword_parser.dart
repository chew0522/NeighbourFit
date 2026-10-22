import '../core/models/enums.dart';
import '../core/models/parsed_query.dart';
import '../core/utils/time_utils.dart';

/// Offline fallback for the AI parser. Plain keyword rules, see
/// docs/MATCHING.md section 3.
class KeywordParser {
  const KeywordParser();

  static final _equipmentItem = RegExp(
    r'\b((?:\w+\s+)?(?:mat|racket|racquet|helmet|dumbbells?|weights|bicycle|bike|ball|shoes))\b',
  );

  ParsedQuery parse(String input, DateTime now) {
    final t = input.toLowerCase();
    bool has(String pattern) => RegExp(pattern).hasMatch(t);

    // Equipment intent comes first.
    final wantsEquipment =
        has(r'\b(borrow|lend|lending|rent)\b') ||
        has(r'\b(mat|racket|racquet|helmet|dumbbells?)\b');
    if (wantsEquipment) {
      String? item;
      final borrow = RegExp(
        r'\b(?:borrow|lend|rent)\s+(?:a|an|the|some)?\s*([a-z][a-z\s]*)',
      ).firstMatch(t);
      if (borrow != null) {
        item = borrow.group(1)!.trim();
        item = item
            .replaceAll(RegExp(r'\b(please|today|tomorrow|now)\b.*$'), '')
            .trim();
      }
      item ??= _equipmentItem.firstMatch(t)?.group(1)?.trim();
      return ParsedQuery(
        intent: QueryIntent.findEquipment,
        equipmentItem: (item == null || item.isEmpty) ? null : item,
      );
    }

    Sport? sport;
    if (has(r'\b(run|running|jog|jogging)\b')) {
      sport = Sport.running;
    } else if (has(r'\b(walk|walking|brisk)\b')) {
      sport = Sport.walking;
    } else if (has(r'\b(cycle|cycling|bike|biking|ride)\b')) {
      sport = Sport.cycling;
    } else if (has(r'\bbadminton\b')) {
      sport = Sport.badminton;
    } else if (has(r'\byoga\b')) {
      sport = Sport.yoga;
    } else if (has(r'\b(swim|swimming|pool)\b')) {
      sport = Sport.swimming;
    } else if (has(r'\b(gym|workout|weights)\b')) {
      sport = Sport.gym;
    }

    TimeSlot? slot;
    if (has(r'\b(morning|sunrise|dawn)\b')) {
      slot = TimeSlot.morning;
    } else if (has(r'\bafternoon\b')) {
      slot = TimeSlot.afternoon;
    } else if (has(r'\b(evening|night|tonight|after work)\b')) {
      slot = TimeSlot.evening;
    }

    final weekend = has(r'\b(weekend|saturday|sunday)\b');
    if (slot == null && weekend) slot = TimeSlot.weekend;

    DateTime? date;
    if (has(r'\btomorrow\b')) {
      date = dateOnly(now).add(const Duration(days: 1));
    } else if (has(r'\b(today|tonight)\b')) {
      date = dateOnly(now);
    }

    final sameGroup = has(r'\b(my age|same age|similar age)\b');
    var gender = 'none';
    if (has(
      r'\b(women only|women-only|girls only|female only|ladies only)\b',
    )) {
      gender = 'women_only';
    } else if (has(r'\b(men only|men-only|boys only|male only)\b')) {
      gender = 'men_only';
    }
    Level? level;
    if (has(r'\b(beginner|beginners|newbie|new to)\b')) {
      level = Level.beginner;
    } else if (has(r'\bintermediate\b')) {
      level = Level.intermediate;
    } else if (has(r'\badvanced\b')) {
      level = Level.advanced;
    }
    final nearMe = has(r'\b(near|nearby|close|closest)\b');

    final anything =
        sport != null ||
        slot != null ||
        date != null ||
        weekend ||
        sameGroup ||
        gender != 'none' ||
        level != null ||
        nearMe ||
        has(
          r'\b(meetup|activity|group|join|anyone|buddy|partner|exercise|people)\b',
        );

    if (!anything &&
        has(
          r'\b(challenge|steps|10,?000|streak|reward|rewards|points|voucher)\b',
        )) {
      return const ParsedQuery(intent: QueryIntent.challengeInfo);
    }
    if (!anything) return const ParsedQuery(intent: QueryIntent.other);

    return ParsedQuery(
      intent: QueryIntent.findActivity,
      sport: sport,
      timeSlot: slot,
      date: date,
      thisWeekend: weekend,
      sameGroupAge: sameGroup,
      genderFilter: gender,
      level: level,
      nearMe: nearMe,
    );
  }
}

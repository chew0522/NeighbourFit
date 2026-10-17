import 'package:intl/intl.dart';

import '../models/enums.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Part of the day plus 'weekend' when it falls on Saturday or Sunday.
Set<TimeSlot> slotsFor(DateTime t) {
  final s = <TimeSlot>{};
  if (t.hour < 12) {
    s.add(TimeSlot.morning);
  } else if (t.hour < 18) {
    s.add(TimeSlot.afternoon);
  } else {
    s.add(TimeSlot.evening);
  }
  if (t.weekday == DateTime.saturday || t.weekday == DateTime.sunday) {
    s.add(TimeSlot.weekend);
  }
  return s;
}

String partOfDayLabel(DateTime t) {
  if (t.hour < 12) return 'Morning';
  if (t.hour < 18) return 'Afternoon';
  return 'Evening';
}

String fmtDateTime(DateTime d) => DateFormat('EEE d MMM · h:mm a').format(d);

String fmtDate(DateTime d) => DateFormat('EEE d MMM').format(d);

String fmtTime(DateTime d) => DateFormat('h:mm a').format(d);

String timeAgo(DateTime t, DateTime now) {
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return fmtDate(t);
}

/// Saturdays and Sundays from today through the next 7 days.
List<DateTime> upcomingWeekendDates(DateTime now) {
  final today = dateOnly(now);
  final out = <DateTime>[];
  for (var i = 0; i < 8; i++) {
    final d = today.add(Duration(days: i));
    if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
      out.add(d);
    }
  }
  return out;
}

int daysLeft(DateTime end, DateTime now) {
  final d = dateOnly(end).difference(dateOnly(now)).inDays;
  return d < 0 ? 0 : d;
}

/// Seed files store times as offsets from "now", for example
/// {"days": 1, "time": "06:30"} or {"nextWeekday": 6, "time": "06:30"}
/// (1 = Monday ... 7 = Sunday, always strictly after today).
DateTime resolveOffset(Map<String, dynamic> off, DateTime now) {
  final time = (off['time'] as String? ?? '09:00').split(':');
  final h = int.tryParse(time[0]) ?? 9;
  final m = time.length > 1 ? (int.tryParse(time[1]) ?? 0) : 0;
  var day = dateOnly(now);
  if (off['nextWeekday'] != null) {
    final target = (off['nextWeekday'] as num).toInt();
    day = day.add(const Duration(days: 1));
    while (day.weekday != target) {
      day = day.add(const Duration(days: 1));
    }
    day = day.add(Duration(days: (off['plusWeeks'] as num?)?.toInt() ?? 0) * 7);
  } else {
    day = day.add(Duration(days: (off['days'] as num?)?.toInt() ?? 0));
  }
  return DateTime(day.year, day.month, day.day, h, m);
}

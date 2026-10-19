import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/utils/time_utils.dart';

/// Calendar picker for the date and a time picker for the time. No typing.
/// Past dates are greyed out; if today is chosen, earlier times are refused.
class DateTimeField extends StatefulWidget {
  const DateTimeField({super.key, this.initial, required this.onChanged});

  final DateTime? initial;

  /// Called with the combined value, or null while either part is missing.
  final ValueChanged<DateTime?> onChanged;

  @override
  State<DateTimeField> createState() => _DateTimeFieldState();
}

class _DateTimeFieldState extends State<DateTimeField> {
  DateTime? _date;
  TimeOfDay? _time;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _date = dateOnly(i);
      _time = TimeOfDay(hour: i.hour, minute: i.minute);
    }
  }

  DateTime? get _combined => (_date == null || _time == null)
      ? null
      : DateTime(
          _date!.year,
          _date!.month,
          _date!.day,
          _time!.hour,
          _time!.minute,
        );

  void _emit() {
    final c = _combined;
    if (c != null && !c.isAfter(DateTime.now())) {
      setState(
        () => _error = 'That time has already passed. Choose a later time.',
      );
      widget.onChanged(null);
      return;
    }
    setState(() => _error = null);
    widget.onChanged(c);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? dateOnly(now),
      firstDate: dateOnly(now),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d == null) return;
    _date = dateOnly(d);
    _emit();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (t == null) return;
    final now = DateTime.now();
    if (_date != null && sameDay(_date!, now)) {
      final picked = DateTime(now.year, now.month, now.day, t.hour, t.minute);
      if (!picked.isAfter(now)) {
        setState(
          () => _error = 'That time has already passed. Choose a later time.',
        );
        return;
      }
    }
    _time = t;
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(_date == null ? 'Pick a date' : fmtDate(_date!)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(
                  _time == null ? 'Pick a time' : _time!.format(context),
                ),
              ),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 14),
            ),
          ),
      ],
    );
  }
}

/// Section label used in forms.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: kText,
      ),
    ),
  );
}

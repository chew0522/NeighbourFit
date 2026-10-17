import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import 'compose_forms.dart';
import 'meetup_form.dart';

/// The ＋ sheet: four large rows, one tap to the matching form.
Future<void> showComposeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) {
      void go(Widget page) {
        Navigator.of(sheetContext).pop();
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Row(
                icon: Icons.directions_run,
                title: 'Share a workout',
                subtitle: 'Tell your neighbours what you did today',
                onTap: () => go(const WorkoutForm()),
              ),
              _Row(
                icon: Icons.restaurant,
                title: 'Share a healthy meal',
                subtitle: 'A meal that fits a healthy lifestyle',
                onTap: () => go(const MealForm()),
              ),
              _Row(
                icon: Icons.groups,
                title: 'Start a meetup',
                subtitle: 'Want company? Tell neighbours when and where',
                onTap: () => go(const MeetupForm()),
              ),
              _Row(
                icon: Icons.handyman,
                title: 'Lend equipment',
                subtitle: 'A mat, racket or bike someone can borrow',
                onTap: () => go(const EquipmentForm()),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: kSurfaceGreen, shape: BoxShape.circle),
              child: Icon(icon, color: kPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kMuted),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/models/enums.dart';

IconData sportIcon(Sport? s) {
  switch (s) {
    case Sport.running:
      return Icons.directions_run;
    case Sport.walking:
      return Icons.directions_walk;
    case Sport.cycling:
      return Icons.directions_bike;
    case Sport.badminton:
      return Icons.sports_tennis;
    case Sport.yoga:
      return Icons.self_improvement;
    case Sport.swimming:
      return Icons.pool;
    case Sport.gym:
      return Icons.fitness_center;
    case Sport.other:
    case null:
      return Icons.sports;
  }
}

/// Post type shown as a small icon plus one word, in one calm style.
class TypeLabel extends StatelessWidget {
  const TypeLabel({super.key, required this.type, this.sport});

  final PostType type;
  final Sport? sport;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final String label;
    switch (type) {
      case PostType.sport:
        icon = sportIcon(sport);
        label = 'Workout';
      case PostType.meal:
        icon = Icons.restaurant;
        label = 'Healthy meal';
      case PostType.meetup:
        icon = sportIcon(sport);
        label = 'Meetup';
      case PostType.equipment:
        icon = Icons.handyman;
        label = 'Equipment';
      case PostType.challenge:
        icon = Icons.emoji_events;
        label = 'Challenge';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: kPrimary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
      ],
    );
  }
}

/// Small tag with icon and tiny label (level, language, etc).
class InfoTag extends StatelessWidget {
  const InfoTag({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kSurfaceGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: kText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

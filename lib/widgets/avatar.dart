import 'package:flutter/material.dart';

import '../core/models/user_profile.dart';

/// Round avatar with the user's initials on their chosen colour.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 20});

  final UserProfile? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = Color(user?.avatarColor ?? 0xFF6B7280);
    final dark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        user?.initials ?? '?',
        style: TextStyle(
          color: dark ? Colors.white : const Color(0xFF1F2A37),
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../core/models/user_profile.dart';
import '../../widgets/avatar.dart';

/// Full-width rectangular row for a neighbour. Tap opens their profile.
class NeighbourRow extends StatelessWidget {
  const NeighbourRow({
    super.key,
    required this.user,
    required this.subtitle,
    required this.onTap,
    this.onDismiss,
  });

  final UserProfile user;
  final String subtitle;
  final VoidCallback onTap;

  /// Shows a small "not now" cross when set.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              UserAvatar(user: user, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.nickname,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: kMuted)),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  tooltip: 'Not now',
                  icon: const Icon(Icons.close, size: 20, color: kMuted),
                  onPressed: onDismiss,
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right, color: kMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

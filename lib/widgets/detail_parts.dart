import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/models/reference_models.dart';
import 'ui_helpers.dart';

/// Building blocks shared by the post detail pages (meetup, workout, meal,
/// equipment), so they look like one family.

/// White rounded card with a soft shadow.
class DetailPanel extends StatelessWidget {
  const DetailPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
      ],
    ),
    child: child,
  );
}

class DetailIconTile extends StatelessWidget {
  const DetailIconTile({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: kSurfaceGreen,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(icon, color: kPrimary, size: 26),
  );
}

class DetailPill extends StatelessWidget {
  const DetailPill({
    super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class DetailBanner extends StatelessWidget {
  const DetailBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.35)),
        ),
      ],
    ),
  );
}

/// Translucent chip shown on a header.
class HeroChip extends StatelessWidget {
  const HeroChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

/// The cream strip with rounded top corners that overlaps the bottom of a header.
PreferredSizeWidget detailHeaderEdge() => PreferredSize(
  preferredSize: const Size.fromHeight(26),
  child: Container(
    height: 26,
    decoration: const BoxDecoration(
      color: kBackground,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  ),
);

/// Round translucent back button for use over a header.
Widget detailBackButton(BuildContext context) => Padding(
  padding: const EdgeInsets.all(8),
  child: Material(
    color: Colors.black38,
    shape: const CircleBorder(),
    child: BackButton(
      color: Colors.white,
      onPressed: () => Navigator.of(context).pop(),
    ),
  ),
);

/// Bar fixed at the bottom of a detail page, holding its main action.
class DetailActionBar extends StatelessWidget {
  const DetailActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: child,
      ),
    ),
  );
}

/// Place name and a Google Maps button.
class WherePanel extends StatelessWidget {
  const WherePanel({super.key, required this.location});

  final PresetLocation location;

  @override
  Widget build(BuildContext context) => DetailPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const DetailIconTile(icon: Icons.place_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
          onPressed: () => openUrl(location.mapsUrl),
          icon: const Icon(Icons.directions_rounded, size: 20),
          label: const Text('Open in Google Maps'),
        ),
      ],
    ),
  );
}

/// Fades its child out as the surrounding SliverAppBar collapses, so header
/// tags never collide with the title as it moves up.
class CollapseFade extends StatelessWidget {
  const CollapseFade({super.key, required this.child, this.invert = false});

  final Widget child;

  /// When true the child is hidden while expanded and shown once collapsed
  /// (used for the small title in the app bar).
  final bool invert;

  @override
  Widget build(BuildContext context) {
    final s = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    var opacity = 1.0;
    if (s != null && s.maxExtent > s.minExtent) {
      final t = (s.currentExtent - s.minExtent) / (s.maxExtent - s.minExtent);
      opacity = invert
          ? ((0.45 - t) / 0.25).clamp(0.0, 1.0)
          : ((t - 0.6) / 0.3).clamp(0.0, 1.0);
    }
    return Opacity(opacity: opacity, child: child);
  }
}

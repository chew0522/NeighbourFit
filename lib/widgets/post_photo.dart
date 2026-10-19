import 'dart:io';

import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// A post photo. Seed photos are assets under `post_pic/`; photos added by
/// users are files saved on the device.
Widget photoImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  int cacheWidth = 1200,
}) {
  Widget broken() => Container(
    color: kSurfaceGreen,
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image_outlined, color: kMuted, size: 36),
  );
  if (path.startsWith('post_pic/')) {
    return Image.asset(
      path,
      fit: fit,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => broken(),
    );
  }
  return Image.file(
    File(path),
    fit: fit,
    cacheWidth: cacheWidth,
    gaplessPlayback: true,
    errorBuilder: (_, __, ___) => broken(),
  );
}

/// Rounded photo shown on a card or detail page. Tap to open the zoomable viewer.
class PostPhoto extends StatelessWidget {
  const PostPhoto({
    super.key,
    required this.path,
    required this.heroTag,
    this.aspectRatio = 4 / 5,
  });

  final String path;
  final String heroTag;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openPhotoViewer(context, path, heroTag),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Hero(tag: heroTag, child: photoImage(path)),
        ),
      ),
    );
  }
}

void openPhotoViewer(BuildContext context, String path, String heroTag) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) =>
          PhotoViewerScreen(path: path, heroTag: heroTag),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

/// Full-screen photo. Pinch to zoom in and out, drag to look around, double
/// tap to zoom in and back, tap the cross to close.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.path,
    required this.heroTag,
  });

  final String path;
  final String heroTag;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TransformationController();
  late final AnimationController _anim;
  Animation<Matrix4>? _zoomAnim;
  Offset _doubleTapAt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          final a = _zoomAnim;
          if (a != null) _controller.value = a.value;
        });
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final zoomedIn = _controller.value.getMaxScaleOnAxis() > 1.05;
    final Matrix4 end;
    if (zoomedIn) {
      end = Matrix4.identity();
    } else {
      const scale = 2.6;
      final p = _doubleTapAt;
      // Zoom into the point that was tapped.
      end = Matrix4.identity()
        ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    }
    _zoomAnim = Matrix4Tween(
      begin: _controller.value,
      end: end,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
              onDoubleTap: _toggleZoom,
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1,
                maxScale: 6,
                child: Center(
                  child: Hero(
                    tag: widget.heroTag,
                    child: photoImage(
                      widget.path,
                      fit: BoxFit.contain,
                      cacheWidth: 2400,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton.filled(
                  tooltip: 'Close',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

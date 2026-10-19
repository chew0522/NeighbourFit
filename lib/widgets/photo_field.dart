import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_theme.dart';
import '../core/utils/ids.dart';
import 'ui_helpers.dart';

/// Optional photo for a post. Tap to take a photo or choose one; a chosen photo
/// can be changed or removed. The photo is copied into the app's own folder so
/// it is still there after the app restarts.
class PhotoField extends StatelessWidget {
  const PhotoField({super.key, required this.path, required this.onChanged});

  final String? path;
  final ValueChanged<String?> onChanged;

  Future<void> _choose(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (path != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  onChanged(null);
                },
              ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/post_photos');
      if (!folder.existsSync()) folder.createSync(recursive: true);
      final saved = await File(
        picked.path,
      ).copy('${folder.path}/${newId()}.jpg');
      onChanged(saved.path);
    } catch (_) {
      showSnack('Could not add the photo. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _choose(context),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder, width: 1.5),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 32, color: kPrimary),
              SizedBox(height: 6),
              Text(
                'Add a photo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text('Optional', style: TextStyle(color: kMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Image.file(File(path!), fit: BoxFit.cover, cacheWidth: 1000),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _Round(
                icon: Icons.edit_outlined,
                tooltip: 'Change photo',
                onTap: () => _choose(context),
              ),
              const SizedBox(width: 8),
              _Round(
                icon: Icons.close_rounded,
                tooltip: 'Remove photo',
                onTap: () => onChanged(null),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black54,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: Colors.white, size: 20),
      onPressed: onTap,
    ),
  );
}

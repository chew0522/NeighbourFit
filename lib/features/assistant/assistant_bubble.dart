import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../state/core_providers.dart';
import 'assistant_dialog.dart';

/// True while the floating window is open. The bubble hides itself then.
final ValueNotifier<bool> assistantOpen = ValueNotifier(false);

/// Where the bubble currently sits. The window grows out of, and shrinks back
/// into, this point.
final ValueNotifier<Offset?> assistantBubbleCenter = ValueNotifier(null);

/// Floating bubble above every route (like the iPhone assistive touch ball).
/// Draggable, snaps to the left or right edge. Tap: the bubble disappears and
/// the chat window pops out of it. Tap outside the window: it shrinks back.
class AssistantBubble extends StatefulWidget {
  const AssistantBubble({super.key});

  @override
  State<AssistantBubble> createState() => _AssistantBubbleState();
}

class _AssistantBubbleState extends State<AssistantBubble> {
  static const _size = 56.0;
  Offset? _pos;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Hide while the keyboard is open so it never covers text fields.
    if (mq.viewInsets.bottom > 0) return const SizedBox.shrink();
    final w = mq.size.width;
    final h = mq.size.height;
    _pos ??= Offset(w - _size - 10, h - mq.padding.bottom - 250);
    final minY = mq.padding.top + 8;
    final maxY = h - mq.padding.bottom - _size - 130;
    final x = _pos!.dx;
    final y = _pos!.dy.clamp(minY, maxY);
    assistantBubbleCenter.value = Offset(x + _size / 2, y + _size / 2);

    return AnimatedPositioned(
      // No easing while the finger is down, a soft snap when it lets go.
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      left: x,
      top: y,
      child: ValueListenableBuilder<bool>(
        valueListenable: assistantOpen,
        builder: (context, open, child) => IgnorePointer(
          ignoring: open,
          child: AnimatedScale(
            scale: open ? 0 : 1,
            // Pops back in with a little overshoot once the window closes.
            duration: Duration(milliseconds: open ? 160 : 320),
            curve: open ? Curves.easeIn : Curves.easeOutBack,
            child: child,
          ),
        ),
        child: GestureDetector(
          onPanStart: (_) => setState(() => _dragging = true),
          onPanUpdate: (d) => setState(() {
            _pos = Offset(
              (x + d.delta.dx).clamp(0, w - _size),
              (y + d.delta.dy).clamp(minY, maxY),
            );
          }),
          onPanEnd: (_) => setState(() {
            _dragging = false;
            final snapLeft = _pos!.dx + _size / 2 < w / 2;
            _pos = Offset(snapLeft ? 10 : w - _size - 10, _pos!.dy);
          }),
          onTap: () {
            final ctx = rootNavigatorKey.currentContext;
            if (ctx != null) showAssistantDialog(ctx);
          },
          child: Semantics(
            button: true,
            label: 'Ask the NeighbourFit assistant',
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _dragging ? 1 : 0.85,
              child: Material(
                color: kAccent,
                elevation: 6,
                shape: const CircleBorder(),
                child: const SizedBox(
                  width: _size,
                  height: _size,
                  child: Icon(Icons.auto_awesome, color: kText, size: 28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

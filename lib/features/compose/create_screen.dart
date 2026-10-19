import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import 'compose_forms.dart';
import 'meetup_form.dart';

/// What can be created. The order is the order of the strip at the bottom.
enum CreateMode {
  workout('Workout', 'Share a workout'),
  meals('Meals', 'Share a healthy meal'),
  meetup('Meetup', 'Start a meetup'),
  equipment('Equipment', 'Lend equipment');

  const CreateMode(this.label, this.title);
  final String label;
  final String title;
}

/// Opens the create page (the ＋ button). Slides up as a full page.
Future<void> openCreate(BuildContext context, {CreateMode initial = CreateMode.workout}) {
  return Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => CreateScreen(initial: initial),
  ));
}

/// Full page with the four create forms. A strip of words at the bottom, like
/// the Post / Story switch on Instagram, picks the form: the chosen word sits
/// in the middle, the others fade out towards the edges.
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key, this.initial = CreateMode.workout});

  final CreateMode initial;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  late final PageController _content;
  late final PageController _strip;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initial.index;
    _content = PageController(initialPage: _index);
    _strip = PageController(initialPage: _index, viewportFraction: 0.32);
  }

  @override
  void dispose() {
    _content.dispose();
    _strip.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    FocusScope.of(context).unfocus();
    setState(() => _index = i);
    _content.animateToPage(i,
        duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom > 0;
    final mode = CreateMode.values[_index];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(mode.title, key: ValueKey(mode), style: const TextStyle(fontSize: 20)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _content,
                // Only the strip changes the form, so a swipe never loses
                // what you typed.
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _KeepAlive(child: WorkoutForm()),
                  _KeepAlive(child: MealForm()),
                  _KeepAlive(child: MeetupForm()),
                  _KeepAlive(child: EquipmentForm()),
                ],
              ),
            ),
            if (!keyboard)
              SizedBox(
                height: 44,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                    stops: [0.0, 0.2, 0.8, 1.0],
                  ).createShader(rect),
                  child: PageView.builder(
                    controller: _strip,
                    itemCount: CreateMode.values.length,
                    onPageChanged: _select,
                    itemBuilder: (_, i) => _StripLabel(
                      mode: CreateMode.values[i],
                      selected: i == _index,
                      onTap: () => _strip.animateToPage(i,
                          duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StripLabel extends StatelessWidget {
  const _StripLabel({required this.mode, required this.selected, required this.onTap});

  final CreateMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: selected ? 18 : 16,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? kText : kMuted,
            ),
            child: Text(mode.label),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 6 : 0,
            height: selected ? 6 : 0,
            decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

/// Keeps a form's text and choices while it is off screen.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

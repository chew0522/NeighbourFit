import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/post.dart';
import '../../core/utils/ids.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/date_time_field.dart';
import '../../widgets/tags.dart';
import '../../widgets/ui_helpers.dart';

/// Shared bits for the four create forms.
mixin ComposeHelpers<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Future<void> publish(Post post, {String message = 'Posted'}) async {
    await ref.read(postsProvider.notifier).add(post);
    ref.read(feedFilterProvider.notifier).set(FeedFilter.forYou);
    if (mounted) Navigator.of(context).pop();
    showSnack(message);
  }
}

/// Dropdown of preset places, own community first.
class PlaceDropdown extends ConsumerWidget {
  const PlaceDropdown({super.key, required this.value, required this.onChanged, this.optional = false});

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool optional;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final data = ref.watch(referenceProvider);
    final locs = [...data.locations]..sort((a, b) {
        final am = a.communityId == me?.communityId ? 0 : 1;
        final bm = b.communityId == me?.communityId ? 0 : 1;
        return am != bm ? am - bm : a.name.compareTo(b.name);
      });
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      hint: Text(optional ? 'Add a place (optional)' : 'Choose a public place'),
      items: [
        for (final l in locs)
          DropdownMenuItem(
            value: l.id,
            child: Text(l.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class SportChips extends StatelessWidget {
  const SportChips({super.key, required this.value, required this.onChanged});

  final Sport? value;
  final ValueChanged<Sport> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in Sport.values)
            ChoiceChip(
              avatar: Icon(sportIcon(s), size: 18, color: kPrimary),
              label: Text(s.label),
              selected: value == s,
              onSelected: (_) => onChanged(s),
            ),
        ],
      );
}

class _FormShell extends StatelessWidget {
  const _FormShell({required this.title, required this.children, required this.onSubmit, this.submitLabel = 'Post'});

  final String title;
  final List<Widget> children;
  final VoidCallback? onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: children,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: onSubmit, child: Text(submitLabel)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- workout

class WorkoutForm extends ConsumerStatefulWidget {
  const WorkoutForm({super.key});

  @override
  ConsumerState<WorkoutForm> createState() => _WorkoutFormState();
}

class _WorkoutFormState extends ConsumerState<WorkoutForm> with ComposeHelpers {
  final _text = TextEditingController();
  Sport? _sport;
  String? _place;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    if (_sport == null) return showSnack('Pick a sport first.');
    if (_text.text.trim().isEmpty) return showSnack('Write a few words about it.');
    publish(Post(
      id: newId('p_'),
      type: PostType.sport,
      authorId: me.id,
      communityId: me.communityId,
      sport: _sport,
      locationId: _place,
      text: _text.text.trim(),
      createdAt: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) => _FormShell(
        title: 'Share a workout',
        onSubmit: _submit,
        children: [
          const FieldLabel('What did you do?'),
          SportChips(value: _sport, onChanged: (s) => setState(() => _sport = s)),
          const FieldLabel('Where?'),
          PlaceDropdown(value: _place, optional: true, onChanged: (v) => setState(() => _place = v)),
          const FieldLabel('Say something'),
          TextField(
            controller: _text,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'How did it go?'),
          ),
        ],
      );
}

// -------------------------------------------------------------------- meal

class MealForm extends ConsumerStatefulWidget {
  const MealForm({super.key});

  @override
  ConsumerState<MealForm> createState() => _MealFormState();
}

class _MealFormState extends ConsumerState<MealForm> with ComposeHelpers {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    if (_text.text.trim().isEmpty) return showSnack('Tell us about your meal.');
    publish(Post(
      id: newId('p_'),
      type: PostType.meal,
      authorId: me.id,
      communityId: me.communityId,
      text: _text.text.trim(),
      createdAt: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) => _FormShell(
        title: 'Share a healthy meal',
        onSubmit: _submit,
        children: [
          const FieldLabel('What did you eat?'),
          TextField(
            controller: _text,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'A meal you made or enjoyed that fits a healthy lifestyle'),
          ),
          const SizedBox(height: 8),
          const Text('This is for healthy meals only, not for giving away food.',
              style: TextStyle(color: kMuted, fontSize: 14)),
        ],
      );
}

// --------------------------------------------------------------- equipment

class EquipmentForm extends ConsumerStatefulWidget {
  const EquipmentForm({super.key});

  @override
  ConsumerState<EquipmentForm> createState() => _EquipmentFormState();
}

class _EquipmentFormState extends ConsumerState<EquipmentForm> with ComposeHelpers {
  final _item = TextEditingController();
  final _text = TextEditingController();

  @override
  void dispose() {
    _item.dispose();
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    if (_item.text.trim().isEmpty) return showSnack('What are you lending?');
    publish(
      Post(
        id: newId('p_'),
        type: PostType.equipment,
        authorId: me.id,
        communityId: me.communityId,
        equipmentItem: _item.text.trim(),
        text: _text.text.trim(),
        createdAt: DateTime.now(),
      ),
      message: 'Listed. Neighbours can now ask to borrow it.',
    );
  }

  @override
  Widget build(BuildContext context) => _FormShell(
        title: 'Lend equipment',
        onSubmit: _submit,
        submitLabel: 'List it',
        children: [
          const FieldLabel('What can neighbours borrow?'),
          TextField(
            controller: _item,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'e.g. Yoga mat, badminton racket'),
          ),
          const FieldLabel('Anything to know? (optional)'),
          TextField(
            controller: _text,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Condition, how long, pick-up details'),
          ),
        ],
      );
}

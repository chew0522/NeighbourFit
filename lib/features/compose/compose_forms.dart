import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/post.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/time_utils.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/date_time_field.dart';
import '../../widgets/photo_field.dart';
import '../../widgets/tags.dart';
import '../../widgets/ui_helpers.dart';

/// Shared bits for the four create forms.
mixin ComposeHelpers<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Future<void> publish(
    Post post, {
    String message = 'Posted',
    FeedFilter goTo = FeedFilter.forYou,
  }) async {
    await ref.read(postsProvider.notifier).add(post);
    ref.read(feedFilterProvider.notifier).set(goTo);
    if (mounted) Navigator.of(context).pop();
    showSnack(message);
  }
}

/// Dropdown of preset places, own community first.
class PlaceDropdown extends ConsumerWidget {
  const PlaceDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.optional = false,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool optional;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final data = ref.watch(referenceProvider);
    final locs = [...data.locations]
      ..sort((a, b) {
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

/// Body of a create form: scrolling fields and a Post button. The page that
/// hosts it (CreateScreen) provides the app bar and the mode strip.
class _FormShell extends StatelessWidget {
  const _FormShell({
    required this.children,
    required this.onSubmit,
    this.submitLabel = 'Post',
  });

  final List<Widget> children;
  final VoidCallback? onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: children,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onSubmit, child: Text(submitLabel)),
          ),
        ),
      ],
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
  String? _photo;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    if (_sport == null) return showSnack('Pick a sport first.');
    if (_text.text.trim().isEmpty) {
      return showSnack('Write a few words about it.');
    }
    publish(
      Post(
        id: newId('p_'),
        type: PostType.sport,
        authorId: me.id,
        communityId: me.communityId,
        sport: _sport,
        locationId: _place,
        text: _text.text.trim(),
        photoPath: _photo,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _FormShell(
    onSubmit: _submit,
    children: [
      PhotoField(path: _photo, onChanged: (v) => setState(() => _photo = v)),
      const FieldLabel('What did you do?'),
      SportChips(value: _sport, onChanged: (s) => setState(() => _sport = s)),
      const FieldLabel('Where?'),
      PlaceDropdown(
        value: _place,
        optional: true,
        onChanged: (v) => setState(() => _place = v),
      ),
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
  String? _photo;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    if (_text.text.trim().isEmpty) return showSnack('Tell us about your meal.');
    publish(
      Post(
        id: newId('p_'),
        type: PostType.meal,
        authorId: me.id,
        communityId: me.communityId,
        text: _text.text.trim(),
        photoPath: _photo,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _FormShell(
    onSubmit: _submit,
    children: [
      PhotoField(path: _photo, onChanged: (v) => setState(() => _photo = v)),
      const FieldLabel('What did you eat?'),
      TextField(
        controller: _text,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'A meal you made or enjoyed that fits a healthy lifestyle',
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'This is for healthy meals only, not for giving away food.',
        style: TextStyle(color: kMuted, fontSize: 14),
      ),
    ],
  );
}

// --------------------------------------------------------------- equipment

class EquipmentForm extends ConsumerStatefulWidget {
  const EquipmentForm({super.key, this.requestItem});

  /// When set, the form opens on "I need to borrow" with this item filled in.
  final String? requestItem;

  @override
  ConsumerState<EquipmentForm> createState() => _EquipmentFormState();
}

class _EquipmentFormState extends ConsumerState<EquipmentForm>
    with ComposeHelpers {
  final _item = TextEditingController();
  final _text = TextEditingController();
  String? _photo;
  late bool _request;
  DateTime? _neededBy;

  @override
  void initState() {
    super.initState();
    _request = widget.requestItem != null;
    _item.text = widget.requestItem ?? '';
  }

  @override
  void didUpdateWidget(EquipmentForm old) {
    super.didUpdateWidget(old);
    if (widget.requestItem != null && widget.requestItem != old.requestItem) {
      _request = true;
      _item.text = widget.requestItem!;
    }
  }

  @override
  void dispose() {
    _item.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _neededBy ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (d != null) {
      setState(() => _neededBy = DateTime(d.year, d.month, d.day, 18));
    }
  }

  void _submit() {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    if (_item.text.trim().isEmpty) {
      return showSnack(
        _request ? 'What do you need?' : 'What are you lending?',
      );
    }
    if (_request && _neededBy == null) {
      return showSnack('Pick the day you need it by.');
    }
    if (_request) {
      ref.read(equipmentSideProvider.notifier).set(EquipmentSide.requests);
    }
    publish(
      Post(
        id: newId('p_'),
        type: PostType.equipment,
        authorId: me.id,
        communityId: me.communityId,
        equipmentItem: _item.text.trim(),
        isRequest: _request,
        startsAt: _request ? _neededBy : null,
        text: _text.text.trim(),
        photoPath: _photo,
        createdAt: DateTime.now(),
      ),
      message: _request
          ? 'Request posted. Neighbours who can lend it will get in touch.'
          : 'Listed. Neighbours can now ask to borrow it.',
      goTo: _request ? FeedFilter.equipment : FeedFilter.forYou,
    );
  }

  @override
  Widget build(BuildContext context) => _FormShell(
    onSubmit: _submit,
    submitLabel: _request ? 'Post request' : 'List it',
    children: [
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: false, label: Text('I can lend')),
            ButtonSegment(value: true, label: Text('I need to borrow')),
          ],
          selected: {_request},
          onSelectionChanged: (v) => setState(() => _request = v.first),
        ),
      ),
      const SizedBox(height: 14),
      PhotoField(path: _photo, onChanged: (v) => setState(() => _photo = v)),
      FieldLabel(
        _request ? 'What do you need?' : 'What can neighbours borrow?',
      ),
      TextField(
        controller: _item,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: _request
              ? 'e.g. Badminton racket, foam roller'
              : 'e.g. Yoga mat, badminton racket',
        ),
      ),
      if (_request) ...[
        const FieldLabel('Needed by'),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(_neededBy == null ? 'Pick a date' : fmtDate(_neededBy!)),
        ),
      ],
      const FieldLabel('Anything to know? (optional)'),
      TextField(
        controller: _text,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: _request
              ? 'How long you need it, when you can pick it up'
              : 'Condition, how long, pick-up details',
        ),
      ),
    ],
  );
}

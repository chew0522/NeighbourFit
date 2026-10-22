import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/post.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/time_utils.dart';
import '../../state/app_state.dart';
import '../../widgets/date_time_field.dart';
import '../../widgets/photo_field.dart';
import '../../widgets/ui_helpers.dart';
import 'compose_forms.dart';

/// One form for casual and planned meetups. Only sport, date, time and place
/// are required; the rest sits under "More options".
class MeetupForm extends ConsumerStatefulWidget {
  const MeetupForm({super.key});

  @override
  ConsumerState<MeetupForm> createState() => _MeetupFormState();
}

class _MeetupFormState extends ConsumerState<MeetupForm> with ComposeHelpers {
  final _title = TextEditingController();
  final _max = TextEditingController();
  final _note = TextEditingController();
  Sport? _sport;
  DateTime? _when;
  String? _place;
  Level? _level;
  String? _photo;

  @override
  void dispose() {
    _title.dispose();
    _max.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    if (_sport == null) return showSnack('Pick a sport first.');
    if (_when == null) {
      return showSnack('Pick a date and a time that has not passed.');
    }
    if (!_when!.isAfter(DateTime.now())) {
      return showSnack('The time must be in the future.');
    }
    if (_place == null) return showSnack('Choose a public place.');
    int? cap;
    if (_max.text.trim().isNotEmpty) {
      cap = int.tryParse(_max.text.trim());
      if (cap == null || cap < 2 || cap > 200) {
        return showSnack('Max people should be a number from 2 to 200.');
      }
    }
    final title = _title.text.trim().isEmpty
        ? '${partOfDayLabel(_when!)} ${_sport!.noun}'
        : _title.text.trim();
    final post = Post(
      id: newId('p_'),
      type: PostType.meetup,
      authorId: me.id,
      communityId: me.communityId,
      title: title,
      text: _note.text.trim(),
      locationId: _place,
      startsAt: _when,
      sport: _sport,
      level: _level,
      photoPath: _photo,
      capacity: cap,
      memberIds: [me.id],
      createdAt: DateTime.now(),
    );
    await ref.read(chatProvider.notifier).ensureGroup(post);
    await publish(post, message: 'Meetup posted. Neighbours can join now.');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              const Text(
                'Want company? Tell your neighbours when and where.',
                style: TextStyle(fontSize: 17, color: kMuted),
              ),
              PhotoField(
                path: _photo,
                onChanged: (v) => setState(() => _photo = v),
              ),
              const FieldLabel('Sport'),
              SportChips(
                value: _sport,
                onChanged: (s) => setState(() => _sport = s),
              ),
              const FieldLabel('When'),
              DateTimeField(onChanged: (d) => _when = d),
              const FieldLabel('Where'),
              PlaceDropdown(
                value: _place,
                onChanged: (v) => setState(() => _place = v),
              ),
              const SizedBox(height: 12),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text(
                    'More options',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FieldLabel('Title'),
                          TextField(
                            controller: _title,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Leave empty for an automatic title',
                            ),
                          ),
                          const FieldLabel('Max people'),
                          TextField(
                            controller: _max,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Leave empty for no limit',
                            ),
                          ),
                          const FieldLabel('Level'),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final l in Level.values)
                                ChoiceChip(
                                  label: Text(l.label),
                                  selected: _level == l,
                                  onSelected: (v) =>
                                      setState(() => _level = v ? l : null),
                                ),
                            ],
                          ),
                          const FieldLabel('A note'),
                          TextField(
                            controller: _note,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Anything people should know',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Post meetup'),
            ),
          ),
        ),
      ],
    );
  }
}

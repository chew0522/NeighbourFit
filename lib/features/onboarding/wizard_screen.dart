import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/models/constants.dart';
import '../../core/models/enums.dart';
import '../../core/models/user_profile.dart';
import '../../core/utils/ids.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/date_time_field.dart';
import '../../widgets/ui_helpers.dart';

/// Email and password chosen on the sign-up page, saved when the profile is
/// finished.
class SignupCredentials {
  const SignupCredentials({required this.email, required this.password});

  final String email;
  final String password;
}

/// Short multi-step profile wizard. Used to create a profile and, with
/// [editing], to change it later from Me > Profile.
class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key, this.editing, this.credentials});

  final UserProfile? editing;
  final SignupCredentials? credentials;

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  static const _steps = 5; // welcome (done), about, likes, when, optional/done
  int _step = 0; // 0 about, 1 likes, 2 when, 3 optional, 4 done

  final _nickname = TextEditingController();
  final _emergency = TextEditingController();
  int? _avatar;
  AgeGroup? _age;
  String? _community;
  final Set<Sport> _sports = {};
  Level? _level;
  final Set<TimeSlot> _slots = {};
  final Set<String> _langs = {};
  Gender? _gender;
  String? _agePref;
  String _genderPref = 'any'; // not asked in this version
  String? _error;

  bool get _editing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _nickname.text = e.nickname;
      _emergency.text = e.emergencyContactName ?? '';
      _avatar = e.avatarColor;
      _age = e.ageGroup;
      _community = e.communityId;
      _sports.addAll(e.sports);
      _level = e.level;
      _slots.addAll(e.timeSlots);
      _langs
        ..clear()
        ..addAll(e.languages);
      _gender = e.gender;
      _agePref = e.agePref;
      _genderPref = e.genderPref;
    }
  }

  @override
  void dispose() {
    _nickname.dispose();
    _emergency.dispose();
    super.dispose();
  }

  String? _validate() {
    switch (_step) {
      case 0:
        if (_nickname.text.trim().isEmpty) return 'Please enter a nickname.';
        if (_avatar == null) return 'Please pick an avatar colour.';
        if (_age == null) return 'Please choose your age group.';
        if (_community == null) return 'Please choose your community.';
        return null;
      case 1:
        if (_sports.isEmpty) return 'Pick at least one sport.';
        if (_level == null) return 'Please choose your level.';
        return null;
      case 2:
        if (_slots.isEmpty) return 'Pick at least one time.';
        if (_langs.isEmpty) return 'Pick at least one language.';
        return null;
      case 3:
        if (_gender == null) return 'Please choose an option for gender.';
        if (_agePref == null) return 'Please choose your age preference.';
        return null;
    }
    return null;
  }

  void _next() {
    final e = _validate();
    if (e != null) {
      setState(() => _error = e);
      return;
    }
    setState(() {
      _error = null;
      _step++;
    });
  }

  Future<void> _finish() async {
    final users = ref.read(usersProvider.notifier);
    final emergency = _emergency.text.trim();
    if (_editing) {
      await users.update(
        widget.editing!.id,
        (u) => u.copyWith(
          nickname: _nickname.text.trim(),
          avatarColor: _avatar!,
          ageGroup: _age,
          gender: _gender!,
          languages: _langs.toList(),
          communityId: _community,
          sports: _sports.toList(),
          level: _level!,
          timeSlots: _slots.toList(),
          agePref: _agePref!,
          genderPref: _genderPref,
          emergencyContactName: emergency.isEmpty ? null : emergency,
          clearEmergencyContact: emergency.isEmpty,
        ),
      );
      if (mounted) Navigator.of(context).pop();
      showSnack('Profile updated.');
      return;
    }
    final u = UserProfile(
      id: newId('u_'),
      nickname: _nickname.text.trim(),
      avatarColor: _avatar!,
      ageGroup: _age!,
      gender: _gender!,
      languages: _langs.toList(),
      communityId: _community!,
      sports: _sports.toList(),
      level: _level!,
      timeSlots: _slots.toList(),
      agePref: _agePref!,
      genderPref: _genderPref,
      emergencyContactName: emergency.isEmpty ? null : emergency,
      createdAt: DateTime.now(),
    );
    await users.upsert(u);
    final cred = widget.credentials;
    if (cred != null) {
      await ref
          .read(authRepoProvider)
          .register(email: cred.email, password: cred.password, userId: u.id);
    }
    await ref.read(sessionProvider.notifier).signIn(u.id);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == 4;
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit profile' : 'Create your profile')),
      body: SafeArea(
        child: Column(
          children: [
            _Dots(total: _steps, active: _step + 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _page(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_error!,
                            style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 15)),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_step > 0 && !last)
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _error = null;
                        _step--;
                      }),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: last ? _finish : _next,
                    child: Text(last ? (_editing ? 'Save' : "Let's go") : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page() {
    switch (_step) {
      case 0:
        return _about();
      case 1:
        return _likes();
      case 2:
        return _when();
      case 3:
        return _optional();
      default:
        return _done();
    }
  }

  Widget _title(String t, [String? sub]) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            if (sub != null) Text(sub, style: const TextStyle(color: kMuted)),
          ],
        ),
      );

  Widget _about() {
    final communities = ref.read(referenceProvider).communities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('About you', 'Just the basics.'),
        const FieldLabel('Nickname'),
        TextField(controller: _nickname, textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'What should neighbours call you?')),
        const FieldLabel('Avatar colour'),
        Wrap(
          spacing: 10,
          children: [
            for (final c in avatarColors)
              GestureDetector(
                key: ValueKey('avatar_$c'),
                onTap: () => setState(() => _avatar = c),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _avatar == c ? kText : Colors.transparent, width: 3),
                  ),
                ),
              ),
          ],
        ),
        const FieldLabel('Age group'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in AgeGroup.values)
              ChoiceChip(
                label: Text(g.label),
                selected: _age == g,
                onSelected: (_) => setState(() => _age = g),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('NeighbourFit is for residents aged 18 and over.',
            style: TextStyle(color: kMuted, fontSize: 14)),
        const FieldLabel('Community'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in communities)
              ChoiceChip(
                label: Text(c.name),
                selected: _community == c.id,
                onSelected: (_) => setState(() => _community = c.id),
              ),
          ],
        ),
      ],
    );
  }

  Widget _likes() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('What do you like?', 'Pick as many as you want.'),
          const FieldLabel('Sports'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in Sport.values.where((s) => s != Sport.other))
                FilterChip(
                  label: Text(s.label),
                  selected: _sports.contains(s),
                  onSelected: (v) => setState(() => v ? _sports.add(s) : _sports.remove(s)),
                ),
            ],
          ),
          const FieldLabel('Your level'),
          Wrap(
            spacing: 8,
            children: [
              for (final l in Level.values)
                ChoiceChip(
                  label: Text(l.label),
                  selected: _level == l,
                  onSelected: (_) => setState(() => _level = l),
                ),
            ],
          ),
        ],
      );

  Widget _when() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('When and how?', 'So we can find people on your schedule.'),
          const FieldLabel('Usual times'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in TimeSlot.values)
                FilterChip(
                  label: Text(t.label),
                  selected: _slots.contains(t),
                  onSelected: (v) => setState(() => v ? _slots.add(t) : _slots.remove(t)),
                ),
            ],
          ),
          const FieldLabel('Languages you speak'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in languageLabels.entries)
                FilterChip(
                  label: Text(e.value),
                  selected: _langs.contains(e.key),
                  onSelected: (v) => setState(() => v ? _langs.add(e.key) : _langs.remove(e.key)),
                ),
            ],
          ),
        ],
      );

  Widget _optional() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('A few more things', 'Choose one in each row. Only the emergency contact is optional.'),
          const FieldLabel('Gender'),
          Wrap(
            spacing: 8,
            children: [
              for (final g in Gender.values)
                ChoiceChip(
                  label: Text(g.label),
                  selected: _gender == g,
                  onSelected: (_) => setState(() => _gender = g),
                ),
            ],
          ),
          const FieldLabel('Neighbours you would like to meet'),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Similar age'),
                selected: _agePref == 'same',
                onSelected: (_) => setState(() => _agePref = 'same'),
              ),
              ChoiceChip(
                label: const Text('Any age'),
                selected: _agePref == 'any',
                onSelected: (_) => setState(() => _agePref = 'any'),
              ),
            ],
          ),
          const FieldLabel('Emergency contact (name only, optional)'),
          TextField(
            controller: _emergency,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Someone we can mention for safe buddy'),
          ),
        ],
      );

  Widget _done() => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.check_circle, size: 72, color: kGreen),
              const SizedBox(height: 16),
              Text(_editing ? 'All changes ready' : "You're all set!",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                _editing
                    ? 'Tap Save to update your profile.'
                    : 'Your neighbours are waiting. Find a meetup or start one.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: kMuted),
              ),
            ],
          ),
        ),
      );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.total, required this.active});

  final int total;
  final int active; // 1-based

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= total; i++)
              Container(
                width: i == active ? 22 : 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: i <= active ? kPrimary : kBorder,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
          ],
        ),
      );
}

T? enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

enum PostType { sport, meal, meetup, equipment, challenge }

enum Sport {
  running('Running', 'run'),
  walking('Walking', 'walk'),
  cycling('Cycling', 'ride'),
  badminton('Badminton', 'badminton'),
  yoga('Yoga', 'yoga'),
  swimming('Swimming', 'swim'),
  gym('Gym', 'workout'),
  other('Other', 'activity');

  const Sport(this.label, this.noun);
  final String label;
  final String noun;
}

enum Level {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  const Level(this.label);
  final String label;
}

enum AgeGroup {
  g18_29('18-29'),
  g30_39('30-39'),
  g40_49('40-49'),
  g50_59('50-59'),
  g60plus('60+');

  const AgeGroup(this.label);
  final String label;

  static AgeGroup? fromLabel(Object? v) {
    if (v is! String) return null;
    for (final g in AgeGroup.values) {
      if (g.label == v) return g;
    }
    return null;
  }
}

enum TimeSlot {
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening'),
  weekend('Weekend');

  const TimeSlot(this.label);
  final String label;
}

enum FieldVisibility {
  everyone('Everyone'),
  community('Community'),
  onlyMe('Only me');

  const FieldVisibility(this.label);
  final String label;
}

enum Gender {
  male('Male'),
  female('Female'),
  undisclosed('Prefer not to say');

  const Gender(this.label);
  final String label;
}

/// Profile fields that carry a per-field visibility setting.
const visibilityFields = ['ageGroup', 'gender', 'level', 'timeSlots'];

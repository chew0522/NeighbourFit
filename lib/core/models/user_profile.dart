import 'enums.dart';
import 'json_utils.dart';

class RedeemedVoucher {
  const RedeemedVoucher({
    required this.voucherId,
    required this.code,
    required this.at,
  });

  final String voucherId;
  final String code;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'voucherId': voucherId,
        'code': code,
        'at': at.toIso8601String(),
      };

  factory RedeemedVoucher.fromJson(Map<String, dynamic> j) => RedeemedVoucher(
        voucherId: j['voucherId'] as String? ?? '',
        code: j['code'] as String? ?? '',
        at: parseDt(j['at']),
      );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.nickname,
    this.avatarColor = 0xFF2E9E6B,
    this.ageGroup = AgeGroup.g18_29,
    this.gender = Gender.undisclosed,
    this.languages = const ['en'],
    required this.communityId,
    this.sports = const [],
    this.level = Level.beginner,
    this.timeSlots = const [],
    this.needsAccessibility = false,
    this.agePref = 'any',
    this.genderPref = 'any',
    this.emergencyContactName,
    this.visibility = const {
      'ageGroup': FieldVisibility.community,
      'gender': FieldVisibility.onlyMe,
      'level': FieldVisibility.community,
      'timeSlots': FieldVisibility.community,
    },
    this.blockedUserIds = const [],
    this.points = 0,
    this.redeemedVouchers = const [],
    this.dismissedSuggestionIds = const [],
    this.joinAwardIds = const [],
    this.isDemo = false,
    required this.createdAt,
  });

  final String id;
  final String nickname;
  final int avatarColor;
  final AgeGroup ageGroup;
  final Gender gender;
  final List<String> languages;
  final String communityId;
  final List<Sport> sports;
  final Level level;
  final List<TimeSlot> timeSlots;
  final bool needsAccessibility;

  /// 'any' or 'same'
  final String agePref;

  /// 'any' or 'women_only'
  final String genderPref;
  final String? emergencyContactName;
  final Map<String, FieldVisibility> visibility;
  final List<String> blockedUserIds;
  final int points;
  final List<RedeemedVoucher> redeemedVouchers;
  final List<String> dismissedSuggestionIds;

  /// Meetups for which the +20 points were already given.
  final List<String> joinAwardIds;
  final bool isDemo;
  final DateTime createdAt;

  FieldVisibility visibilityOf(String field) =>
      visibility[field] ?? FieldVisibility.community;

  bool isVisible(String field) => visibilityOf(field) != FieldVisibility.onlyMe;

  String get initials {
    final parts = nickname.replaceAll('.', '').trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].length <= 4) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return nickname.trim().isEmpty ? '?' : nickname.trim()[0].toUpperCase();
  }

  UserProfile copyWith({
    String? nickname,
    int? avatarColor,
    AgeGroup? ageGroup,
    Gender? gender,
    List<String>? languages,
    String? communityId,
    List<Sport>? sports,
    Level? level,
    List<TimeSlot>? timeSlots,
    bool? needsAccessibility,
    String? agePref,
    String? genderPref,
    String? emergencyContactName,
    bool clearEmergencyContact = false,
    Map<String, FieldVisibility>? visibility,
    List<String>? blockedUserIds,
    int? points,
    List<RedeemedVoucher>? redeemedVouchers,
    List<String>? dismissedSuggestionIds,
    List<String>? joinAwardIds,
  }) =>
      UserProfile(
        id: id,
        nickname: nickname ?? this.nickname,
        avatarColor: avatarColor ?? this.avatarColor,
        ageGroup: ageGroup ?? this.ageGroup,
        gender: gender ?? this.gender,
        languages: languages ?? this.languages,
        communityId: communityId ?? this.communityId,
        sports: sports ?? this.sports,
        level: level ?? this.level,
        timeSlots: timeSlots ?? this.timeSlots,
        needsAccessibility: needsAccessibility ?? this.needsAccessibility,
        agePref: agePref ?? this.agePref,
        genderPref: genderPref ?? this.genderPref,
        emergencyContactName: clearEmergencyContact
            ? null
            : (emergencyContactName ?? this.emergencyContactName),
        visibility: visibility ?? this.visibility,
        blockedUserIds: blockedUserIds ?? this.blockedUserIds,
        points: points ?? this.points,
        redeemedVouchers: redeemedVouchers ?? this.redeemedVouchers,
        dismissedSuggestionIds:
            dismissedSuggestionIds ?? this.dismissedSuggestionIds,
        joinAwardIds: joinAwardIds ?? this.joinAwardIds,
        isDemo: isDemo,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'avatarColor': avatarColor,
        'ageGroup': ageGroup.label,
        'gender': gender.name,
        'languages': languages,
        'communityId': communityId,
        'sports': sports.map((e) => e.name).toList(),
        'level': level.name,
        'timeSlots': timeSlots.map((e) => e.name).toList(),
        'needsAccessibility': needsAccessibility,
        'matchPrefs': {'agePref': agePref, 'genderPref': genderPref},
        'emergencyContactName': emergencyContactName,
        'visibility': visibility.map((k, v) => MapEntry(k, v.name)),
        'blockedUserIds': blockedUserIds,
        'points': points,
        'redeemedVouchers': redeemedVouchers.map((e) => e.toJson()).toList(),
        'dismissedSuggestionIds': dismissedSuggestionIds,
        'joinAwardIds': joinAwardIds,
        'isDemo': isDemo,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    final prefs = asMap(j['matchPrefs']);
    final vis = asMap(j['visibility']);
    return UserProfile(
      id: j['id'] as String,
      nickname: j['nickname'] as String? ?? 'Neighbour',
      avatarColor: parseColor(j['avatarColor']),
      ageGroup: AgeGroup.fromLabel(j['ageGroup']) ?? AgeGroup.g18_29,
      gender: enumByName(Gender.values, j['gender']) ?? Gender.undisclosed,
      languages: strList(j['languages']),
      communityId: j['communityId'] as String? ?? 'c_lakeside',
      sports: strList(j['sports'])
          .map((e) => enumByName(Sport.values, e))
          .whereType<Sport>()
          .toList(),
      level: enumByName(Level.values, j['level']) ?? Level.beginner,
      timeSlots: strList(j['timeSlots'])
          .map((e) => enumByName(TimeSlot.values, e))
          .whereType<TimeSlot>()
          .toList(),
      needsAccessibility: j['needsAccessibility'] as bool? ?? false,
      agePref: prefs['agePref'] as String? ?? 'any',
      genderPref: prefs['genderPref'] as String? ?? 'any',
      emergencyContactName: j['emergencyContactName'] as String?,
      visibility: {
        for (final f in visibilityFields)
          f: enumByName(FieldVisibility.values, vis[f]) ??
              (f == 'gender' ? FieldVisibility.onlyMe : FieldVisibility.community),
      },
      blockedUserIds: strList(j['blockedUserIds']),
      points: (j['points'] as num?)?.toInt() ?? 0,
      redeemedVouchers: mapList(j['redeemedVouchers'])
          .map(RedeemedVoucher.fromJson)
          .toList(),
      dismissedSuggestionIds: strList(j['dismissedSuggestionIds']),
      joinAwardIds: strList(j['joinAwardIds']),
      isDemo: j['isDemo'] as bool? ?? false,
      createdAt: parseDt(j['createdAt']),
    );
  }
}

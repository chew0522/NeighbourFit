import 'enums.dart';
import 'json_utils.dart';

class Comment {
  const Comment({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: j['id'] as String? ?? '',
        authorId: j['authorId'] as String? ?? '',
        text: j['text'] as String? ?? '',
        createdAt: parseDt(j['createdAt']),
      );
}

class NextTime {
  const NextTime({required this.userId, this.note, required this.at});

  final String userId;
  final String? note;
  final DateTime at;

  Map<String, dynamic> toJson() =>
      {'userId': userId, 'note': note, 'at': at.toIso8601String()};

  factory NextTime.fromJson(Map<String, dynamic> j) => NextTime(
        userId: j['userId'] as String? ?? '',
        note: j['note'] as String?,
        at: parseDt(j['at']),
      );
}

/// One post structure for every type. Unused fields stay null / empty.
class Post {
  const Post({
    required this.id,
    required this.type,
    required this.authorId,
    required this.communityId,
    this.text = '',
    this.title,
    this.locationId,
    this.startsAt,
    this.sport,
    this.level,
    this.accessibilityFriendly = false,
    this.safeBuddy = false,
    this.capacity,
    this.memberIds = const [],
    this.equipmentItem,
    this.cheeredBy = const [],
    this.comments = const [],
    this.nextTimeBy = const [],
    this.homeSafeIds = const [],
    required this.createdAt,
  });

  final String id;
  final PostType type;
  final String authorId;
  final String communityId;
  final String text;
  final String? title;
  final String? locationId;
  final DateTime? startsAt;
  final Sport? sport;
  final Level? level;
  final bool accessibilityFriendly;
  final bool safeBuddy;

  /// Meetup only. null means no limit.
  final int? capacity;
  final List<String> memberIds;
  final String? equipmentItem;
  final List<String> cheeredBy;
  final List<Comment> comments;

  /// Sport shares only. Visible to the poster only.
  final List<NextTime> nextTimeBy;
  final List<String> homeSafeIds;
  final DateTime createdAt;

  bool get isMeetup => type == PostType.meetup;
  bool get isFull => capacity != null && memberIds.length >= capacity!;
  bool isUpcoming(DateTime now) => startsAt != null && startsAt!.isAfter(now);

  Post copyWith({
    List<String>? memberIds,
    List<String>? cheeredBy,
    List<Comment>? comments,
    List<NextTime>? nextTimeBy,
    List<String>? homeSafeIds,
  }) =>
      Post(
        id: id,
        type: type,
        authorId: authorId,
        communityId: communityId,
        text: text,
        title: title,
        locationId: locationId,
        startsAt: startsAt,
        sport: sport,
        level: level,
        accessibilityFriendly: accessibilityFriendly,
        safeBuddy: safeBuddy,
        capacity: capacity,
        memberIds: memberIds ?? this.memberIds,
        equipmentItem: equipmentItem,
        cheeredBy: cheeredBy ?? this.cheeredBy,
        comments: comments ?? this.comments,
        nextTimeBy: nextTimeBy ?? this.nextTimeBy,
        homeSafeIds: homeSafeIds ?? this.homeSafeIds,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'authorId': authorId,
        'communityId': communityId,
        'text': text,
        'title': title,
        'locationId': locationId,
        'startsAt': startsAt?.toIso8601String(),
        'sport': sport?.name,
        'level': level?.name,
        'accessibilityFriendly': accessibilityFriendly,
        'safeBuddy': safeBuddy,
        'capacity': capacity,
        'memberIds': memberIds,
        'equipmentItem': equipmentItem,
        'cheeredBy': cheeredBy,
        'comments': comments.map((e) => e.toJson()).toList(),
        'nextTimeBy': nextTimeBy.map((e) => e.toJson()).toList(),
        'homeSafeIds': homeSafeIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as String,
        type: enumByName(PostType.values, j['type']) ?? PostType.sport,
        authorId: j['authorId'] as String? ?? '',
        communityId: j['communityId'] as String? ?? 'c_lakeside',
        text: j['text'] as String? ?? '',
        title: j['title'] as String?,
        locationId: j['locationId'] as String?,
        startsAt: parseDtOrNull(j['startsAt']),
        sport: enumByName(Sport.values, j['sport']),
        level: enumByName(Level.values, j['level']),
        accessibilityFriendly: j['accessibilityFriendly'] as bool? ?? false,
        safeBuddy: j['safeBuddy'] as bool? ?? false,
        capacity: (j['capacity'] as num?)?.toInt(),
        memberIds: strList(j['memberIds']),
        equipmentItem: j['equipmentItem'] as String?,
        cheeredBy: strList(j['cheeredBy']),
        comments: mapList(j['comments']).map(Comment.fromJson).toList(),
        nextTimeBy: mapList(j['nextTimeBy']).map(NextTime.fromJson).toList(),
        homeSafeIds: strList(j['homeSafeIds']),
        createdAt: parseDt(j['createdAt']),
      );
}

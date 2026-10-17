import 'json_utils.dart';

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isSystem = false,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isSystem;

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'isSystem': isSystem,
      };

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String? ?? '',
        senderId: j['senderId'] as String? ?? '',
        text: j['text'] as String? ?? '',
        createdAt: parseDt(j['createdAt']),
        isSystem: j['isSystem'] as bool? ?? false,
      );
}

/// 'dm' or 'group'. Group chats belong to a Meetup through [sourcePostId].
class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.memberIds,
    this.sourcePostId,
    this.title,
    this.status = 'active',
    this.messages = const [],
  });

  final String id;
  final String type;
  final List<String> memberIds;
  final String? sourcePostId;
  final String? title;

  /// 'active' or 'blocked'. Group chats become read-only after the meetup;
  /// that is computed from the meetup time, not stored.
  final String status;
  final List<Message> messages;

  bool get isGroup => type == 'group';
  DateTime? get lastAt => messages.isEmpty ? null : messages.last.createdAt;

  Conversation copyWith({
    List<String>? memberIds,
    String? status,
    List<Message>? messages,
  }) =>
      Conversation(
        id: id,
        type: type,
        memberIds: memberIds ?? this.memberIds,
        sourcePostId: sourcePostId,
        title: title,
        status: status ?? this.status,
        messages: messages ?? this.messages,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'memberIds': memberIds,
        'sourcePostId': sourcePostId,
        'title': title,
        'status': status,
        'messages': messages.map((e) => e.toJson()).toList(),
      };

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as String,
        type: j['type'] as String? ?? 'dm',
        memberIds: strList(j['memberIds']),
        sourcePostId: j['sourcePostId'] as String?,
        title: j['title'] as String?,
        status: j['status'] as String? ?? 'active',
        messages: mapList(j['messages']).map(Message.fromJson).toList(),
      );
}

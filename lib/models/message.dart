import 'package:uuid/uuid.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String text;
  final DateTime sentAt;
  final bool isRead;

  Message({
    String? id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.text,
    DateTime? sentAt,
    this.isRead = false,
  })  : id = id ?? const Uuid().v4(),
        sentAt = sentAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'text': text,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead ? 1 : 0,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      conversationId: map['conversationId'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      receiverId: map['receiverId'],
      receiverName: map['receiverName'],
      text: map['text'] ?? '',
      sentAt: DateTime.tryParse(map['sentAt'] ?? '') ?? DateTime.now(),
      isRead: map['isRead'] == 1,
    );
  }
}

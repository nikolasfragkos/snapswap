class Conversation {
  final String conversationId;
  final String partnerId;
  final String partnerName;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;

  const Conversation({
    required this.conversationId,
    required this.partnerId,
    required this.partnerName,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.unreadCount,
  });

  Conversation copyWith({
    String? lastMessage,
    DateTime? lastTimestamp,
    int? unreadCount,
  }) {
    return Conversation(
      conversationId: conversationId,
      partnerId: partnerId,
      partnerName: partnerName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

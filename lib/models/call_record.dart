import 'package:uuid/uuid.dart';

enum CallDirection { outgoing, incoming }

enum CallStatus { ringing, inProgress, ended, missed }

class CallRecord {
  final String id;
  final String partnerId;
  final String partnerName;
  final CallDirection direction;
  final CallStatus status;
  final DateTime startedAt;
  final int durationSeconds;

  CallRecord({
    String? id,
    required this.partnerId,
    required this.partnerName,
    this.direction = CallDirection.outgoing,
    this.status = CallStatus.ringing,
    DateTime? startedAt,
    this.durationSeconds = 0,
  })  : id = id ?? const Uuid().v4(),
        startedAt = startedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'direction': direction.index,
      'status': status.index,
      'startedAt': startedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
    };
  }

  factory CallRecord.fromMap(Map<String, dynamic> map) {
    return CallRecord(
      id: map['id'],
      partnerId: map['partnerId'],
      partnerName: map['partnerName'],
      direction: CallDirection.values[map['direction'] ?? 0],
      status: CallStatus.values[map['status'] ?? 0],
      startedAt: DateTime.tryParse(map['startedAt'] ?? '') ?? DateTime.now(),
      durationSeconds: map['durationSeconds'] ?? 0,
    );
  }
}

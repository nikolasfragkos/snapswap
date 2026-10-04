import 'package:uuid/uuid.dart';

enum SwapStatus {
  pending,
  confirmed,
  completed,
  cancelled,
}

class Swap {
  final String id;
  final String myItemId;
  final String myItemName;
  final String theirItemId;
  final String theirItemName;
  final String partnerId;
  final String partnerName;
  final SwapStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? rating;
  final String? review;

  Swap({
    String? id,
    required this.myItemId,
    required this.myItemName,
    required this.theirItemId,
    required this.theirItemName,
    required this.partnerId,
    required this.partnerName,
    this.status = SwapStatus.pending,
    DateTime? createdAt,
    this.completedAt,
    this.rating,
    this.review,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'myItemId': myItemId,
      'myItemName': myItemName,
      'theirItemId': theirItemId,
      'theirItemName': theirItemName,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rating': rating,
      'review': review,
    };
  }

  factory Swap.fromMap(Map<String, dynamic> map) {
    return Swap(
      id: map['id'],
      myItemId: map['myItemId'],
      myItemName: map['myItemName'],
      theirItemId: map['theirItemId'],
      theirItemName: map['theirItemName'],
      partnerId: map['partnerId'],
      partnerName: map['partnerName'],
      status: SwapStatus.values[map['status'] ?? 0],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      completedAt: map['completedAt'] != null 
          ? DateTime.tryParse(map['completedAt']) 
          : null,
      rating: map['rating'],
      review: map['review'],
    );
  }

  Swap copyWith({
    SwapStatus? status,
    DateTime? completedAt,
    int? rating,
    String? review,
  }) {
    return Swap(
      id: id,
      myItemId: myItemId,
      myItemName: myItemName,
      theirItemId: theirItemId,
      theirItemName: theirItemName,
      partnerId: partnerId,
      partnerName: partnerName,
      status: status ?? this.status,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }

  String getFormattedDate() {
    return '${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Ιαν', 'Φεβ', 'Μαρ', 'Απρ', 'Μάι', 'Ιούν',
      'Ιούλ', 'Αυγ', 'Σεπ', 'Οκτ', 'Νοε', 'Δεκ'
    ];
    return months[month - 1];
  }

  String getStatusText() {
    switch (status) {
      case SwapStatus.pending:
        return 'Εκκρεμής';
      case SwapStatus.confirmed:
        return 'Επιβεβαιωμένη';
      case SwapStatus.completed:
        return 'Ολοκληρώθηκε';
      case SwapStatus.cancelled:
        return 'Ακυρώθηκε';
    }
  }
}

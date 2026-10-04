import 'package:uuid/uuid.dart';

class SwapItem {
  final String id;
  final String itemName;
  final String description;
  final String category;
  final String wantsCategory;
  final String imageUrl;
  final String userId;
  final String userName;
  final int userScore;
  final double latitude;
  final double longitude;
  final double distance;
  final DateTime createdAt;
  final bool isActive;

  SwapItem({
    String? id,
    required this.itemName,
    this.description = '',
    required this.category,
    required this.wantsCategory,
    required this.imageUrl,
    required this.userId,
    required this.userName,
    this.userScore = 0,
    this.latitude = 0,
    this.longitude = 0,
    this.distance = 0,
    DateTime? createdAt,
    this.isActive = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'description': description,
      'category': category,
      'wantsCategory': wantsCategory,
      'imageUrl': imageUrl,
      'userId': userId,
      'userName': userName,
      'userScore': userScore,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory SwapItem.fromMap(Map<String, dynamic> map) {
    return SwapItem(
      id: map['id'],
      itemName: map['itemName'],
      description: map['description'] ?? '',
      category: map['category'],
      wantsCategory: map['wantsCategory'],
      imageUrl: map['imageUrl'],
      userId: map['userId'],
      userName: map['userName'],
      userScore: map['userScore'] ?? 0,
      latitude: map['latitude']?.toDouble() ?? 0,
      longitude: map['longitude']?.toDouble() ?? 0,
      distance: map['distance']?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      isActive: map['isActive'] == 1,
    );
  }

  SwapItem copyWith({
    String? itemName,
    String? description,
    String? category,
    String? wantsCategory,
    String? imageUrl,
    double? latitude,
    double? longitude,
    double? distance,
    bool? isActive,
  }) {
    return SwapItem(
      id: id,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      category: category ?? this.category,
      wantsCategory: wantsCategory ?? this.wantsCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId,
      userName: userName,
      userScore: userScore,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} λεπτά πριν';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ώρες πριν';
    } else {
      return '${difference.inDays} μέρες πριν';
    }
  }
}

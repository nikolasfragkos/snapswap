import 'package:uuid/uuid.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int swapScore;
  final String level;
  final int totalSwaps;
  final int successRate;
  final double rating;
  final String location;
  final DateTime memberSince;
  final List<Achievement> achievements;

  User({
    String? id,
    required this.name,
    this.email = '',
    this.avatarUrl = '',
    this.swapScore = 0,
    this.level = 'Νέος Χρήστης',
    this.totalSwaps = 0,
    this.successRate = 0,
    this.rating = 0,
    this.location = '',
    DateTime? memberSince,
    List<Achievement>? achievements,
  })  : id = id ?? const Uuid().v4(),
        memberSince = memberSince ?? DateTime.now(),
        achievements = achievements ?? [];

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'swapScore': swapScore,
      'level': level,
      'totalSwaps': totalSwaps,
      'successRate': successRate,
      'rating': rating,
      'location': location,
      'memberSince': memberSince.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      swapScore: map['swapScore'] ?? 0,
      level: map['level'] ?? 'Νέος Χρήστης',
      totalSwaps: map['totalSwaps'] ?? 0,
      successRate: map['successRate'] ?? 0,
      rating: map['rating']?.toDouble() ?? 0,
      location: map['location'] ?? '',
      memberSince: DateTime.tryParse(map['memberSince'] ?? '') ?? DateTime.now(),
    );
  }

  User copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    int? swapScore,
    String? level,
    int? totalSwaps,
    int? successRate,
    double? rating,
    String? location,
    List<Achievement>? achievements,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      swapScore: swapScore ?? this.swapScore,
      level: level ?? this.level,
      totalSwaps: totalSwaps ?? this.totalSwaps,
      successRate: successRate ?? this.successRate,
      rating: rating ?? this.rating,
      location: location ?? this.location,
      memberSince: memberSince,
      achievements: achievements ?? this.achievements,
    );
  }

  static String calculateLevel(int score) {
    if (score >= 500) return 'Swap Legend';
    if (score >= 300) return 'Swap Master';
    if (score >= 150) return 'Swap Expert';
    if (score >= 50) return 'Swap Pro';
    return 'Νέος Χρήστης';
  }
}

class Achievement {
  final String id;
  final String name;
  final String icon;
  final bool unlocked;
  final String description;

  Achievement({
    required this.id,
    required this.name,
    required this.icon,
    this.unlocked = false,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'unlocked': unlocked ? 1 : 0,
      'description': description,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      unlocked: map['unlocked'] == 1,
      description: map['description'] ?? '',
    );
  }

  static List<Achievement> defaultAchievements() {
    return [
      Achievement(id: '1', name: 'First Swap', icon: '🎯', unlocked: false, description: 'Ολοκλήρωσε την πρώτη σου ανταλλαγή'),
      Achievement(id: '2', name: '10 Swaps', icon: '⭐', unlocked: false, description: 'Ολοκλήρωσε 10 ανταλλαγές'),
      Achievement(id: '3', name: '25 Swaps', icon: '🔥', unlocked: false, description: 'Ολοκλήρωσε 25 ανταλλαγές'),
      Achievement(id: '4', name: '50 Swaps', icon: '💎', unlocked: false, description: 'Ολοκλήρωσε 50 ανταλλαγές'),
      Achievement(id: '5', name: 'Top Trader', icon: '👑', unlocked: false, description: 'Φτάσε το επίπεδο Swap Legend'),
    ];
  }
}

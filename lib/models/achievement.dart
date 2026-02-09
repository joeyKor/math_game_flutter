import 'dart:convert';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int threshold;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.threshold,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      threshold: threshold,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'threshold': threshold,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      icon: map['icon'],
      threshold: map['threshold'] ?? 0,
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'])
          : null,
    );
  }

  static String encode(List<Achievement> achievements) => json.encode(
    achievements.map<Map<String, dynamic>>((a) => a.toMap()).toList(),
  );

  static List<Achievement> decode(String jsonStr) =>
      (json.decode(jsonStr) as List<dynamic>)
          .map<Achievement>((item) => Achievement.fromMap(item))
          .toList();
}

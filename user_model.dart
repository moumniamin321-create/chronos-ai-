import '../core/constants.dart';

/// The single local user profile. Since Chronos AI has no accounts and no
/// cloud sync by design, there is always exactly one UserModel stored on
/// the device.
class UserModel {
  final String id;
  final String name;
  final int age;
  final List<String> goals;
  final String wakeTime; // "HH:mm"
  final String sleepTime; // "HH:mm"
  final int xp;
  final int level;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.goals,
    required this.wakeTime,
    required this.sleepTime,
    this.xp = 0,
    this.level = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get rankTitle => AppConstants.rankForLevel(level);

  /// XP required to go from [level] to [level + 1].
  int xpToNextLevel() {
    return (AppConstants.xpBasePerLevel *
            (level == 0 ? 1 : level) *
            AppConstants.xpGrowthFactor)
        .round();
  }

  UserModel copyWith({
    String? name,
    int? age,
    List<String>? goals,
    String? wakeTime,
    String? sleepTime,
    int? xp,
    int? level,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      goals: goals ?? this.goals,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'goals': goals.join('|'),
      'wakeTime': wakeTime,
      'sleepTime': sleepTime,
      'xp': xp,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      age: map['age'] as int,
      goals: (map['goals'] as String).isEmpty
          ? []
          : (map['goals'] as String).split('|'),
      wakeTime: map['wakeTime'] as String,
      sleepTime: map['sleepTime'] as String,
      xp: map['xp'] as int,
      level: map['level'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

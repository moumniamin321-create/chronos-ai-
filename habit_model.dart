class HabitModel {
  final String id;
  final String title;
  final String icon; // emoji or icon key, kept simple for offline use
  final List<DateTime> completedDates;
  final DateTime createdAt;

  HabitModel({
    required this.id,
    required this.title,
    this.icon = '⭐',
    List<DateTime>? completedDates,
    DateTime? createdAt,
  })  : completedDates = completedDates ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool get completedToday {
    final now = DateTime.now();
    return completedDates.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );
  }

  /// Current consecutive-day streak, counting backward from today.
  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    final sortedDays = completedDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    for (final day in sortedDays) {
      if (day == cursor) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (day == cursor.add(const Duration(days: 1))) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  HabitModel copyWith({String? title, String? icon, List<DateTime>? completedDates}) {
    return HabitModel(
      id: id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'completedDates': completedDates.map((d) => d.toIso8601String()).join(','),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    final rawDates = map['completedDates'] as String;
    return HabitModel(
      id: map['id'] as String,
      title: map['title'] as String,
      icon: map['icon'] as String,
      completedDates: rawDates.isEmpty
          ? []
          : rawDates.split(',').map((s) => DateTime.parse(s)).toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

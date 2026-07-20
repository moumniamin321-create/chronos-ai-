/// Global constants used across the Chronos AI app.
class AppConstants {
  AppConstants._();

  static const String appName = 'Chronos AI';
  static const String assistantName = 'Atlas';

  // SQLite database
  static const String dbName = 'chronos_ai.db';
  static const int dbVersion = 1;

  // Shared preferences keys
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefUserId = 'current_user_id';

  // XP / leveling curve: xpForLevel(n) = base * n^growth
  static const int xpBasePerLevel = 100;
  static const double xpGrowthFactor = 1.35;

  // Rank thresholds (level -> title in Arabic)
  static const Map<int, String> rankTitles = {
    1: 'مبتدئ',
    5: 'منضبط',
    10: 'منظم',
    20: 'محترف',
    30: 'خبير',
    40: 'أستاذ',
    50: 'سيد الوقت',
  };

  static String rankForLevel(int level) {
    String title = rankTitles[1]!;
    for (final entry in rankTitles.entries) {
      if (level >= entry.key) title = entry.value;
    }
    return title;
  }
}

enum TaskCategory { study, work, sport, rest, hobby, sleep, other }

enum TaskPriority { low, medium, high, critical }

extension TaskCategoryX on TaskCategory {
  String get labelAr {
    switch (this) {
      case TaskCategory.study:
        return 'دراسة';
      case TaskCategory.work:
        return 'عمل';
      case TaskCategory.sport:
        return 'رياضة';
      case TaskCategory.rest:
        return 'راحة';
      case TaskCategory.hobby:
        return 'هواية';
      case TaskCategory.sleep:
        return 'نوم';
      case TaskCategory.other:
        return 'أخرى';
    }
  }
}

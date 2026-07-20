import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'constants.dart';

/// Single top-level ChangeNotifier the whole app listens to for the
/// current user + gamification (XP/level/rank). Kept in core/ since it's
/// cross-cutting app state, not tied to one feature screen.
class AppState extends ChangeNotifier {
  UserModel? _user;
  UserModel? get user => _user;

  bool get isLoaded => _user != null;

  Future<void> loadUser() async {
    _user = await AuthService.instance.currentUser();
    notifyListeners();
  }

  Future<void> setUser(UserModel user) async {
    _user = user;
    notifyListeners();
  }

  /// Awards XP for completing a task/habit and handles level-ups. Returns
  /// true if the user leveled up, so the UI can show a celebration.
  Future<bool> awardXp(int amount) async {
    if (_user == null) return false;
    int newXp = _user!.xp + amount;
    int newLevel = _user!.level;
    bool leveledUp = false;

    while (newXp >= _xpNeededFor(newLevel)) {
      newXp -= _xpNeededFor(newLevel);
      newLevel++;
      leveledUp = true;
    }

    _user = _user!.copyWith(xp: newXp, level: newLevel);
    await DatabaseService.instance.saveUser(_user!);
    notifyListeners();
    return leveledUp;
  }

  /// XP required to complete [level], independent of the user's current
  /// stored level — safe to call repeatedly while simulating level-ups.
  int _xpNeededFor(int level) {
    return (AppConstants.xpBasePerLevel * (level == 0 ? 1 : level) * AppConstants.xpGrowthFactor)
        .round();
  }
}

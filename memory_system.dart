import '../models/task_model.dart';
import '../services/database_service.dart';
import '../core/constants.dart';

/// Atlas's long-term memory. This does not call any external AI — it is a
/// local statistical memory over the user's own task history, which is
/// exactly the kind of "learns your habits" behaviour the app needs,
/// fully offline and free to run.
class MemorySystem {
  final DatabaseService _db;
  MemorySystem({DatabaseService? db}) : _db = db ?? DatabaseService.instance;

  /// Tasks the user tends to postpone repeatedly (postponedCount >= 2),
  /// grouped by category so Atlas can name the pattern ("you keep
  /// postponing study tasks").
  Future<Map<TaskCategory, int>> chronicProcrastinationByCategory() async {
    final tasks = await _db.getAllTasks();
    final Map<TaskCategory, int> result = {};
    for (final t in tasks.where((t) => t.postponedCount >= 2)) {
      result[t.category] = (result[t.category] ?? 0) + 1;
    }
    return result;
  }

  /// The hour of day (0-23) where the user historically completes the
  /// highest share of tasks — this is the empirical "best focus time".
  Future<int?> bestFocusHour() async {
    final tasks = await _db.getAllTasks();
    if (tasks.isEmpty) return null;

    final Map<int, int> completedByHour = {};
    final Map<int, int> totalByHour = {};

    for (final t in tasks) {
      final hour = t.startTime.hour;
      totalByHour[hour] = (totalByHour[hour] ?? 0) + 1;
      if (t.isCompleted) {
        completedByHour[hour] = (completedByHour[hour] ?? 0) + 1;
      }
    }

    int? bestHour;
    double bestRate = -1;
    totalByHour.forEach((hour, total) {
      if (total < 2) return; // not enough data to trust this hour
      final rate = (completedByHour[hour] ?? 0) / total;
      if (rate > bestRate) {
        bestRate = rate;
        bestHour = hour;
      }
    });
    return bestHour;
  }

  Future<void> remember(String note) async {
    await _db.addMemoryNote(DateTime.now().microsecondsSinceEpoch.toString(), note);
  }

  Future<List<String>> recall({int limit = 20}) => _db.getMemoryNotes(limit: limit);

  /// Produces a human-readable Arabic insight like the example in the
  /// spec: "لاحظت أنك تنجز المهام الصعبة صباحًا أكثر...". Called
  /// periodically (e.g. once a week) by AtlasBrain.
  Future<String?> generateWeeklyInsight() async {
    final bestHour = await bestFocusHour();
    if (bestHour == null) return null;

    final period = bestHour < 12
        ? 'الصباح'
        : (bestHour < 17 ? 'بعد الظهر' : 'المساء');

    final note = 'لاحظت أنك تنجز مهامك بشكل أفضل في $period '
        '(حوالي الساعة $bestHour:00) — حاول جدولة أهم مهامك في هذا الوقت.';
    await remember(note);
    return note;
  }
}

import '../models/task_model.dart';

class DayPrediction {
  final int recommendedFocusHour;
  final double estimatedCompletionProbability; // 0..1
  final bool needsRestSoon;

  DayPrediction({
    required this.recommendedFocusHour,
    required this.estimatedCompletionProbability,
    required this.needsRestSoon,
  });
}

/// Simple, explainable predictive model built on the user's own recent
/// history — analogous to what the spec calls "الذكاء التنبؤي". It looks
/// at sleep hours, task load, and recent completion rate to forecast the
/// day ahead. No external ML service needed or used.
class PredictionEngine {
  DayPrediction predictForToday({
    required List<TaskModel> last7DaysTasks,
    required List<TaskModel> todaysTasks,
    int? knownBestFocusHour,
  }) {
    final recentCompleted = last7DaysTasks.where((t) => t.isCompleted).length;
    final recentTotal = last7DaysTasks.length;
    final recentRate = recentTotal == 0 ? 0.6 : recentCompleted / recentTotal;

    // Heavier day load slightly lowers completion probability estimate.
    final loadPenalty = (todaysTasks.length > 6) ? 0.1 : 0.0;

    final probability = (recentRate - loadPenalty).clamp(0.05, 0.98);

    // Consecutive study/work tasks without a rest block signal burnout risk.
    final sorted = [...todaysTasks]..sort((a, b) => a.startTime.compareTo(b.startTime));
    int consecutiveIntense = 0;
    bool needsRest = false;
    for (final t in sorted) {
      final isIntense = t.category.name == 'study' || t.category.name == 'work';
      if (isIntense) {
        consecutiveIntense++;
        if (consecutiveIntense >= 3) {
          needsRest = true;
          break;
        }
      } else {
        consecutiveIntense = 0;
      }
    }

    return DayPrediction(
      recommendedFocusHour: knownBestFocusHour ?? 9,
      estimatedCompletionProbability: probability,
      needsRestSoon: needsRest,
    );
  }
}

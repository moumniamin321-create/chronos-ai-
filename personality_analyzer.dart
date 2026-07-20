import '../models/task_model.dart';
import '../core/constants.dart';

enum WorkStyle { morningPerson, nightOwl, steady, burstWorker }

class PersonalityProfile {
  final WorkStyle workStyle;
  final TaskCategory strongestCategory;
  final TaskCategory weakestCategory;
  final double disciplineScore; // 0..1, share of tasks completed on time

  PersonalityProfile({
    required this.workStyle,
    required this.strongestCategory,
    required this.weakestCategory,
    required this.disciplineScore,
  });
}

/// Infers a lightweight "personality profile" purely from task-completion
/// statistics — no external psychological test, no network call, just
/// pattern analysis of the user's own logged behaviour.
class PersonalityAnalyzer {
  PersonalityProfile analyze(List<TaskModel> history) {
    if (history.isEmpty) {
      return PersonalityProfile(
        workStyle: WorkStyle.steady,
        strongestCategory: TaskCategory.other,
        weakestCategory: TaskCategory.other,
        disciplineScore: 0.5,
      );
    }

    final completed = history.where((t) => t.isCompleted).toList();

    final morningCompleted = completed.where((t) => t.startTime.hour < 12).length;
    final eveningCompleted = completed.where((t) => t.startTime.hour >= 18).length;

    WorkStyle style;
    if (completed.isEmpty) {
      style = WorkStyle.steady;
    } else if (morningCompleted / completed.length > 0.55) {
      style = WorkStyle.morningPerson;
    } else if (eveningCompleted / completed.length > 0.55) {
      style = WorkStyle.nightOwl;
    } else {
      style = WorkStyle.steady;
    }

    final byCategory = <TaskCategory, List<TaskModel>>{};
    for (final t in history) {
      byCategory.putIfAbsent(t.category, () => []).add(t);
    }

    TaskCategory strongest = TaskCategory.other;
    TaskCategory weakest = TaskCategory.other;
    double bestRate = -1;
    double worstRate = 2;

    byCategory.forEach((cat, tasks) {
      if (tasks.length < 2) return;
      final rate = tasks.where((t) => t.isCompleted).length / tasks.length;
      if (rate > bestRate) {
        bestRate = rate;
        strongest = cat;
      }
      if (rate < worstRate) {
        worstRate = rate;
        weakest = cat;
      }
    });

    final discipline = completed.length / history.length;

    return PersonalityProfile(
      workStyle: style,
      strongestCategory: strongest,
      weakestCategory: weakest,
      disciplineScore: discipline.clamp(0.0, 1.0),
    );
  }
}

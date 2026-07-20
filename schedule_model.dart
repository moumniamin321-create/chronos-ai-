import 'task_model.dart';

/// Represents one calendar day's plan, derived from the task list rather
/// than stored directly — this keeps a single source of truth in the
/// tasks table while still giving screens a convenient day-level view.
class ScheduleModel {
  final DateTime day;
  final List<TaskModel> tasks;

  ScheduleModel({required this.day, required this.tasks});

  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((t) => t.isCompleted).length;

  double get productivityRate =>
      totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  Duration get totalPlannedDuration =>
      tasks.fold(Duration.zero, (sum, t) => sum + t.duration);

  List<TaskModel> get sortedByTime =>
      [...tasks]..sort((a, b) => a.startTime.compareTo(b.startTime));
}

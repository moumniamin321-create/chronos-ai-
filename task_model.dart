import '../core/constants.dart';

class TaskModel {
  final String id;
  final String title;
  final String? notes;
  final DateTime startTime;
  final DateTime endTime;
  final TaskCategory category;
  final TaskPriority priority;
  final bool isCompleted;
  final bool isAiGenerated;
  final int postponedCount;

  TaskModel({
    required this.id,
    required this.title,
    this.notes,
    required this.startTime,
    required this.endTime,
    this.category = TaskCategory.other,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    this.isAiGenerated = false,
    this.postponedCount = 0,
  });

  Duration get duration => endTime.difference(startTime);

  TaskModel copyWith({
    String? title,
    String? notes,
    DateTime? startTime,
    DateTime? endTime,
    TaskCategory? category,
    TaskPriority? priority,
    bool? isCompleted,
    int? postponedCount,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      isAiGenerated: isAiGenerated,
      postponedCount: postponedCount ?? this.postponedCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'category': category.index,
      'priority': priority.index,
      'isCompleted': isCompleted ? 1 : 0,
      'isAiGenerated': isAiGenerated ? 1 : 0,
      'postponedCount': postponedCount,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      category: TaskCategory.values[map['category'] as int],
      priority: TaskPriority.values[map['priority'] as int],
      isCompleted: (map['isCompleted'] as int) == 1,
      isAiGenerated: (map['isAiGenerated'] as int) == 1,
      postponedCount: map['postponedCount'] as int,
    );
  }
}

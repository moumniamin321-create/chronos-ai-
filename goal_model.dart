class GoalModel {
  final String id;
  final String title;
  final DateTime? deadline;
  final double progress; // 0.0 - 1.0
  final bool isAchieved;

  GoalModel({
    required this.id,
    required this.title,
    this.deadline,
    this.progress = 0.0,
    this.isAchieved = false,
  });

  GoalModel copyWith({String? title, DateTime? deadline, double? progress, bool? isAchieved}) {
    return GoalModel(
      id: id,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      progress: progress ?? this.progress,
      isAchieved: isAchieved ?? this.isAchieved,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'deadline': deadline?.toIso8601String(),
      'progress': progress,
      'isAchieved': isAchieved ? 1 : 0,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] as String,
      title: map['title'] as String,
      deadline: map['deadline'] == null ? null : DateTime.parse(map['deadline'] as String),
      progress: (map['progress'] as num).toDouble(),
      isAchieved: (map['isAchieved'] as int) == 1,
    );
  }
}

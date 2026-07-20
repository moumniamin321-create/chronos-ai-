import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../core/constants.dart';

/// A parsed request, extracted from the user's free-text message to Atlas
/// (e.g. "لدي امتحان بعد أسبوع وأريد الدراسة والرياضة").
class PlanRequest {
  final int daysUntilDeadline;
  final bool wantsStudy;
  final bool wantsSport;
  final bool wantsRest;
  final String? rawGoalTitle;

  PlanRequest({
    required this.daysUntilDeadline,
    required this.wantsStudy,
    required this.wantsSport,
    required this.wantsRest,
    this.rawGoalTitle,
  });
}

/// Builds concrete, schedulable TaskModel blocks out of a PlanRequest.
/// This is intentionally rule-based (not a black box) so behaviour is
/// predictable and explainable to the user, and needs no network access.
class PlannerEngine {
  final _uuid = const Uuid();

  List<TaskModel> buildStudyPlan({
    required PlanRequest request,
    required DateTime startDate,
    required String wakeTime, // "HH:mm"
    required String sleepTime,
    int? preferredFocusHour,
  }) {
    final List<TaskModel> plan = [];
    final focusHour = preferredFocusHour ?? 9;

    for (int day = 0; day < request.daysUntilDeadline; day++) {
      final date = DateTime(startDate.year, startDate.month, startDate.day + day);

      if (request.wantsStudy) {
        final studyStart = DateTime(date.year, date.month, date.day, focusHour);
        plan.add(TaskModel(
          id: _uuid.v4(),
          title: request.rawGoalTitle != null
              ? 'مذاكرة: ${request.rawGoalTitle}'
              : 'جلسة مذاكرة',
          startTime: studyStart,
          endTime: studyStart.add(const Duration(hours: 2)),
          category: TaskCategory.study,
          priority: TaskPriority.high,
          isAiGenerated: true,
        ));

        // Short break after focused study — protects against burnout.
        final breakStart = studyStart.add(const Duration(hours: 2));
        plan.add(TaskModel(
          id: _uuid.v4(),
          title: 'استراحة قصيرة',
          startTime: breakStart,
          endTime: breakStart.add(const Duration(minutes: 20)),
          category: TaskCategory.rest,
          priority: TaskPriority.low,
          isAiGenerated: true,
        ));
      }

      if (request.wantsSport) {
        final sportStart = DateTime(date.year, date.month, date.day, 17);
        plan.add(TaskModel(
          id: _uuid.v4(),
          title: 'تمرين رياضي',
          startTime: sportStart,
          endTime: sportStart.add(const Duration(minutes: 45)),
          category: TaskCategory.sport,
          priority: TaskPriority.medium,
          isAiGenerated: true,
        ));
      }

      // Always protect sleep — Atlas never schedules over the user's
      // declared sleep window.
      final sleepParts = sleepTime.split(':').map(int.parse).toList();
      final sleepStart = DateTime(date.year, date.month, date.day, sleepParts[0], sleepParts[1]);
      plan.add(TaskModel(
        id: _uuid.v4(),
        title: 'وقت النوم',
        startTime: sleepStart,
        endTime: sleepStart.add(const Duration(hours: 8)),
        category: TaskCategory.sleep,
        priority: TaskPriority.critical,
        isAiGenerated: true,
      ));
    }

    return plan;
  }

  /// Very small natural-language parser tailored to the kind of requests
  /// Atlas is expected to receive. It looks for Arabic keywords rather
  /// than depending on an external NLU service, so it works fully offline.
  PlanRequest parseUserMessage(String message) {
    final lower = message.toLowerCase();

    int days = 7;
    final weekMatch = RegExp(r'أسبوع').hasMatch(message);
    final dayMatch = RegExp(r'(\d+)\s*(يوم|أيام)').firstMatch(message);
    final monthMatch = RegExp(r'شهر').hasMatch(message);

    if (dayMatch != null) {
      days = int.tryParse(dayMatch.group(1) ?? '7') ?? 7;
    } else if (weekMatch) {
      days = 7;
    } else if (monthMatch) {
      days = 30;
    }

    return PlanRequest(
      daysUntilDeadline: days,
      wantsStudy: lower.contains('دراس') || lower.contains('امتحان') || lower.contains('مذاكرة'),
      wantsSport: lower.contains('رياض') || lower.contains('تمرين'),
      wantsRest: lower.contains('راحة') || lower.contains('نوم'),
      rawGoalTitle: RegExp(r'امتحان\w*').firstMatch(message)?.group(0),
    );
  }
}

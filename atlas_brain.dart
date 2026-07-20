import '../models/task_model.dart';
import '../services/database_service.dart';
import 'memory_system.dart';
import 'personality_analyzer.dart';
import 'prediction_engine.dart';
import 'planner_engine.dart';
import 'recommendation_engine.dart';

/// AtlasBrain is the single entry point the UI talks to. It never touches
/// widgets directly (kept out of features/ per the project's architecture
/// rules) and coordinates the smaller, focused AI modules:
///  - MemorySystem: long-term facts about the user
///  - PersonalityAnalyzer: working-style inference
///  - PredictionEngine: short-term forecasts
///  - PlannerEngine: turns intent into real schedulable tasks
///  - RecommendationEngine: turns all of the above into tips
class AtlasBrain {
  final DatabaseService _db;
  final MemorySystem memory;
  final PersonalityAnalyzer _personality = PersonalityAnalyzer();
  final PredictionEngine _prediction = PredictionEngine();
  final PlannerEngine planner = PlannerEngine();
  final RecommendationEngine _recommendation = RecommendationEngine();

  AtlasBrain({DatabaseService? db})
      : _db = db ?? DatabaseService.instance,
        memory = MemorySystem(db: db ?? DatabaseService.instance);

  /// Full daily briefing shown on the Home screen: tips + prediction.
  Future<AtlasBriefing> dailyBriefing() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final allTasks = await _db.getAllTasks();
    final last7Days = allTasks.where((t) => t.startTime.isAfter(weekAgo)).toList();
    final todaysTasks = allTasks
        .where((t) =>
            t.startTime.year == now.year &&
            t.startTime.month == now.month &&
            t.startTime.day == now.day)
        .toList();

    final profile = _personality.analyze(allTasks);
    final bestHour = await memory.bestFocusHour();
    final prediction = _prediction.predictForToday(
      last7DaysTasks: last7Days,
      todaysTasks: todaysTasks,
      knownBestFocusHour: bestHour,
    );
    final procrastination = await memory.chronicProcrastinationByCategory();

    final tips = _recommendation.buildTips(
      profile: profile,
      prediction: prediction,
      chronicProcrastination: procrastination,
    );

    return AtlasBriefing(
      tips: tips,
      productivityRate: todaysTasks.isEmpty
          ? 0
          : todaysTasks.where((t) => t.isCompleted).length / todaysTasks.length,
      prediction: prediction,
      profile: profile,
    );
  }

  /// Handles a free-text message from the user in the chat screen and
  /// returns both a reply and, if relevant, a generated set of tasks.
  Future<AtlasReply> respondTo(String userMessage, {
    required DateTime today,
    required String wakeTime,
    required String sleepTime,
  }) async {
    final request = planner.parseUserMessage(userMessage);
    final bestHour = await memory.bestFocusHour();

    if (!request.wantsStudy && !request.wantsSport && !request.wantsRest) {
      return AtlasReply(
        text: 'فهمت طلبك، لكن لم أستطع تحديد نشاط واضح (دراسة/رياضة/راحة). '
            'جرّب مثلاً: "لدي امتحان بعد أسبوع وأريد الدراسة والرياضة".',
        generatedTasks: const [],
      );
    }

    final tasks = planner.buildStudyPlan(
      request: request,
      startDate: today,
      wakeTime: wakeTime,
      sleepTime: sleepTime,
      preferredFocusHour: bestHour,
    );

    for (final t in tasks) {
      await _db.upsertTask(t);
    }

    final parts = <String>[];
    if (request.wantsStudy) parts.add('خطة مذاكرة');
    if (request.wantsSport) parts.add('مواعيد رياضة');
    parts.add('حماية وقت نومك');

    final reply = 'تم! أنشأت لك ${parts.join(" و ")} على مدى ${request.daysUntilDeadline} '
        'يوم${bestHour != null ? "، وحرصت على وضع أهم الجلسات حوالي الساعة $bestHour لأنها وقتك الأفضل تركيزًا" : ""}.';

    return AtlasReply(text: reply, generatedTasks: tasks);
  }

  /// Should be called roughly weekly (e.g. app-open check) to let Atlas
  /// surface a fresh long-term-memory insight.
  Future<String?> maybeGenerateInsight() => memory.generateWeeklyInsight();
}

class AtlasBriefing {
  final List<String> tips;
  final double productivityRate;
  final DayPrediction prediction;
  final PersonalityProfile profile;

  AtlasBriefing({
    required this.tips,
    required this.productivityRate,
    required this.prediction,
    required this.profile,
  });
}

class AtlasReply {
  final String text;
  final List<TaskModel> generatedTasks;

  AtlasReply({required this.text, required this.generatedTasks});
}

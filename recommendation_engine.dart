import '../core/constants.dart';
import 'personality_analyzer.dart';
import 'prediction_engine.dart';

/// Combines the outputs of PersonalityAnalyzer, PredictionEngine, and
/// MemorySystem into short, actionable Arabic tips shown on the Home
/// screen and inside Atlas's chat.
class RecommendationEngine {
  List<String> buildTips({
    required PersonalityProfile profile,
    required DayPrediction prediction,
    required Map<TaskCategory, int> chronicProcrastination,
  }) {
    final tips = <String>[];

    if (prediction.needsRestSoon) {
      tips.add('لديك سلسلة مهام مكثفة اليوم — أنصحك بإضافة استراحة قصيرة قبل أن ينخفض تركيزك.');
    }

    switch (profile.workStyle) {
      case WorkStyle.morningPerson:
        tips.add('أداؤك أفضل في الصباح — حاول وضع أهم مهامك قبل الظهر.');
        break;
      case WorkStyle.nightOwl:
        tips.add('لاحظت أنك تنجز أكثر في المساء — استغل هذا الوقت للمهام الصعبة.');
        break;
      case WorkStyle.burstWorker:
      case WorkStyle.steady:
        break;
    }

    if (chronicProcrastination.isNotEmpty) {
      final worst = chronicProcrastination.entries.reduce((a, b) => a.value > b.value ? a : b);
      tips.add('تلاحظ أنك تؤجل مهام "${worst.key.labelAr}" بشكل متكرر — جرّب تقسيمها لخطوات أصغر.');
    }

    if (profile.disciplineScore < 0.4) {
      tips.add('نسبة إنجازك للمهام منخفضة هذا الأسبوع — لا بأس، جرّب تقليل عدد المهام اليومية بدل زيادتها.');
    } else if (profile.disciplineScore > 0.8) {
      tips.add('انضباطك ممتاز هذا الأسبوع! استمر بهذا المستوى.');
    }

    if (tips.isEmpty) {
      tips.add('أضف بعض المهام حتى أتمكن من تحليل نمط يومك وتقديم نصائح مخصصة لك.');
    }

    return tips;
  }
}

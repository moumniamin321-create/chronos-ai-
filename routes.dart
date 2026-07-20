import 'package:flutter/material.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/assistant/atlas_chat_screen.dart';
import '../features/planner/daily_plan_screen.dart';
import '../features/planner/calendar_screen.dart';
import '../features/habits/habits_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/profile/profile_screen.dart';

/// Central place for every named route in the app.
/// Keeping this separate from main.dart means adding a new screen later
/// never requires touching app bootstrapping code.
class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String assistant = '/assistant';
  static const String dailyPlan = '/daily-plan';
  static const String calendar = '/calendar';
  static const String habits = '/habits';
  static const String progress = '/progress';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
        onboarding: (_) => const OnboardingScreen(),
        home: (_) => const HomeScreen(),
        assistant: (_) => const AtlasChatScreen(),
        dailyPlan: (_) => const DailyPlanScreen(),
        calendar: (_) => const CalendarScreen(),
        habits: (_) => const HabitsScreen(),
        progress: (_) => const ProgressScreen(),
        profile: (_) => const ProfileScreen(),
      };
}

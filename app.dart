import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'core/app_state.dart';
import 'core/constants.dart';
import 'services/storage_service.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';

class ChronosApp extends StatelessWidget {
  const ChronosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routes: AppRoutes.routes,
        home: const _StartupGate(),
      ),
    );
  }
}

/// Decides whether to show onboarding or jump straight to Home, based on
/// whether a local profile already exists.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final done = await StorageService.instance.getBool(AppConstants.prefOnboardingDone);
    if (done) {
      await context.read<AppState>().loadUser();
    }
    if (mounted) setState(() => _onboardingDone = done);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0E1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _onboardingDone! ? const HomeScreen() : const OnboardingScreen();
  }
}

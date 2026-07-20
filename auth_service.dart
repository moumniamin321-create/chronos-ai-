import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'storage_service.dart';

/// There are no accounts, passwords, or sign-in in Chronos AI — this is a
/// single-user, single-device app by design. "AuthService" here just
/// means: has the user finished onboarding, and do we have a local
/// profile? This keeps the app free and removes any account-related
/// backend cost entirely.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final _uuid = const Uuid();

  Future<bool> hasCompletedOnboarding() {
    return StorageService.instance.getBool(AppConstants.prefOnboardingDone);
  }

  Future<UserModel> createLocalProfile({
    required String name,
    required int age,
    required List<String> goals,
    required String wakeTime,
    required String sleepTime,
  }) async {
    final user = UserModel(
      id: _uuid.v4(),
      name: name,
      age: age,
      goals: goals,
      wakeTime: wakeTime,
      sleepTime: sleepTime,
    );

    await DatabaseService.instance.saveUser(user);
    await StorageService.instance.setBool(AppConstants.prefOnboardingDone, true);
    await StorageService.instance.setString(AppConstants.prefUserId, user.id);
    return user;
  }

  Future<UserModel?> currentUser() => DatabaseService.instance.getUser();
}

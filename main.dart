import 'package:flutter/material.dart';
import 'app.dart';
import 'core/error_handler.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorHandler.install();

  await StorageService.instance.init();
  await NotificationService.instance.init();

  runApp(const ChronosApp());
}

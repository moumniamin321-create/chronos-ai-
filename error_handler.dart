import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Central error handling so a single failed widget or a bad database read
/// never crashes the whole app — it degrades gracefully and logs instead.
class AppErrorHandler {
  AppErrorHandler._();

  static void install() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _log(details.exceptionAsString(), details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _log(error.toString(), stack);
      return true;
    };
  }

  static void _log(String message, StackTrace? stack) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Chronos AI] Unhandled error: $message\n$stack');
    }
    // In a production build this is the place to forward errors to a
    // local log file (see StorageService.appendErrorLog), never to a
    // remote server, since this app is fully offline by design.
  }

  /// Wraps a fallible async call and returns [fallback] instead of throwing,
  /// while still logging what went wrong. Use this around AI/planning logic
  /// so a bad prediction never breaks the UI.
  static Future<T> guard<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } catch (e, st) {
      _log(e.toString(), st);
      return fallback;
    }
  }
}

/// A small reusable widget for showing a friendly inline error instead of
/// a red screen of death.
class ErrorFallback extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorFallback({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ],
        ),
      ),
    );
  }
}

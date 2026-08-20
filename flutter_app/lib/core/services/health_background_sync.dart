import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'health_service.dart';
import 'auth_manager.dart';

/// Background health synchronisation.
///
/// Google Health does not provide a reliable "new data inserted" push event
/// to this Flutter client. Instead, Android/iOS wakes the app periodically and
/// the sync engine checks MongoDB sync points. If the daily point is not due,
/// no Google Health request is made.
class HealthBackgroundSync {
  static const String taskName = 'pulse_ai_health_daily_sync';
  static const String uniqueName = 'pulse_ai_health_daily_sync_unique';

  static bool _initialized = false;

  static Future<void> ensureScheduled() async {
    if (kIsWeb) return;

    try {
      if (!_initialized) {
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );
        _initialized = true;
      }

      final scheduled =
          await Workmanager().isScheduledByUniqueName(uniqueName);

      if (!scheduled) {
        await Workmanager().registerPeriodicTask(
          uniqueName,
          taskName,
          frequency: const Duration(hours: 24),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );
      }
    } catch (e) {
      debugPrint('[HealthBackgroundSync] scheduling failed: $e');
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      ui.DartPluginRegistrant.ensureInitialized();

      if (taskName != HealthBackgroundSync.taskName) {
        return true;
      }

      // Restore the Google account silently and refresh its access token.
      final connected = await HealthService.initialize();
      if (!connected || !HealthService.isConnected) {
        // Nothing to sync until the user has connected Google Health.
        return true;
      }

      final jwt = await AuthManager().getToken();
      if (jwt == null || jwt.isEmpty) {
        // Authentication may be restored on the next foreground run.
        return true;
      }

      // smartSyncHealth() is incremental:
      // - first-ever empty MongoDB -> full history import
      // - existing MongoDB data -> only recent due window
      // - no due sync point -> zero Google Health data fetch
      final result = await HealthService.smartSyncHealth(jwt, force: false);

      debugPrint(
        '[HealthBackgroundSync] '
        'skipped=${result['skipped']} '
        'new=${result['newRecords']} '
        'updated=${result['updatedRecords']}',
      );

      return true;
    } catch (e, stack) {
      debugPrint('[HealthBackgroundSync] task failed: $e');
      debugPrint('$stack');
      return false;
    }
  });
}

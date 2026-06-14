import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class HealthService {
  static final Health health = Health();

  static final List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.EXERCISE_TIME,
  ];

  static Future<bool> connect() async {
    if (kIsWeb) {
      debugPrint(
        "Health Connect is not supported on Web",
      );
      return false;
    }

    try {
      return await health.requestAuthorization(
        types,
      );
    } catch (e) {
      debugPrint(
        "Health permission error: $e",
      );
      return false;
    }
  }

  static Future<Map<String, dynamic>>
      getTodayHealthData() async {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    );

    int steps =
        await health.getTotalStepsInInterval(
              start,
              now,
            ) ??
            0;

    double heartRate = 0;
    double restingHeartRate = 0;
    double calories = 0;
    double sleepHours = 0;
    double bloodOxygen = 0;
    double bodyTemperature = 0;
    double distanceWalked = 0;
    double activeHours = 0;

    String source = "Unknown";

    try {
      final healthData =
          await health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: types,
      );

      for (final item in healthData) {
        try {
          source = item.sourceName;

          final value =
              double.tryParse(
                    item.value.toString(),
                  ) ??
                  0;

          switch (item.type) {
            case HealthDataType.HEART_RATE:
              heartRate = value;
              break;

            case HealthDataType.RESTING_HEART_RATE:
              restingHeartRate = value;
              break;

            case HealthDataType.ACTIVE_ENERGY_BURNED:
              calories += value;
              break;

            case HealthDataType.DISTANCE_DELTA:
              distanceWalked += value;
              break;

            case HealthDataType.BLOOD_OXYGEN:
              bloodOxygen = value;
              break;

            case HealthDataType.BODY_TEMPERATURE:
              bodyTemperature = value;
              break;

            case HealthDataType.EXERCISE_TIME:
              activeHours += value / 60;
              break;

            case HealthDataType.SLEEP_ASLEEP:
              sleepHours += item.dateTo
                      .difference(
                        item.dateFrom,
                      )
                      .inMinutes /
                  60;
              break;

            default:
              break;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint(
        "Health data fetch error: $e",
      );
    }

    return {
      "steps": steps,
      "heartRate": heartRate.round(),
      "restingHeartRate":
          restingHeartRate.round(),
      "calories": calories.round(),
      "sleepHours":
          double.parse(
        sleepHours.toStringAsFixed(1),
      ),
      "bloodOxygen":
          double.parse(
        bloodOxygen.toStringAsFixed(1),
      ),
      "bodyTemperature":
          double.parse(
        bodyTemperature.toStringAsFixed(1),
      ),
      "distanceWalked":
          double.parse(
        distanceWalked.toStringAsFixed(2),
      ),
      "activeHours":
          double.parse(
        activeHours.toStringAsFixed(1),
      ),
      "source": source,
      "syncedAt":
          DateTime.now().toIso8601String(),
    };
  }

  static Future<bool> syncToBackend(
    String jwt,
  ) async {
    try {
      final data =
          await getTodayHealthData();

      final response = await http.post(
        Uri.parse(
          "${ApiConstants.baseUrl}/health-connect/sync",
        ),
        headers: {
          "Content-Type":
              "application/json",
          "Authorization":
              "Bearer $jwt",
        },
        body: jsonEncode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        "Backend sync error: $e",
      );
      return false;
    }
  }
}
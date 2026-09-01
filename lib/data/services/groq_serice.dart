import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:flutter/material.dart';

class GroqService {
  static final GroqService _instance = GroqService._internal();

  factory GroqService() {
    return _instance;
  }

  GroqService._internal();

  Future<String> generateCategory(
    String name,
    bool isExpense,
    BuildContext context,
  ) async {
    return "";
  }

  Future<Map<String, dynamic>?> parseNotificationTransaction(
    String notificationText,
    String appName,
    double fallbackAmount,
    BuildContext context,
  ) async {
    return null;
  }

  Future<List<Map<String, dynamic>>?> parseImageMovements(
    String base64Image,
    String mimeType,
    BuildContext context,
  ) async {
    return [];
  }

  Future<List<String>> generateTags(String names, BuildContext context) async {
    return [];
  }

  Future<String> generateSummary(
    List<MovementValue> movements,
    Month month,
    BuildContext context,
  ) async {
    return "";
  }
}

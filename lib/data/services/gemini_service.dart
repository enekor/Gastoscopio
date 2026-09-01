import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:flutter/material.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal();

  bool get hasApiKey => false;

  Future initializeGemini() async {
    // Deprecated
  }

  Future<String> generateCategory(
    String name,
    bool isExpense,
    BuildContext context,
  ) async {
    return "";
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

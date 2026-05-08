import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import '../models.dart';

class QuestionRepository {
  Future<List<Question>> loadAllQuestions() async {
    try {
      print('Loading questions from assets...');
      final jsonString = await rootBundle.loadString('assets/questions.json').timeout(const Duration(seconds: 5));
      print('Loaded JSON string of length ${jsonString.length}');
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      print('Decoded ${decoded.length} questions');
      final questions = decoded.map((item) => Question.fromJson(item)).toList();
      print('Parsed ${questions.length} questions successfully');
      return questions;
    } on TimeoutException {
      print('Timeout loading questions from assets');
      return [];
    } catch (e) {
      print('Error loading questions: $e');
      rethrow;
    }
  }
}
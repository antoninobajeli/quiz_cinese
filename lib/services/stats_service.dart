import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class StatsService {
  Future<Map<int, QuestionStats>>? _cachedStats;

  Future<Map<int, QuestionStats>> loadQuestionStatsMap() async {
    if (_cachedStats != null) return _cachedStats!;
    
    _cachedStats = _loadQuestionStatsMap();
    return _cachedStats!;
  }

  Future<Map<int, QuestionStats>> _loadQuestionStatsMap() async {
    try {
      print('Loading question stats...');
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 10));
      final sessions = prefs.getStringList('quiz_sessions') ?? [];
      print('Found ${sessions.length} sessions');
      final stats = <int, QuestionStats>{};

      for (final sessionJson in sessions) {
        try {
          final session = jsonDecode(sessionJson) as Map<String, dynamic>;
          final answers = session['answers'] as List<dynamic>? ?? [];

          for (final answerJson in answers) {
            final answer = QuizAnswer.fromJson(answerJson as Map<String, dynamic>);
            final existing = stats[answer.questionId];
            if (existing == null) {
              stats[answer.questionId] = QuestionStats(
                lastUpdate:DateTime.now(),
                questionId: answer.questionId,
                correctAnswers: answer.isCorrect ? 1 : 0,
                incorrectAnswers: answer.isCorrect ? 0 : 1,
              );
            } else {
              stats[answer.questionId] = QuestionStats(
                lastUpdate:DateTime.now(),
                questionId: existing.questionId,
                correctAnswers: existing.correctAnswers + (answer.isCorrect ? 1 : 0),
                incorrectAnswers: existing.incorrectAnswers + (answer.isCorrect ? 0 : 1),
              );
            }
          }
        } catch (e) {
          print('Error parsing session: $e');
        }
      }

      print('Loaded stats for ${stats.length} questions');
      return stats;
    } on TimeoutException {
      print('Timeout loading SharedPreferences');
      return {};
    } catch (e) {
      print('Error loading stats: $e');
      rethrow;
    }
  }

  Future<QuestionStats> getQuestionStats(int questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = prefs.getStringList('quiz_sessions') ?? [];

    int correct = 0;
    int incorrect = 0;

    for (final sessionJson in sessions) {
      try {
        final session = jsonDecode(sessionJson) as Map<String, dynamic>;
        final answers = session['answers'] as List<dynamic>? ?? [];

        for (final answerJson in answers) {
          final answer = QuizAnswer.fromJson(answerJson as Map<String, dynamic>);
          if (answer.questionId == questionId) {
            if (answer.isCorrect) {
              correct++;
            } else {
              incorrect++;
            }
          }
        }
      } catch (e) {
        // Ignora sessioni malformate
      }
    }

    return QuestionStats(
      lastUpdate:DateTime.now(),
      questionId: questionId,
      correctAnswers: correct,
      incorrectAnswers: incorrect,
    );
  }

  Future<void> saveQuizSession(List<QuizAnswer> answers, int correctCount) async {
    final prefs = await SharedPreferences.getInstance();
    final quizSession = {
      'timestamp': DateTime.now().toIso8601String(),
      'correctCount': correctCount,
      'totalQuestions': answers.length,
      'answers': answers.map((a) => a.toJson()).toList(),
    };

    final sessions = prefs.getStringList('quiz_sessions') ?? [];
    sessions.add(jsonEncode(quizSession));
    await prefs.setStringList('quiz_sessions', sessions);
  }

  Future<List<QuizSessionSummary>> loadAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = prefs.getStringList('quiz_sessions') ?? [];
      final summaries = <QuizSessionSummary>[];

      for (final sessionJson in sessions) {
        try {
          final session = jsonDecode(sessionJson) as Map<String, dynamic>;
          final timestamp = DateTime.parse(session['timestamp'] as String);
          final correctCount = session['correctCount'] as int;
          final totalQuestions = session['totalQuestions'] as int;
          final answers = (session['answers'] as List<dynamic>?)
              ?.map((a) => QuizAnswer.fromJson(a as Map<String, dynamic>))
              .toList() ?? [];

          summaries.add(QuizSessionSummary(
            timestamp: timestamp,
            correctCount: correctCount,
            totalQuestions: totalQuestions,
            answers: answers,
          ));
        } catch (e) {
          print('Error parsing session: $e');
        }
      }

      // Ordina le sessioni per data decrescente (più recenti prima)
      summaries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return summaries;
    } catch (e) {
      print('Error loading sessions: $e');
      return [];
    }
  }
}
import 'dart:math';
import '../models.dart';
import 'question_repository.dart';
import 'stats_service.dart';

class QuizService {
  final QuestionRepository _questionRepository;
  final StatsService _statsService;
  final Random _random;

  QuizService({
    QuestionRepository? questionRepository,
    StatsService? statsService,
    Random? random,
  }) : _questionRepository = questionRepository ?? QuestionRepository(),
       _statsService = statsService ?? StatsService(),
       _random = random ?? Random();

  QuestionRepository get questionRepository => _questionRepository;

  Future<List<Question>> loadQuizQuestions({int? questionCount}) async {
    try {
      print('Loading quiz questions...');
      final allQuestions = await _questionRepository.loadAllQuestions();
      print('Loaded ${allQuestions.length} total questions');
      final questionStats = await _statsService.loadQuestionStatsMap();
      print('Loaded stats for ${questionStats.length} questions');

      final sortedQuestions = List<Question>.from(allQuestions);
      sortedQuestions.sort((a, b) {
        final statsA = questionStats[a.id] ?? QuestionStats(questionId: a.id, correctAnswers: 0, incorrectAnswers: 0);
        final statsB = questionStats[b.id] ?? QuestionStats(questionId: b.id, correctAnswers: 0, incorrectAnswers: 0);

        final totalA = statsA.correctAnswers + statsA.incorrectAnswers;
        final totalB = statsB.correctAnswers + statsB.incorrectAnswers;
        final ratioA = totalA == 0 ? 0.5 : statsA.correctAnswers / totalA;
        final ratioB = totalB == 0 ? 0.5 : statsB.correctAnswers / totalB;
        return ratioA.compareTo(ratioB);
      });

      final countToUse = questionCount;
      final questionsToUse = countToUse != null
          ? _selectWeightedRandomQuestions(sortedQuestions, questionStats, countToUse)
          : sortedQuestions;

      print('Selected ${questionsToUse.length} questions for quiz');
      return questionsToUse;
    } catch (e) {
      print('Error loading quiz questions: $e');
      rethrow;
    }
  }

  List<Question> _selectWeightedRandomQuestions(
    List<Question> sortedQuestions,
    Map<int, QuestionStats> stats,
    int count,
  ) {
    if (count >= sortedQuestions.length) {
      return List<Question>.from(sortedQuestions);
    }

    final remaining = List<Question>.from(sortedQuestions);
    final selected = <Question>[];
    int attempts = 0;
    const maxAttempts = 1000; // Safeguard against infinite loop

    while (selected.length < count && remaining.isNotEmpty && attempts < maxAttempts) {
      final weights = <double>[];
      for (final question in remaining) {
        final stat = stats[question.id] ?? QuestionStats(questionId: question.id, correctAnswers: 0, incorrectAnswers: 0);
        final totalAsked = stat.correctAnswers + stat.incorrectAnswers;
        final ratio = totalAsked == 0 ? 0.5 : stat.correctAnswers / totalAsked;

        final priorityWeight = 1.0 - ratio;
        final askWeight = 1.0 / (1 + totalAsked);
        final combinedWeight = priorityWeight * 0.7 + askWeight * 0.3 + 0.01;
        weights.add(combinedWeight);
      }

      final totalWeight = weights.fold(0.0, (sum, w) => sum + w);
      if (totalWeight <= 0) {
        // If no weights, select randomly
        final randomIndex = _random.nextInt(remaining.length);
        selected.add(remaining.removeAt(randomIndex));
        continue;
      }

      final choice = _random.nextDouble() * totalWeight;
      double cumulative = 0.0;
      int chosenIndex = -1;

      for (var i = 0; i < remaining.length; i++) {
        cumulative += weights[i];
        if (choice <= cumulative) {
          chosenIndex = i;
          break;
        }
      }

      if (chosenIndex >= 0 && chosenIndex < remaining.length) {
        selected.add(remaining.removeAt(chosenIndex));
      } else {
        // Fallback: select first
        selected.add(remaining.removeAt(0));
      }

      attempts++;
    }

    // If we couldn't select enough, fill with remaining
    while (selected.length < count && remaining.isNotEmpty) {
      selected.add(remaining.removeAt(0));
    }

    return selected;
  }
}
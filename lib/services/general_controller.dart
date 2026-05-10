import 'package:flutter/material.dart';
import 'package:quizcinese/sessions/scratch_session.dart';
import '../models.dart';
import 'quiz_service.dart';
import 'stats_service.dart';
import '../sessions/quiz_session.dart';
import '../sessions/gaming_session.dart';

class GeneralController extends ChangeNotifier {
  final QuizService _quizService;
  final StatsService _statsService;

  QuizSession quizSession = QuizSession();
  GamingSession gamingSession = GamingSession();
  ScratchSession scratchSession = ScratchSession();

  Future<List<Question>>? _quizQuestionsFuture;
  Future<List<Question>>? _gamingQuestionsFuture;
  Future<List<Question>>? _scratchQuestionsFuture;
  late Future<List<Question>> allQuestionsFuture;

  Future<List<Question>>? get quizQuestionsFuture => _quizQuestionsFuture;
  Future<List<Question>>? get gamingQuestionsFuture => _gamingQuestionsFuture;
  Future<List<Question>>? get scratchQuestionsFuture => _scratchQuestionsFuture;

  GeneralController({
    QuizService? quizService,
    StatsService? statsService,
  }) : _quizService = quizService ?? QuizService(),
       _statsService = statsService ?? StatsService() {
    _loadAllQuestions();
  }

  void _loadAllQuestions() {
    allQuestionsFuture = _quizService.questionRepository.loadAllQuestions();
  }

  void startQuiz(int questionCount) {
    _quizQuestionsFuture = _quizService.loadQuizQuestions(questionCount: questionCount).then((questions) {
      quizSession.startQuiz(questions);
      notifyListeners();
      return questions;
    });
    notifyListeners();
  }

  void startGaming(int questionCount) {
    _gamingQuestionsFuture = _quizService.loadQuizQuestions(questionCount: questionCount).then((questions) {
      gamingSession.startGaming(questions);
      notifyListeners();
      return questions;
    });
    notifyListeners();
  }

  void startScratch(int questionCount) {
    _scratchQuestionsFuture = _quizService.loadQuizQuestions(questionCount: questionCount).then((questions) {
      scratchSession.startGaming(questions);
      notifyListeners();
      return questions;
    });
    notifyListeners();
  }



  void confirmStartQuiz(List<Question> questions) {
    quizSession.startQuiz(questions);
    notifyListeners();
  }

  void confirmStartGaming(List<Question> questions) {
    gamingSession.startGaming(questions);
    notifyListeners();
  }

  void confirmStartScratch(List<Question> questions) {
    scratchSession.startGaming(questions);
    notifyListeners();
  }



  void submitQuizAnswer(String answer) {
    quizSession.submitAnswer(answer);
    notifyListeners();
  }

  void submitGamingAnswer(String selectedChar) {
    gamingSession.submitAnswer(selectedChar);
    notifyListeners();
  }

  void submitScratchAnswer(String guessAnswer) {
    scratchSession.submitAnswer(guessAnswer);
    notifyListeners();
  }




  void nextQuizQuestion() {
    if (!quizSession.nextQuestion()) {
      // Quiz completed
      _saveQuizScore();
    }
    notifyListeners();
  }

  void nextGamingQuestion() {
    if (!gamingSession.nextQuestion()) {
      // Gaming completed
    }
    notifyListeners();
  }

  void nextScratchQuestion() {
    if (!scratchSession.nextQuestion()) {
      // Quiz completed
      _saveQuizScore();
    }
    notifyListeners();
  }



  void endQuiz() {
    _saveQuizScore();
    notifyListeners();
  }

  void endGaming() {
    notifyListeners();
  }


  void endScratch() {
    _saveQuizScore();
    notifyListeners();
  }


  void restartQuiz() {
    quizSession.reset();
    _quizQuestionsFuture = null;
    notifyListeners();
  }

  void restartGaming() {
    gamingSession.reset();
    _gamingQuestionsFuture = null;
    notifyListeners();
  }
  void restartScratch() {
    scratchSession.reset();
    _scratchQuestionsFuture = null;
    notifyListeners();
  }



  Future<void> _saveQuizScore() async {
    await _statsService.saveQuizSession(quizSession.answers, quizSession.correctCount);
  }

  Future<Map<int, QuestionStats>>? _statsFuture;

  Future<Map<int, QuestionStats>> loadStats() {
    return _statsFuture ??= _statsService.loadQuestionStatsMap();
  }

  Future<QuestionStats> getQuestionStats(int questionId) {
    return _statsService.getQuestionStats(questionId);
  }
}
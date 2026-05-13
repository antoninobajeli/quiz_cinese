import 'package:flutter/material.dart';
import 'package:quizcinese/sessions/scratch_session.dart';
import '../models.dart';
import 'quiz_service.dart';
import 'stats_service.dart';
import '../sessions/quiz_session.dart';
import '../sessions/drawing_session.dart';

class GeneralController extends ChangeNotifier {
  final QuizService _generalService;
  final StatsService _statsService;

  QuizSession quizSession = QuizSession();
  DrawingSession drawingSession = DrawingSession();
  ScratchSession scratchSession = ScratchSession();

  Future<List<Question>>? _quizQuestionsFuture;
  Future<List<Question>>? _drawingQuestionsFuture;
  Future<({List<Question> quizQuestions, List<Question> allQuestions})>? _scratchQuestionsFuture;
  late Future<List<Question>> allQuestionsFuture;

  Future<List<Question>>? get quizQuestionsFuture => _quizQuestionsFuture;
  Future<List<Question>>? get drawingQuestionsFuture => _drawingQuestionsFuture;
  Future<({List<Question> quizQuestions, List<Question> allQuestions})>? get scratchQuestionsFuture => _scratchQuestionsFuture;

  GeneralController({
    QuizService? quizService,
    StatsService? statsService,
  }) : _generalService = quizService ?? QuizService(),
       _statsService = statsService ?? StatsService() {
    _loadAllQuestions();
  }

  void _loadAllQuestions() {
    allQuestionsFuture = _generalService.questionRepository.loadAllQuestions();
  }

  void startQuiz(int questionCount) {
    _quizQuestionsFuture = _generalService.loadQuizQuestions(questionCount: questionCount).then((questions) {
      quizSession.startQuiz(questions.quizQuestions);
      notifyListeners();
      return questions.quizQuestions;
    });
    notifyListeners();
  }

  void startDrawing(int questionCount) {
    _drawingQuestionsFuture = _generalService.loadQuizQuestions(questionCount: questionCount).then((questions) {
      drawingSession.startDrawing(questions.quizQuestions);
      notifyListeners();
      return questions.quizQuestions;
    });
    notifyListeners();
  }

  void startScratch(int questionCount) {
    _scratchQuestionsFuture = _generalService.loadQuizQuestions(questionCount: questionCount).then((questions) {
      scratchSession.startScratching(questions);
      notifyListeners();
      return questions;
    });
    notifyListeners();
  }



  void confirmStartQuiz(List<Question> questions) {
    quizSession.startQuiz(questions);
    notifyListeners();
  }

  void confirmStartDrawing(List<Question> questions) {
    drawingSession.startDrawing(questions);
    notifyListeners();
  }
/*
  void confirmStartScratch(List<Question> questions) {
    scratchSession.startDrawing(questions);
    notifyListeners();
  }*/



  void submitQuizAnswer(String answer) {
    quizSession.submitAnswer(answer);
    notifyListeners();
  }

  void submitDrawingAnswer(String selectedChar) {
    drawingSession.submitAnswer(selectedChar);
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

  void nextDrawingQuestion() {
    if (!drawingSession.nextQuestion()) {
      // Drawing completed
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

  void endDrawing() {
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

  void restartDrawing() {
    drawingSession.reset();
    _drawingQuestionsFuture = null;
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
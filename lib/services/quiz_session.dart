import '../models.dart';

class QuizSession {
  List<Question> questions = [];
  int currentIndex = 0;
  int correctCount = 0;
  List<QuizAnswer> answers = [];
  String? feedbackMessage;
  bool isStarted = false;

  void startQuiz(List<Question> loadedQuestions) {
    questions = loadedQuestions;
    currentIndex = 0;
    correctCount = 0;
    answers.clear();
    feedbackMessage = null;
    isStarted = true;
  }

  void submitAnswer(String userAnswer) {
    final current = questions[currentIndex];
    final isCorrect = userAnswer.toLowerCase() == current.answer.toLowerCase();

    answers.add(QuizAnswer(
      questionId: current.id,
      question: current.question,
      userAnswer: userAnswer,
      correctAnswer: current.answer,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
    ));

    feedbackMessage = isCorrect
        ? 'Risposta corretta!'
        : 'Risposta errata. La risposta giusta è: ${current.answer} --  ${current.answerpinyin ?? ""}';

    if (isCorrect) {
      correctCount += 1;
    }
  }

  bool nextQuestion() {
    if (currentIndex + 1 < questions.length) {
      currentIndex += 1;
      feedbackMessage = null;
      return true;
    }
    return false; // Quiz finished
  }

  void reset() {
    questions.clear();
    currentIndex = 0;
    correctCount = 0;
    answers.clear();
    feedbackMessage = null;
    isStarted = false;
  }

  bool get isCompleted => currentIndex >= questions.length - 1 && feedbackMessage != null;
  int get totalQuestions => questions.length;
  double get progress => questions.isEmpty ? 0 : (currentIndex + 1) / questions.length;
}
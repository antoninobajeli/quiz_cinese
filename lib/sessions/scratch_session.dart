import '../models.dart';

class ScratchSession {
  List<Question> questions = [];
  int currentIndex = 0;
  int correctCount = 0;
  List<QuizAnswer> answers = [];
  String? feedbackMessage;
  bool isStarted = false;

  void startGaming(List<Question> loadedQuestions) {
    questions = loadedQuestions;
    currentIndex = 0;
    correctCount = 0;
    answers.clear();
    feedbackMessage = null;
    isStarted = true;
  }

  void submitAnswer(String selectedChar) {
    final current = questions[currentIndex];
    // In gaming mode, input is always considered correct as validation happens in UI

    final isCorrect = current.answerpinyin!.toLowerCase().compareTo(selectedChar.toLowerCase())==0;


    answers.add(QuizAnswer(
      questionId: current.id,
      question: current.question,
      userAnswer: selectedChar,
      correctAnswer: current.answer,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
    ));


    feedbackMessage = isCorrect
        ? 'Ottimo! "$selectedChar" è corretto! ✨'
        : 'Risposta errata $selectedChar. Il pinyin corretto è: "${current.answerpinyin}"';

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
    return false; // Gaming finished
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
}
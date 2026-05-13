import '../models.dart';

class ScratchSession {
  List<Question> currPlayQuestions = [];
  List<Question> kowledgebase = [];
  int currentIndex = 0;
  int correctCount = 0;
  List<QuizAnswer> answers = [];
  String? feedbackMessage;
  bool isStarted = false;

  void startScratching(({List<Question> allQuestions, List<Question> quizQuestions}) loadedQuestions) {
    currPlayQuestions = loadedQuestions.quizQuestions;
    kowledgebase = loadedQuestions.allQuestions;
    currentIndex = 0;
    correctCount = 0;
    answers.clear();
    feedbackMessage = null;
    isStarted = true;
  }

  void submitAnswer(String selectedChar) {
    final current = currPlayQuestions[currentIndex];
    // In Scratch mode, input is always considered correct as validation happens in UI

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
    if (currentIndex + 1 < currPlayQuestions.length) {
      currentIndex += 1;
      feedbackMessage = null;
      return true;
    }
    return false; // Scratch finished
  }

  void reset() {
    currPlayQuestions.clear();
    currentIndex = 0;
    correctCount = 0;
    answers.clear();
    feedbackMessage = null;
    isStarted = false;
  }

  bool get isCompleted => currentIndex >= currPlayQuestions.length - 1 && feedbackMessage != null;
  int get totalQuestions => currPlayQuestions.length;
}
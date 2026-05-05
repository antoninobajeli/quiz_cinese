enum AllQuestionsSortOption {
  id,
  ratio,
  totalAsked,
}

enum QuestionType {
  text,
  multipleChoice,
}

class QuizAnswer {
  final int questionId;
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final DateTime timestamp;

  QuizAnswer({
    required this.questionId,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'question': question,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      questionId: json['questionId'] as int,
      question: json['question'] as String,
      userAnswer: json['userAnswer'] as String,
      correctAnswer: json['correctAnswer'] as String,
      isCorrect: json['isCorrect'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class Question {
  final int id;
  final QuestionType type;
  final String question;
  final String answer;
  final List<String>? choices;

  Question({
    required this.id,
    required this.type,
    required this.question,
    required this.answer,
    this.choices,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      type: json['type'] == 'multiple_choice' ? QuestionType.multipleChoice : QuestionType.text,
      question: json['question'] as String,
      answer: json['answer'] as String,
      choices: json['choices'] != null ? List<String>.from(json['choices'] as List<dynamic>) : null,
    );
  }
}

class QuestionStats {
  final int questionId;
  final int correctAnswers;
  final int incorrectAnswers;

  QuestionStats({
    required this.questionId,
    required this.correctAnswers,
    required this.incorrectAnswers,
  });
}

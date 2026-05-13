enum AllQuestionsSortOption {
  id,
  question_az,
  question_za,
  pinyin_az,
  pinyin_za,
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
  final String? answerpinyin;
  final String? answerclassgr;
  final List<String>? choices;

  Question({
    required this.id,
    required this.type,
    required this.question,
    required this.answer,
    this.answerpinyin,
    this.answerclassgr,
    this.choices,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      type: json['type'] == 'multiple_choice' ? QuestionType.multipleChoice : QuestionType.text,
      question: json['question'] as String,
      answer: json['answer'] as String,
      answerpinyin: json['answerpinyin'] as String?,
      answerclassgr: json['answerclassgr'] as String?,
      choices: json['choices'] != null ? List<String>.from(json['choices'] as List<dynamic>) : null,
    );
  }
}

class QuestionStats {
  final DateTime lastUpdate;
  final int questionId;
  final int correctAnswers;
  final int incorrectAnswers;

  QuestionStats({
    required this.lastUpdate,
    required this.questionId,
    required this.correctAnswers,
    required this.incorrectAnswers,
  });
}

class QuizSessionSummary {
  final DateTime timestamp;
  final int correctCount;
  final int totalQuestions;
  final double percentage;
  final List<QuizAnswer> answers;

  QuizSessionSummary({
    required this.timestamp,
    required this.correctCount,
    required this.totalQuestions,
    required this.answers,
  }) : percentage = totalQuestions > 0 ? (correctCount / totalQuestions) : 0.0;

  String get formattedDate => '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  
  String get formattedPercentage => '${(percentage * 100).toStringAsFixed(0)}%';
  
  String get emoticon {
    if (percentage == 1.0) return '🏆';
    if (percentage >= 0.8) return '🌟';
    if (percentage >= 0.6) return '👍';
    if (percentage >= 0.4) return '📚';
    return '💪';
  }
}

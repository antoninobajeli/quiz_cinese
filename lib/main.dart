import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Cinese',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const QuizHomePage(),
    );
  }
}

class QuizHomePage extends StatefulWidget {
  const QuizHomePage({super.key});

  @override
  State<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage> {
  late Future<List<Question>> _questionsFuture;
  final _answerController = TextEditingController();
  String? _selectedChoice;
  int _currentIndex = 0;
  String? _feedbackMessage;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _loadQuestions();
  }

  Future<List<Question>> _loadQuestions() async {
    final jsonString = await rootBundle.loadString('assets/questions.json');
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    final questions = decoded.map((item) => Question.fromJson(item)).toList();
    questions.shuffle();
    return questions;
  }

  void _submitAnswer(List<Question> questions) {
    final current = questions[_currentIndex];
    final answer = current.type == QuestionType.text
        ? _answerController.text.trim()
        : _selectedChoice ?? '';

    final isCorrect = answer.toLowerCase() == current.answer.toLowerCase();
    setState(() {
      _feedbackMessage = isCorrect ? 'Risposta corretta!' : 'Risposta errata. La risposta giusta è: ${current.answer}';
      if (isCorrect) {
        _correctCount += 1;
      }
    });
  }

  void _nextQuestion(List<Question> questions) {
    if (_currentIndex + 1 < questions.length) {
      setState(() {
        _currentIndex += 1;
        _answerController.clear();
        _selectedChoice = null;
        _feedbackMessage = null;
      });
    } else {
      _showScoreDialog(questions.length);
    }
  }

  void _showScoreDialog(int total) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz completato'),
        content: Text('Hai risposto correttamente a $_correctCount domande su $total.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartQuiz();
            },
            child: const Text('Ricomincia'),
          ),
        ],
      ),
    );
  }

  void _restartQuiz() {
    setState(() {
      _questionsFuture = _loadQuestions();
      _currentIndex = 0;
      _correctCount = 0;
      _feedbackMessage = null;
      _answerController.clear();
      _selectedChoice = null;
    });
  }

  Widget _buildAnswerInput(Question question) {
    if (question.type == QuestionType.multipleChoice) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: question.choices!.map((choice) {
          return RadioListTile<String>(
            title: Text(choice),
            value: choice,
            groupValue: _selectedChoice,
            onChanged: (value) {
              setState(() {
                _selectedChoice = value;
              });
            },
          );
        }).toList(),
      );
    }

    return TextField(
      controller: _answerController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'La tua risposta',
      ),
      keyboardType: TextInputType.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Cinese'),
      ),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Errore nel caricamento delle domande: ${snapshot.error}'));
          }

          final questions = snapshot.data!;
          final current = questions[_currentIndex];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Domanda ${_currentIndex + 1} di ${questions.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  current.question,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                _buildAnswerInput(current),
                const SizedBox(height: 16),
                if (_feedbackMessage != null)
                  Text(
                    _feedbackMessage!,
                    style: TextStyle(
                      color: _feedbackMessage!.contains('corretta') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    _submitAnswer(questions);
                  },
                  child: const Text('Controlla risposta'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _nextQuestion(questions);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade900),
                  child: const Text('Prossima domanda'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum QuestionType {
  text,
  multipleChoice,
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

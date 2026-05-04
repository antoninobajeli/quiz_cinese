import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

enum AllQuestionsSortOption {
  id,
  ratio,
  totalAsked,
}

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
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
  late Future<List<Question>> _allQuestionsFuture;
  final _answerController = TextEditingController();
  String? _selectedChoice;
  int _currentIndex = 0;
  String? _feedbackMessage;
  int _correctCount = 0;
  final List<QuizAnswer> _answers = [];
  final Random _random = Random();
  int? _selectedQuestionCount;
  int _currentTabIndex = 0;
  AllQuestionsSortOption _allQuestionsSort = AllQuestionsSortOption.ratio;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _loadQuizQuestions();
    _allQuestionsFuture = _loadAllQuestions();
  }

  Future<List<Question>> _loadAllQuestions() async {
    final jsonString = await rootBundle.loadString('assets/questions.json');
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded.map((item) => Question.fromJson(item)).toList();
  }

  Future<Map<int, QuestionStats>> _loadQuestionStatsMap() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = prefs.getStringList('quiz_sessions') ?? [];
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
              questionId: answer.questionId,
              correctAnswers: answer.isCorrect ? 1 : 0,
              incorrectAnswers: answer.isCorrect ? 0 : 1,
            );
          } else {
            stats[answer.questionId] = QuestionStats(
              questionId: existing.questionId,
              correctAnswers: existing.correctAnswers + (answer.isCorrect ? 1 : 0),
              incorrectAnswers: existing.incorrectAnswers + (answer.isCorrect ? 0 : 1),
            );
          }
        }
      } catch (_) {
        // Ignora sessioni malformate
      }
    }

    return stats;
  }

  Future<List<Question>> _loadQuizQuestions() async {
    final allQuestions = await _loadAllQuestions();
    final questionStats = await _loadQuestionStatsMap();

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

    final questionsToUse = _selectedQuestionCount != null
        ? _selectWeightedRandomQuestions(sortedQuestions, questionStats, _selectedQuestionCount!)
        : sortedQuestions;

    return questionsToUse;
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

    while (selected.length < count && remaining.isNotEmpty) {
      final weights = <double>[];
      for (final question in remaining) {
        final stat = stats[question.id]!;
        final totalAsked = stat.correctAnswers + stat.incorrectAnswers;
        final ratio = totalAsked == 0 ? 0.5 : stat.correctAnswers / totalAsked;

        final priorityWeight = 1.0 - ratio;
        final askWeight = 1.0 / (1 + totalAsked);
        final combinedWeight = priorityWeight * 0.7 + askWeight * 0.3 + 0.01;
        weights.add(combinedWeight);
      }

      final totalWeight = weights.fold(0.0, (sum, w) => sum + w);
      final choice = _random.nextDouble() * totalWeight;
      double cumulative = 0.0;
      int chosenIndex = 0;

      for (var i = 0; i < remaining.length; i++) {
        cumulative += weights[i];
        if (choice <= cumulative) {
          chosenIndex = i;
          break;
        }
      }

      selected.add(remaining.removeAt(chosenIndex));
    }

    return selected;
  }

  void _askForQuestionCount() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Numero di domande'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Inserisci il numero di domande',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final count = int.tryParse(controller.text);
              if (count != null && count > 0) {
                setState(() {
                  _selectedQuestionCount = count;
                  _questionsFuture = _loadQuizQuestions();
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Inizia'),
          ),
        ],
      ),
    );
  }

  void _submitAnswer(List<Question> questions) {
    final current = questions[_currentIndex];
    final answer = current.type == QuestionType.text
        ? _answerController.text.trim()
        : _selectedChoice ?? '';

    final isCorrect = answer.toLowerCase() == current.answer.toLowerCase();
    
    // Salva la risposta
    _answers.add(QuizAnswer(
      questionId: current.id,
      question: current.question,
      userAnswer: answer,
      correctAnswer: current.answer,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
    ));
    
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
    _saveScore();
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

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    final quizSession = {
      'timestamp': DateTime.now().toIso8601String(),
      'correctCount': _correctCount,
      'totalQuestions': _answers.length,
      'answers': _answers.map((a) => a.toJson()).toList(),
    };
    
    final sessions = prefs.getStringList('quiz_sessions') ?? [];
    sessions.add(jsonEncode(quizSession));
    await prefs.setStringList('quiz_sessions', sessions);
  }

  void _restartQuiz() {
    setState(() {
      _selectedQuestionCount = null;
      _questionsFuture = _loadQuizQuestions();
      _currentIndex = 0;
      _correctCount = 0;
      _feedbackMessage = null;
      _answerController.clear();
      _selectedChoice = null;
      _answers.clear();
    });
  }

  Future<QuestionStats> _getQuestionStats(int questionId) async {
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
      questionId: questionId,
      correctAnswers: correct,
      incorrectAnswers: incorrect,
    );
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
    if (_currentTabIndex == 0 && _selectedQuestionCount == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_selectedQuestionCount == null && _currentTabIndex == 0) {
          _askForQuestionCount();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Cinese'),
      ),
      body: _currentTabIndex == 0 ? _buildQuizView() : _buildAllQuestionsView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Statistiche',
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView() {
    return FutureBuilder<List<Question>>(
      future: _questionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Errore nel caricamento delle domande: ${snapshot.error}'));
        }

        final questions = snapshot.data!;
        if (questions.isEmpty) {
          return const Center(child: Text('Nessuna domanda disponibile.'));
        }

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
              const SizedBox(height: 8),
              FutureBuilder<QuestionStats>(
                future: _getQuestionStats(current.id),
                builder: (context, statsSnapshot) {
                  if (statsSnapshot.connectionState == ConnectionState.done && statsSnapshot.hasData) {
                    final stats = statsSnapshot.data!;
                    final total = stats.correctAnswers + stats.incorrectAnswers;
                    if (total > 0) {
                      return Text(
                        '(${stats.correctAnswers} corrette, ${stats.incorrectAnswers} sbagliate)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
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
    );
  }

  Widget _buildAllQuestionsView() {
    return FutureBuilder<List<Question>>(
      future: _allQuestionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Errore nel caricamento delle domande: ${snapshot.error}'));
        }

        final questions = snapshot.data!;
        return FutureBuilder<Map<int, QuestionStats>>(
          future: _loadQuestionStatsMap(),
          builder: (context, statsSnapshot) {
            if (statsSnapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (statsSnapshot.hasError) {
              return Center(child: Text('Errore nel caricamento delle statistiche: ${statsSnapshot.error}'));
            }

            final stats = statsSnapshot.data!;
            final sortedQuestions = List<Question>.from(questions);
            sortedQuestions.sort((a, b) {
              final statsA = stats[a.id] ?? QuestionStats(questionId: a.id, correctAnswers: 0, incorrectAnswers: 0);
              final statsB = stats[b.id] ?? QuestionStats(questionId: b.id, correctAnswers: 0, incorrectAnswers: 0);
              final totalA = statsA.correctAnswers + statsA.incorrectAnswers;
              final totalB = statsB.correctAnswers + statsB.incorrectAnswers;
              final ratioA = totalA == 0 ? 0.0 : statsA.correctAnswers / totalA;
              final ratioB = totalB == 0 ? 0.0 : statsB.correctAnswers / totalB;
              switch (_allQuestionsSort) {
                case AllQuestionsSortOption.id:
                  return a.id.compareTo(b.id);
                case AllQuestionsSortOption.ratio:
                  return ratioA.compareTo(ratioB);
                case AllQuestionsSortOption.totalAsked:
                  return totalB.compareTo(totalA);
              }
            });

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ordina per',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      DropdownButton<AllQuestionsSortOption>(
                        value: _allQuestionsSort,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _allQuestionsSort = value;
                            });
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: AllQuestionsSortOption.id,
                            child: Text('ID'),
                          ),
                          DropdownMenuItem(
                            value: AllQuestionsSortOption.ratio,
                            child: Text('Rapporto'),
                          ),
                          DropdownMenuItem(
                            value: AllQuestionsSortOption.totalAsked,
                            child: Text('N. risposte'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedQuestions.length,
                    itemBuilder: (context, index) {
                      final question = sortedQuestions[index];
                      final questionStat = stats[question.id] ?? QuestionStats(questionId: question.id, correctAnswers: 0, incorrectAnswers: 0);
                      final totalAsked = questionStat.correctAnswers + questionStat.incorrectAnswers;
                      final ratio = totalAsked == 0 ? 0.0 : questionStat.correctAnswers / totalAsked;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Domanda #${question.id}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                question.question,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              if (question.type == QuestionType.multipleChoice) ...[
                                const Text('Scelte:'),
                                const SizedBox(height: 4),
                                ...question.choices!.map((choice) => Text('• $choice')).toList(),
                                const SizedBox(height: 8),
                              ],
                              Text('Risposta corretta: ${question.answer}'),
                              const SizedBox(height: 12),
                              Text('Statistiche:'),
                              const SizedBox(height: 4),
                              Text('• Corrette: ${questionStat.correctAnswers}'),
                              Text('• Sbagliate: ${questionStat.incorrectAnswers}'),
                              Text('• Rapporto: ${ratio.toStringAsFixed(2)}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
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

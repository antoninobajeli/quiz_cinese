import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'screens/quiz_view.dart';
import 'screens/stats_view.dart';
import 'screens/current_quiz_view.dart';

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
          seedColor: const Color(0xFFFF1493),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF1493),
          brightness: Brightness.dark,
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
  bool _quizStarted = false;
  int _currentTabIndex = 0;
  AllQuestionsSortOption _allQuestionsSort = AllQuestionsSortOption.ratio;

  @override
  void initState() {
    super.initState();
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

        final stat = ((stats.length>0) && (stats[question.id]!=null))? stats[question.id]!:QuestionStats(questionId: question.id, correctAnswers: 0, incorrectAnswers: 0);
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
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pronto a iniziare?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('Quante domande vuoi affrontare?'),
              const SizedBox(height: 32),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCountOption(1, 'Riscaldamento'),
                  _buildCountOption(5, 'Veloce'),
                  _buildCountOption(10, 'Standard'),
                  _buildCountOption(20, 'Sfida'),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _askForCustomQuestionCount();
                },
                child: const Text('Inserisci numero personalizzato'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _askForCustomQuestionCount() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Numero personalizzato'),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              final count = int.tryParse(controller.text);
              if (count != null && count > 0) {
                setState(() {
                  _selectedQuestionCount = count;
                  _quizStarted = true;
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

  Widget _buildCountOption(int count, String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedQuestionCount = count;
          _quizStarted = true;
          _questionsFuture = _loadQuizQuestions();
        });
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
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
    final percentage = total > 0 ? (_correctCount / total) : 0.0;
    String message;
    String emoji;

    if (percentage == 1.0) {
      message = 'Incredibile! Sei un vero esperto! 🏆';
      emoji = '🤩';
    } else if (percentage >= 0.7) {
      message = 'Ottimo lavoro! Continua così! 🚀';
      emoji = '👏';
    } else if (percentage >= 0.4) {
      message = 'Niente male, ma puoi migliorare! 💪';
      emoji = '😉';
    } else {
      message = 'Non mollare! La prossima andrà meglio! ✨';
      emoji = '📚';
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji == '📚')
                SvgPicture.asset(
                  'assets/libri_cute.svg',
                  height: 80,
                )
              else
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 64),
                ),
              const SizedBox(height: 16),
              Text(
                'Quiz Completato!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_correctCount',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      ' / $total',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'domande corrette',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _restartQuiz();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ricomincia',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      _quizStarted = false;
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

  Widget _buildQuestionStatsCard(Question question, QuestionStats stats) {
    final totalAsked = stats.correctAnswers + stats.incorrectAnswers;
    final ratio = totalAsked == 0 ? 0.0 : stats.correctAnswers / totalAsked;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: question.answer));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Risposta "${question.answer}" copiata!'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${question.id}',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          question.question,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Risposta: ${question.answer}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildStatBadge(
              label: 'Tot.',
              value: '$totalAsked',
              icon: Icons.history,
              color: Colors.blueGrey,
            ),
            const SizedBox(width: 8),
            _buildStatBadge(
              label: 'Rate',
              value: '${(ratio * 100).toInt()}%',
              icon: Icons.star_rounded,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    )
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.bold),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Cinese'),
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          QuizView(
            quizStarted: _quizStarted,
            questionsFuture: _quizStarted ? _questionsFuture : null,
            currentIndex: _currentIndex,
            feedbackMessage: _feedbackMessage,
            onStartQuiz: _askForQuestionCount,
            onSubmitAnswer: _submitAnswer,
            onNextQuestion: _nextQuestion,
            getQuestionStats: _getQuestionStats,
            buildAnswerInput: _buildAnswerInput,
          ),
          StatsView(
            allQuestionsFuture: _allQuestionsFuture,
            loadQuestionStatsMap: _loadQuestionStatsMap,
            currentSort: _allQuestionsSort,
            onSortChanged: (sort) => setState(() => _allQuestionsSort = sort),
            buildQuestionStatsCard: _buildQuestionStatsCard,
          ),
          CurrentQuizView(
            quizStarted: _quizStarted,
            questionsFuture: _quizStarted ? _questionsFuture : null,
            loadQuestionStatsMap: _loadQuestionStatsMap,
            onStartQuiz: _askForQuestionCount,
            buildQuestionStatsCard: _buildQuestionStatsCard,
          ),
        ],
      ),
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
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted),
            label: 'Quiz attuale',
          ),
        ],
      ),
    );
  }
}

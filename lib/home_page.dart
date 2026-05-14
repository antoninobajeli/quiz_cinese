import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_notifications/easy_notifications.dart';
import 'package:quizcinese/screens/drawing_view.dart';
import 'package:web/web.dart' as web;

import 'components/scratch_reveal.dart';
import 'models.dart';
import 'screens/quiz_view.dart';
import 'screens/stats_view.dart';
import 'screens/scratch_and_guess_view.dart';
import 'screens/sessions_history_view.dart';
import 'services/general_controller.dart';

class QuizHomePage extends StatefulWidget {
  const QuizHomePage({super.key});

  @override
  State<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage> {
  late GeneralController _controller;
  final _answerController = TextEditingController();
  final _scratchController= ScratchController();
  String? _selectedChoice;
  int? _selectedQuestionCount;
  int _currentTabIndex = 0;
  AllQuestionsSortOption _allQuestionsSort = AllQuestionsSortOption.ratio;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _reminderController = TextEditingController();
  int? _reminderValue;
  late ConfettiController _confettiController;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _controller = GeneralController();
    _controller.addListener(_onControllerChanged);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _audioPlayer = AudioPlayer();
    requestNotificationPermission();


  }

  void requestNotificationPermission() async {
    final notification = web.Notification;

    if (web.Notification.permission == 'default') {
      final permission = await web.Notification
          .requestPermission()
          .toDart;
      if (permission == 'granted') {
        print('Notification permission approved.');
      }
    }
    await EasyNotifications.scheduleMessage(
      title: 'Reminder',
      body: 'Time for your meeting!',
      scheduledDate: DateTime.now().add(Duration(seconds: 10)),
    );
    print('quiz homepage message scheduleMessage');
  }


  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    _answerController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  Future<Map<int, QuestionStats>> _loadQuestionStatsMap() async {
    return _controller.loadStats();
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
                  _controller.startQuiz(count);
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
          _controller.startQuiz(count);
        });
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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

  void _showReminderValueDialog(int value) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder impostato'),
        content: Text('Hai impostato il valore: $value'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsDrawer() {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Impostazioni',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Reminder',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reminderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valore numerico',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final value = int.tryParse(_reminderController.text);
                  if (value != null) {
                    setState(() {
                      _reminderValue = value;
                    });
                    _showReminderValueDialog(value);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inserisci un numero valido')),
                    );
                  }
                },
                child: const Text('Imposta Reminder'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Azione nulla',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  globalContext.callMethod("registerPeriodicSync" as JSAny);
                },
                child: const Text('text'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitQuizAnswer(List<Question> questions) {
    final current = questions[_controller.quizSession.currentIndex];
    final answer = current.type == QuestionType.text
        ? _answerController.text.trim()
        : _selectedChoice ?? '';

    _controller.submitQuizAnswer(answer);

    setState(() {
      if (_controller.quizSession.feedbackMessage!.contains('corretta')) {
        _confettiController.play();
        _audioPlayer.play(AssetSource('success.mp3'));
      }
    });
  }

  // Drawing Mode Logic
  void _askForScratchQuestionCount() {
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
                'Pronto a Giocare a Scratch?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('Quante sfide vuoi affrontare?'),
              const SizedBox(height: 32),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildScratchCountOption(5, 'Sprint'),
                  _buildScratchCountOption(10, 'Maratona'),
                  _buildScratchCountOption(20, 'Elite'),
                  _buildScratchCountOption(50, 'Leggenda'),
                ],
              ),
              const SizedBox(height: 24),
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

  Widget _buildScratchCountOption(int count, String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _controller.startScratch(count);
        });
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .tertiaryContainer
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
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
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drawing Mode Logic
  void _askForDrawingQuestionCount() {
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
                'Pronto a Giocare?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('Quante sfide vuoi affrontare?'),
              const SizedBox(height: 32),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildDrawingCountOption(5, 'Sprint'),
                  _buildDrawingCountOption(10, 'Maratona'),
                  _buildDrawingCountOption(20, 'Elite'),
                  _buildDrawingCountOption(50, 'Leggenda'),
                ],
              ),
              const SizedBox(height: 24),
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

  Widget _buildDrawingCountOption(int count, String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _controller.startDrawing(count);
        });
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .tertiaryContainer
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
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
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitDrawingAnswer(List<Question> questions, String selectedChar) {
    final current = questions[_controller.quizSession.currentIndex];
    final answer = current.type == QuestionType.text
        ? _answerController.text.trim()
        : _selectedChoice ?? '';

    _controller.submitDrawingAnswer(selectedChar);

    setState(() {
      if (_controller.drawingSession.feedbackMessage!.contains('Ottimo')) {
        _confettiController.play();
        _audioPlayer.play(AssetSource('success.mp3'));
      }
    });
  }

  void _submitScratchAndGuesAnswer(
      List<Question> questions, String selectedChar) {
    final current = questions[_controller.quizSession.currentIndex];
    final answer = current.type == QuestionType.text
        ? _answerController.text.trim()
        : _selectedChoice ?? '';

    _controller.submitScratchAnswer(selectedChar);

    setState(() {
      if (_controller.scratchSession.feedbackMessage!.contains('Ottimo')) {
        _confettiController.play();
        _audioPlayer.play(AssetSource('success.mp3'));
      }
    });
  }

  void _nextQuestion(List<Question> questions) {
    _controller.nextQuizQuestion();
    if (_controller.quizSession.isCompleted) {
      _showQuizScoreDialog(questions.length);
    } else {
      setState(() {
        _answerController.clear();
        _selectedChoice = null;
      });
    }
  }

  void _nextDrawingQuestion(List<Question> questions) {
    _controller.nextDrawingQuestion();
    if (_controller.drawingSession.isCompleted) {
      _showDrawingScoreDialog(questions.length);
    }
  }

  void _nextScratchQuestion(List<Question> questions) {
    _controller.nextScratchQuestion();
    _scratchController.reset();
    if (_controller.scratchSession.isCompleted) {
      _showScratchScoreDialog(questions.length);
    }
  }

  void _showQuizScoreDialog(int total) {
    final percentage =
        total > 0 ? (_controller.quizSession.correctCount / total) : 0.0;
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
                Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.1),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_controller.quizSession.correctCount}',
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
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
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

  void _showDrawingScoreDialog(int total) {
    // Salvataggio opzionale per statistiche separate se necessario
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎮', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Sfida Completata!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hai completato $total sfide di caratteri!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _restartDrawing();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Ricomincia',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScratchScoreDialog(int total) {
    final percentage =
        total > 0 ? (_controller.scratchSession.correctCount / total) : 0.0;
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
                Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.1),
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
                'Scratch & Guess Completato!',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_controller.scratchSession.correctCount}',
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
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
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
                    _restartScratch();
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

  void _endQuiz() {
    _controller.endQuiz();
    _showQuizScoreDialog(_controller.quizSession.currentIndex + 1);
  }

  void _endDrawing() {
    _controller.endDrawing();
    _showDrawingScoreDialog(_controller.drawingSession.currentIndex + 1);
  }

  void _endScratch() {
    _controller.endScratch();
    _showScratchScoreDialog(_controller.scratchSession.currentIndex + 1);
  }

  void _restartQuiz() {
    setState(() {
      _selectedQuestionCount = null;
      _controller.restartQuiz();
      _answerController.clear();
      _selectedChoice = null;
    });
  }

  void _restartDrawing() {
    setState(() {
      _controller.restartDrawing();
    });
  }

  void _restartScratch() {
    setState(() {
      _selectedQuestionCount = null;
      _controller.restartScratch();
      _answerController.clear();
      _selectedChoice = null;
    });
  }

  Future<QuestionStats> _getQuestionStats(int questionId) async {
    return _controller.getQuestionStats(questionId);
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
          side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      (question.answerpinyin != null &&
                              question.answerpinyin!.isNotEmpty)
                          ? Text(
                              '${question.answer} ${question.answerpinyin}',
                              style: TextStyle(
                                fontSize: 26,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Text(
                              'R: ${question.answer}',
                              style: TextStyle(
                                fontSize: 26,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                      if (question.answerpinyin != null ||
                          question.answerclassgr != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            /*if (question.answerpinyin != null && question.answerpinyin!.isNotEmpty)
                          _buildSmallTag(
                            text: question.answerpinyin!,
                            color: colorScheme.secondary,
                            icon: Icons.record_voice_over_outlined,
                          ),
                        if (question.answerpinyin != null &&
                            question.answerpinyin!.isNotEmpty &&
                            question.answerclassgr != null &&
                            question.answerclassgr!.isNotEmpty)
                          const SizedBox(width: 8),*/
                            if (question.answerclassgr != null &&
                                question.answerclassgr!.isNotEmpty)
                              _buildSmallTag(
                                text: question.answerclassgr!,
                                color: colorScheme.tertiary,
                                icon: Icons.label_outline_rounded,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(children: [
                  _buildStatBadge(
                    label: 'Tot.',
                    value: '$totalAsked',
                    icon: Icons.history,
                    color: Colors.blueGrey,
                  ),
                  _buildStatBadge(
                    label: 'Rate',
                    value: '${(ratio * 100).toInt()}%',
                    icon: Icons.star_rounded,
                    color: Colors.orange,
                  ),
                ])
              ],
            ),
          ),
        ));
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
        color: color.withValues(alpha: 0.1),
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
              /*Text(
                label,
                style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
              ),*/
              Text(
                value,
                style: TextStyle(
                    fontSize: 14, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTag({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Cinese HSK-1'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _buildSettingsDrawer(),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentTabIndex,
            children: [
              const SessionsHistoryView(),
              QuizView(
                quizStarted: _controller.quizSession.isStarted,
                questionsFuture: _controller.quizQuestionsFuture,
                currentIndex: _controller.quizSession.currentIndex,
                feedbackMessage: _controller.quizSession.feedbackMessage,
                onStartQuiz: _askForQuestionCount,
                onSubmitAnswer: _submitQuizAnswer,
                onNextQuestion: _nextQuestion,
                onEndGame: _endQuiz,
                getQuestionStats: _getQuestionStats,
                buildAnswerInput: _buildAnswerInput,
                loadQuestionStatsMap: _loadQuestionStatsMap,
                buildQuestionStatsCard: _buildQuestionStatsCard,
              ),
              DrawingView(
                drawingStarted: _controller.drawingSession.isStarted,
                questionsFuture: _controller.drawingQuestionsFuture,
                currentIndex: _controller.drawingSession.currentIndex,
                feedbackMessage: _controller.drawingSession.feedbackMessage,
                onStartDrawing: _askForDrawingQuestionCount,
                onSubmitAnswer: _submitDrawingAnswer,
                onNextQuestion: _nextDrawingQuestion,
                onEndGame: _endDrawing,
              ),
              StractchAndGuess(
                  quizStarted: _controller.scratchSession.isStarted,
                  questionsFuture: _controller.scratchQuestionsFuture,
                  currentIndex: _controller.scratchSession.currentIndex,
                  feedbackMessage: _controller.scratchSession.feedbackMessage,
                  onStartQuiz: _askForScratchQuestionCount,
                  onSubmitAnswer: _submitScratchAndGuesAnswer,
                  onNextQuestion: _nextScratchQuestion,
                  onEndGame: _endScratch,
                  getQuestionStats: _getQuestionStats,
                  buildAnswerInput: _buildAnswerInput,
                  loadQuestionStatsMap: _loadQuestionStatsMap,
                  buildQuestionStatsCard: _buildQuestionStatsCard,
                  scratchController: _scratchController),
              StatsView(
                allQuestionsFuture: _controller.allQuestionsFuture,
                loadQuestionStatsMap: _loadQuestionStatsMap,
                currentSort: _allQuestionsSort,
                onSortChanged: (sort) =>
                    setState(() => _allQuestionsSort = sort),
                buildQuestionStatsCard: _buildQuestionStatsCard,
              ),

            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
              createParticlePath: (size) {
                final path = Path();
                path.addOval(Rect.fromCircle(
                    center: Offset.zero, radius: size.width / 2));
                return path;
              },
            ),
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
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.draw),
            label: 'Drawing',
          ),
          NavigationDestination(
            icon: Icon(Icons.memory),
            label: 'S & G',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Vocaboli',
          ),

        ],
      ),
    );
  }
}

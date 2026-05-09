import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';import 'package:package_info_plus/package_info_plus.dart';import '../models.dart';

class QuizView extends StatefulWidget {
  final bool quizStarted;
  final Future<List<Question>>? questionsFuture;
  final int currentIndex;
  final String? feedbackMessage;
  final VoidCallback onStartQuiz;
  final Function(List<Question>) onSubmitAnswer;
  final Function(List<Question>) onNextQuestion;
  final VoidCallback onEndGame;
  final Future<QuestionStats> Function(int) getQuestionStats;
  final Widget Function(Question) buildAnswerInput;
  final Future<Map<int, QuestionStats>> Function() loadQuestionStatsMap;
  final Widget Function(Question, QuestionStats) buildQuestionStatsCard;

  const QuizView({
    super.key,
    required this.quizStarted,
    required this.questionsFuture,
    required this.currentIndex,
    required this.feedbackMessage,
    required this.onStartQuiz,
    required this.onSubmitAnswer,
    required this.onNextQuestion,
    required this.onEndGame,
    required this.getQuestionStats,
    required this.buildAnswerInput,
    required this.loadQuestionStatsMap,
    required this.buildQuestionStatsCard,
  });

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  bool _isDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    if (widget.questionsFuture == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final logoHeight = constraints.maxHeight / 3;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'logo',
                    child: SvgPicture.asset(
                      'assets/logo.svg',
                      height: logoHeight,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Sei pronto alla sfida?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Metti alla prova il tuo cinese e scala la classifica! 🚀',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: widget.onStartQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'INIZIA ORA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      String version = 'v0.0.0';
                      if (snapshot.hasData && snapshot.data != null) {
                        version = 'v${snapshot.data!.version}';
                      }
                      return Text(
                        version,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Stack(
      children: [
        // Contenuto principale
        Scaffold(
          appBar: AppBar(
            title: Text('Domanda ${widget.currentIndex + 1}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  setState(() {
                    _isDrawerOpen = true;
                  });
                },
                tooltip: 'Visualizza quiz attuale',
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          body: FutureBuilder<List<Question>>(
            future: widget.questionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(child: Text('Errore nel caricamento delle domande.'));
              }

              final questions = snapshot.data!;
              final current = questions[widget.currentIndex];

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      current.question,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<QuestionStats>(
                      future: widget.getQuestionStats(current.id),
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
                    widget.buildAnswerInput(current),
                    const SizedBox(height: 16),
                    if (widget.feedbackMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.feedbackMessage!.contains('corretta')
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.feedbackMessage!.contains('corretta') ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  widget.feedbackMessage!.contains('corretta') ? Icons.check_circle : Icons.error,
                                  color: widget.feedbackMessage!.contains('corretta') ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.feedbackMessage!.contains('corretta')
                                        ? widget.feedbackMessage!
                                        : 'Risposta errata.',
                                    style: TextStyle(
                                      color: widget.feedbackMessage!.contains('corretta') ? Colors.green.shade700 : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.feedbackMessage!.contains('Risposta errata'))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Center(
                                  child: Text(
                                    widget.feedbackMessage!.split(':').last.trim(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    if (widget.feedbackMessage == null)
                      ElevatedButton(
                        onPressed: () => widget.onSubmitAnswer(questions),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('CONTROLLA', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => widget.onNextQuestion(questions),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          widget.currentIndex + 1 < questions.length ? 'PROSSIMA DOMANDA' : 'VEDI RISULTATO',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: widget.onEndGame,
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: const Text(
                        'FINE PARTITA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Overlay scuro quando il pannello è aperto
        if (_isDrawerOpen)
          GestureDetector(
            onTap: () {
              setState(() {
                _isDrawerOpen = false;
              });
            },
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

        // Pannello laterale
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: _isDrawerOpen ? 0 : -MediaQuery.of(context).size.width * 0.8,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.8,
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Header del pannello
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Quiz Attuale',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _isDrawerOpen = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Lista delle domande
                Expanded(
                  child: FutureBuilder<List<Question>>(
                    future: widget.questionsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Center(child: Text('Errore nel caricamento delle domande.'));
                      }

                      final questions = snapshot.data!;
                      return FutureBuilder<Map<int, QuestionStats>>(
                        future: widget.loadQuestionStatsMap(),
                        builder: (context, statsSnapshot) {
                          if (statsSnapshot.connectionState != ConnectionState.done) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (statsSnapshot.hasError) {
                            return const Center(child: Text('Errore nel caricamento delle statistiche.'));
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: questions.length,
                            itemBuilder: (context, index) {
                              final question = questions[index];
                              final isCurrentQuestion = index == widget.currentIndex;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: isCurrentQuestion
                                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                    : null,
                                child:
                                InkWell(
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
                                  child:
                                  Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Domanda ${index + 1}',
                                            style: TextStyle(
                                              fontWeight: isCurrentQuestion ? FontWeight.bold : FontWeight.normal,
                                              color: isCurrentQuestion
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          if (isCurrentQuestion) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.play_arrow,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        question.question+"  "+question.answer,
                                        style: TextStyle(
                                          fontSize: 26,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                )),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
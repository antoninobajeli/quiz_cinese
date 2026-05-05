import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models.dart';

class QuizView extends StatelessWidget {
  final bool quizStarted;
  final Future<List<Question>>? questionsFuture;
  final int currentIndex;
  final String? feedbackMessage;
  final VoidCallback onStartQuiz;
  final Function(List<Question>) onSubmitAnswer;
  final Function(List<Question>) onNextQuestion;
  final Future<QuestionStats> Function(int) getQuestionStats;
  final Widget Function(Question) buildAnswerInput;

  const QuizView({
    super.key,
    required this.quizStarted,
    required this.questionsFuture,
    required this.currentIndex,
    required this.feedbackMessage,
    required this.onStartQuiz,
    required this.onSubmitAnswer,
    required this.onNextQuestion,
    required this.getQuestionStats,
    required this.buildAnswerInput,
  });

  @override
  Widget build(BuildContext context) {
    if (!quizStarted) {
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
                      onPressed: onStartQuiz,
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
                ],
              ),
            ),
          );
        },
      );
    }

    return FutureBuilder<List<Question>>(
      future: questionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Ops! Qualcosa è andato storto 😅',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        }

        final questions = snapshot.data!;
        if (questions.isEmpty) {
          return const Center(child: Text('Nessuna domanda disponibile.'));
        }

        final current = questions[currentIndex];
        final progress = (currentIndex + 1) / questions.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Domanda ${currentIndex + 1} di ${questions.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        current.question,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<QuestionStats>(
                        future: getQuestionStats(current.id),
                        builder: (context, statsSnapshot) {
                          if (statsSnapshot.connectionState == ConnectionState.done && statsSnapshot.hasData) {
                            final stats = statsSnapshot.data!;
                            final total = stats.correctAnswers + stats.incorrectAnswers;
                            if (total > 0) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '🔥 $total risposte totali',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              buildAnswerInput(current),
              const SizedBox(height: 24),
              if (feedbackMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: feedbackMessage!.contains('corretta')
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: feedbackMessage!.contains('corretta') ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        feedbackMessage!.contains('corretta') ? Icons.check_circle : Icons.error,
                        color: feedbackMessage!.contains('corretta') ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: feedbackMessage!.split(':').first + (feedbackMessage!.contains(':') ? ':' : ''),
                              ),
                              if (feedbackMessage!.contains(':'))
                                TextSpan(
                                  text: feedbackMessage!.split(':').last,
                                  style: const TextStyle(color: Colors.white),
                                ),
                            ],
                          ),
                          style: TextStyle(
                            color: feedbackMessage!.contains('corretta') ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              if (feedbackMessage == null)
                ElevatedButton(
                  onPressed: () => onSubmitAnswer(questions),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('CONTROLLA', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else
                ElevatedButton(
                  onPressed: () => onNextQuestion(questions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    currentIndex + 1 < questions.length ? 'PROSSIMA DOMANDA' : 'VEDI RISULTATO',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

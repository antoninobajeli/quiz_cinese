import 'package:flutter/material.dart';
import '../models.dart';

class CurrentQuizView extends StatelessWidget {
  final bool quizStarted;
  final Future<List<Question>>? questionsFuture;
  final Future<Map<int, QuestionStats>> Function() loadQuestionStatsMap;
  final VoidCallback onStartQuiz;
  final Widget Function(Question, QuestionStats) buildQuestionStatsCard;

  const CurrentQuizView({
    super.key,
    required this.quizStarted,
    required this.questionsFuture,
    required this.loadQuestionStatsMap,
    required this.onStartQuiz,
    required this.buildQuestionStatsCard,
  });

  @override
  Widget build(BuildContext context) {
    if (!quizStarted) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Avvia il quiz per vedere le domande selezionate per questa sessione.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onStartQuiz,
              child: const Text('Avvia quiz'),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Question>>(
      future: questionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Errore nel caricamento delle domande: ${snapshot.error}'));
        }

        final questions = snapshot.data!;
        if (questions.isEmpty) {
          return const Center(child: Text('Nessuna domanda nel quiz attuale.'));
        }

        return FutureBuilder<Map<int, QuestionStats>>(
          future: loadQuestionStatsMap(),
          builder: (context, statsSnapshot) {
            if (statsSnapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (statsSnapshot.hasError) {
              return Center(child: Text('Errore nel caricamento delle statistiche: ${statsSnapshot.error}'));
            }

            final stats = statsSnapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                final questionStat = stats[question.id] ?? QuestionStats(lastUpdate: DateTime.now(),questionId: question.id, correctAnswers: 0, incorrectAnswers: 0);
                return buildQuestionStatsCard(question, questionStat);
              },
            );
          },
        );
      },
    );
  }
}

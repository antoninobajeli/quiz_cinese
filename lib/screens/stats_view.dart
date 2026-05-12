import 'package:flutter/material.dart';
import '../models.dart';

class StatsView extends StatelessWidget {
  final Future<List<Question>> allQuestionsFuture;
  final Future<Map<int, QuestionStats>> Function() loadQuestionStatsMap;
  final AllQuestionsSortOption currentSort;
  final Function(AllQuestionsSortOption) onSortChanged;
  final Widget Function(Question, QuestionStats) buildQuestionStatsCard;

  const StatsView({
    super.key,
    required this.allQuestionsFuture,
    required this.loadQuestionStatsMap,
    required this.currentSort,
    required this.onSortChanged,
    required this.buildQuestionStatsCard,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Question>>(
      future: allQuestionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Errore nel caricamento delle domande: ${snapshot.error}'));
        }

        final questions = snapshot.data!;
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
            final sortedQuestions = List<Question>.from(questions);
            sortedQuestions.sort((a, b) {
              final statsA = stats[a.id] ?? QuestionStats(questionId: a.id, correctAnswers: 0, incorrectAnswers: 0);
              final statsB = stats[b.id] ?? QuestionStats(questionId: b.id, correctAnswers: 0, incorrectAnswers: 0);
              final totalA = statsA.correctAnswers + statsA.incorrectAnswers;
              final totalB = statsB.correctAnswers + statsB.incorrectAnswers;
              final ratioA = totalA == 0 ? 0.0 : statsA.correctAnswers / totalA;
              final ratioB = totalB == 0 ? 0.0 : statsB.correctAnswers / totalB;
              switch (currentSort) {
                case AllQuestionsSortOption.id:
                  return a.id.compareTo(b.id);
                case AllQuestionsSortOption.question_az:
                  return a.question.toLowerCase().compareTo(b.question.toLowerCase());
                case AllQuestionsSortOption.question_za:
                  return b.question.toLowerCase().compareTo(a.question.toLowerCase());
                case AllQuestionsSortOption.pinyin_az:
                  return a.answerpinyin!.toLowerCase().compareTo(b.answerpinyin!.toLowerCase());
                case AllQuestionsSortOption.pinyin_za:
                  return b.answerpinyin!.toLowerCase().compareTo(a.answerpinyin!.toLowerCase());
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
                        value: currentSort,
                        onChanged: (value) {
                          if (value != null) {
                            onSortChanged(value);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: AllQuestionsSortOption.id,
                            child: Text('ID'),
                          ),
                          DropdownMenuItem(
                            value: AllQuestionsSortOption.question_az,
                            child: Text('Italiano A-Z'),
                          ),
                          DropdownMenuItem(
                            value: AllQuestionsSortOption.question_za,
                            child: Text('Italiano Z-A'),
                          ),
                          DropdownMenuItem(
                            value: AllQuestionsSortOption.pinyin_az,
                            child: Text('Piniyn A-Z'),
                          ),
                          DropdownMenuItem(
                            value: AllQuestionsSortOption.pinyin_az,
                            child: Text('Piniyn Z-A'),
                          ),
                          DropdownMenuItem(
                            value: AllQuestionsSortOption.ratio,
                            child: Text('Apprendimmento'),
                          ),
                          DropdownMenuItem(
                            value: AllQuestionsSortOption.totalAsked,
                            child: Text('N. esercitazioni'),
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
                      return buildQuestionStatsCard(question, questionStat);
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

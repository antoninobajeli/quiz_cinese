import 'package:flutter/material.dart';
import '../models.dart';
import '../services/stats_service.dart';

class SessionsHistoryView extends StatefulWidget {
  const SessionsHistoryView({super.key});

  @override
  State<SessionsHistoryView> createState() => _SessionsHistoryViewState();
}

class _SessionsHistoryViewState extends State<SessionsHistoryView>
    with TickerProviderStateMixin {
  late StatsService _statsService;
  late List<AnimationController> _animationControllers;

  @override
  void initState() {
    super.initState();
    _statsService = StatsService();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<QuizSessionSummary>>(
        future: _statsService.loadAllSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Errore: ${snapshot.error}'),
            );
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuna sessione salvata',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa il tuo primo quiz per iniziare!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          _animationControllers = List.generate(
            sessions.length + 1,
            (index) => AnimationController(
              duration: Duration(milliseconds: 600 + (index * 100)),
              vsync: this,
            ),
          );

          for (var controller in _animationControllers) {
            controller.forward();
          }

          // Calcola statistiche aggregate
          int totalQuestions = 0;
          int totalCorrect = 0;
          for (final session in sessions) {
            totalQuestions += session.totalQuestions;
            totalCorrect += session.correctCount;
          }
          final overallPercentage =
              totalQuestions > 0 ? (totalCorrect / totalQuestions) : 0.0;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sessions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildStatsHeader(
                  context,
                  sessions.length,
                  totalQuestions,
                  totalCorrect,
                  overallPercentage,
                );
              }
              return _buildSessionCard(context, sessions[index - 1], index - 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(
    BuildContext context,
    int sessionCount,
    int totalQuestions,
    int totalCorrect,
    double overallPercentage,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationControllers[0],
          curve: Curves.elasticOut,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le tue Statistiche',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.assignment,
                  label: 'Sessioni',
                  value: sessionCount.toString(),
                ),
                _buildStatItem(
                  icon: Icons.help,
                  label: 'Domande',
                  value: totalQuestions.toString(),
                ),
                _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Corrette',
                  value: '${(overallPercentage * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      {required IconData icon,
      required String label,
      required String value}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    QuizSessionSummary session,
    int index,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationControllers[index],
          curve: Curves.easeOutCubic,
        ),
      ),
      child: FadeTransition(
        opacity: _animationControllers[index],
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getGradientColors(context, session.percentage),
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _getPrimaryColor(session.percentage)
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showSessionDetails(context, session),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header con data e emoticon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.formattedDate,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.white70,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${session.totalQuestions} domande',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDarkMode
                                          ? Colors.white60
                                          : Colors.white60,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          session.emoticon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar e statistiche
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Risposte corrette',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.white70,
                                        ),
                                  ),
                                  Text(
                                    '${session.correctCount}/${session.totalQuestions}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: session.percentage,
                                  minHeight: 6,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDarkMode
                                        ? Colors.white
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            session.formattedPercentage,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.white,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(BuildContext context, double percentage) {
    if (percentage == 1.0) {
      return [
        const Color(0xFF4CAF50),
        const Color(0xFF45a049),
      ];
    } else if (percentage >= 0.8) {
      return [
        const Color(0xFF2196F3),
        const Color(0xFF1976D2),
      ];
    } else if (percentage >= 0.6) {
      return [
        const Color(0xFF9C27B0),
        const Color(0xFF7B1FA2),
      ];
    } else if (percentage >= 0.4) {
      return [
        const Color(0xFFFF9800),
        const Color(0xFFF57C00),
      ];
    } else {
      return [
        const Color(0xFFf44336),
        const Color(0xFFd32f2f),
      ];
    }
  }

  Color _getPrimaryColor(double percentage) {
    if (percentage == 1.0) {
      return const Color(0xFF4CAF50);
    } else if (percentage >= 0.8) {
      return const Color(0xFF2196F3);
    } else if (percentage >= 0.6) {
      return const Color(0xFF9C27B0);
    } else if (percentage >= 0.4) {
      return const Color(0xFFFF9800);
    } else {
      return const Color(0xFFf44336);
    }
  }

  void _showSessionDetails(BuildContext context, QuizSessionSummary session) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dettagli Sessione',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      session.emoticon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  'Data:',
                  session.formattedDate,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Risultato:',
                  '${session.correctCount}/${session.totalQuestions} (${session.formattedPercentage})',
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: session.percentage,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getPrimaryColor(session.percentage),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Analisi delle risposte:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ..._buildAnswersList(context, session),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Chiudi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  List<Widget> _buildAnswersList(BuildContext context, QuizSessionSummary session) {
    final widgets = <Widget>[];
    for (int i = 0; i < session.answers.length; i++) {
      final answer = session.answers[i];
      widgets.add(
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: answer.isCorrect
                ? Colors.green.shade50
                : Colors.red.shade50,
            border: Border(
              left: BorderSide(
                color: answer.isCorrect
                    ? Colors.green
                    : Colors.red,
                width: 4,
              ),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Domanda ${i + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: answer.isCorrect ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                answer.question,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Risposta: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    TextSpan(
                      text: answer.userAnswer,
                      style: TextStyle(
                        fontSize: 11,
                        color: answer.isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              if (!answer.isCorrect) ...[
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Corretta: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      TextSpan(
                        text: answer.correctAnswer,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return widgets;
  }
}

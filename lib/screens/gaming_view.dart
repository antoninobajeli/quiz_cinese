import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models.dart';
import 'dart:math';

class GamingView extends StatefulWidget {
  final bool gamingStarted;
  final Future<List<Question>>? questionsFuture;
  final int currentIndex;
  final String? feedbackMessage;
  final VoidCallback onStartGaming;
  final Function(List<Question>, String selectedChar) onSubmitAnswer;
  final Function(List<Question>) onNextQuestion;
  final VoidCallback onEndGame;

  const GamingView({
    super.key,
    required this.gamingStarted,
    required this.questionsFuture,
    required this.currentIndex,
    required this.feedbackMessage,
    required this.onStartGaming,
    required this.onSubmitAnswer,
    required this.onNextQuestion,
    required this.onEndGame,
  });

  @override
  State<GamingView> createState() => _GamingViewState();
}

class _GamingViewState extends State<GamingView> {
  final _controller = TextEditingController();
  String? _targetChar;
  final _random = Random();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pickTargetChar(String answer) {
    if (answer.isEmpty) return;
    // Filtra per evitare spazi o punteggiatura se necessario, ma qui prendiamo un carattere a caso
    setState(() {
      _targetChar = answer[_random.nextInt(answer.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.gamingStarted) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final logoHeight = constraints.maxHeight / 3;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/logo.svg',
                    height: logoHeight,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Modalità Gaming 🎮',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Focus su un singolo carattere alla volta. Più veloce, più intenso!',
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
                      onPressed: widget.onStartGaming,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                        foregroundColor: Theme.of(context).colorScheme.onTertiary,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'GIOCA ORA',
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
        
        // Se non abbiamo ancora scelto il carattere per questa domanda, lo facciamo
        if (_targetChar == null || !current.answer.contains(_targetChar!)) {
           _targetChar = current.answer[_random.nextInt(current.answer.length)];
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final charDisplayHeight = constraints.maxHeight / 3;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Domanda ${widget.currentIndex + 1} di ${questions.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    current.question,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Carattere gigante
                  Container(
                    height: charDisplayHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      _targetChar!,
                      style: TextStyle(
                        fontSize: charDisplayHeight * 0.7,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      hintText: 'Inserisci il carattere',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onChanged: (val) {
                      if (val.trim() == _targetChar) {
                        widget.onSubmitAnswer(questions, _targetChar!);
                        _controller.clear();
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  if (widget.feedbackMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.feedbackMessage!.contains('corretta')
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.feedbackMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.feedbackMessage!.contains('corretta') ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  if (widget.feedbackMessage != null)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _targetChar = null;
                        });
                        widget.onNextQuestion(questions);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        widget.currentIndex + 1 < questions.length ? 'PROSSIMA' : 'VEDI RISULTATO',
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
        );
      },
    );
  }
}

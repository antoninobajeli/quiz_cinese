import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models.dart';

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
  bool _isDrawerOpen = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questionsFuture == null) {
      return Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final logoHeight = constraints.maxHeight / 3;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
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
        ),
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
                    tooltip: 'Visualizza gaming attuale',
                  ),
                ],
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              body: LayoutBuilder(
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
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
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
                  color: Colors.black.withValues(alpha: 0.5),
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
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Gaming Attuale',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onTertiaryContainer,
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
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          final isCurrentQuestion = index == widget.currentIndex;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isCurrentQuestion
                                ? Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3)
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
                                              ? Theme.of(context).colorScheme.tertiary
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      if (isCurrentQuestion) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.play_arrow,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.tertiary,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${question.question}  ${question.answer}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            )),
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
      },
    );
  }
}

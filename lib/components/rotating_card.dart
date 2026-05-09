import 'dart:math';
import 'package:flutter/material.dart';

class RotatingCard extends StatefulWidget {
  const RotatingCard({super.key});

  @override
  State<RotatingCard> createState() => _RotatingCardState();
}

class _RotatingCardState extends State<RotatingCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 3 giri al secondo per 3 giri totali = 1 secondo di durata
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Avvia l'animazione al caricamento
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () {
            _controller.reset();
            _controller.forward();
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Calcolo della rotazione:
              // _controller.value va da 0 a 1.
              // Per fare 3 giri completi moltiplichiamo per 3 * 2π
              double rotationValue = _controller.value * 3 * 2 * pi;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002) // Effetto prospettiva (profondità)
                  ..rotateY(rotationValue), // Rotazione sull'asse Y (come una carta)
                child: child,
              );
            },
            child: const CardWidget(),
          ),
        ),
      ),
    );
  }
}

// Un semplice widget che rappresenta la faccia della carta
class CardWidget extends StatelessWidget {
  const CardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: const Center(
        child: Text(
          '🂠',
          style: TextStyle(fontSize: 80, color: Colors.white),
        ),
      ),
    );
  }
}
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizcinese/components/rotating_card.dart';
import 'package:web_haptics/web_haptics.dart';

class ScratchRevealWidget extends StatefulWidget {
  final String revealText;

  const ScratchRevealWidget({
    super.key,
    this.revealText = 'Sfondo Rivelato!',
  });

  @override
  State<ScratchRevealWidget> createState() => _ScratchRevealWidgetState();
}


class _ScratchRevealWidgetState extends State<ScratchRevealWidget> {
  // Lista che memorizza le coordinate tracciate dal dito.
  // Un valore null indica che l'utente ha sollevato il dito (fine del tratto).
  List<Offset?> points = [];
  final haptics = WebHaptics();

  // Dentro il tuo State...
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage('assets/scratiching_surface.png');
  }

  Future<void> _loadImage(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
    });
  }

  @override
  Widget build(BuildContext context) {


    return

      //RotatingCard(),
      Stack(
      alignment: Alignment.center,
      children: [
        // 1. IL BACKGROUND DA RIVELARE
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(20),
            /*image: const DecorationImage(
              image: NetworkImage('https://picsum.photos/300/300'), // Immagine di test
              fit: BoxFit.cover,
            ),*/
          ),
          child: Center(
            child: Text(
              widget.revealText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 80,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
        ),

        // 2. IL LIVELLO OPACO SOVRAPPOSTO (DA GRATTARE)
        GestureDetector(
          onPanStart: (details) {
            setState(() {
              points.add(details.localPosition);
            });
          },
          onPanUpdate: (details) {
            setState(() {
              points.add(details.localPosition);
              haptics.trigger([
                Vibration(duration: 50, intensity: 0.8),
                Vibration(delay: 30, duration: 80, intensity: 0.4),
              ]);
            });
          },
          onPanEnd: (details) {
            setState(() {
              points.add(null); // Segna la fine di un tratto continuo
            });
          },
          child: CustomPaint(
            size: const Size(200, 200),
            painter: ScratchPainter(points: points,image: _image),
          ),
        ),
      ],
    );
  }
}

class ScratchPainter extends CustomPainter {
  final List<Offset?> points;
  final ui.Image? image; // L'immagine caricata



  ScratchPainter({required this.points,required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // CRITICO: Creiamo un layer separato. Questo impedisce a BlendMode.clear
    // di "bucare" l'intera app, limitando l'effetto solo a questo CustomPaint.
    canvas.saveLayer(rect, Paint());

    final rRect=RRect.fromRectAndRadius(
      rect,
      const Radius.circular(20),
    );

    canvas.clipRRect(rRect);
    if (image != null) {
      // Disegniamo l'immagine adattandola alle dimensioni del widget (BoxFit.fill)
      paintImage(
        canvas: canvas,
        rect: rect,
        image: image!,
        fit: BoxFit.cover
        // Usiamo un clip per mantenere i bordi arrotondati del box
        //canvasAlpha: 242 // Opacità ~0.95
      );
    } else {
      // Fallback se l'immagine non è pronta
      final backgroundPaint = Paint()..color = Colors.white.withValues(alpha: 0.95);
      canvas.drawRRect(rRect, backgroundPaint);
    }


    // Impostiamo il pennello che fungerà da "gomma"
    final eraserPaint = Paint()
      ..blendMode = BlendMode.dstOut // Sottrae l'alpha del tratto a quello dello sfondo
      ..color = Colors.black.withValues(alpha: 0.01) // 10% di schiarimento per ogni passaggio
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0 // Leggermente più largo per un effetto più morbido
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Disegniamo le linee basandoci sui punti raccolti
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        // Tratto continuo
        canvas.drawLine(points[i]!, points[i + 1]!, eraserPaint);
      } else if (points[i] != null && points[i + 1] == null) {
        // Disegna anche un singolo tocco ("tap" senza trascinamento)
        canvas.drawCircle(points[i]!, 1.0, eraserPaint);
      }
    }

    // Uniamo il layer appena modificato al resto del canvas
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ScratchPainter oldDelegate) {
    // Ridisegna la UI solo se la lista dei punti è cambiata
    //return oldDelegate.points != points;
    return true;
  }


}
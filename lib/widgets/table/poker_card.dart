import 'package:flutter/material.dart';
import '../../theme.dart';

class PokerCardWidget extends StatelessWidget {
  final String? cardCode;
  final double width;
  final double height;
  final double rankFontSize;
  final double suitFontSize;

  const PokerCardWidget({
    super.key,
    this.cardCode,
    this.width = 64,
    this.height = 86,
    this.rankFontSize = 24,
    this.suitFontSize = 19,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(width > 80 ? 15 : 11);
    if (cardCode == null) {
      // A card slot that exists but hasn't been revealed yet - a face-down card, not an empty
      // one, since the API always sends a fixed-size community-card array padded with nulls.
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: KarataColors.card,
          borderRadius: radius,
          border: Border.all(color: KarataColors.bg, width: 2),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: CustomPaint(painter: _CardBackPainter()),
        ),
      );
    }

    final code = cardCode!;
    if (code.length < 2) return const SizedBox();
    final suitChar = code[code.length - 1].toLowerCase();
    final rank = code.substring(0, code.length - 1).toUpperCase();

    const suitSymbols = {'c': '♣', 'd': '♦', 'h': '♥', 's': '♠'};
    const redSuits = {'d', 'h'};
    final suitSymbol = suitSymbols[suitChar] ?? '?';
    final suitColor = redSuits.contains(suitChar)
        ? KarataColors.red
        : KarataColors.cardInk;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.only(top: 7, left: 8),
      decoration: BoxDecoration(
        color: KarataColors.card,
        borderRadius: radius,
        border: Border.all(color: KarataColors.bg, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rank,
            style: TextStyle(
              color: suitColor,
              fontSize: rank.length > 1 ? rankFontSize * 0.8 : rankFontSize,
              height: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            suitSymbol,
            style: TextStyle(
              color: suitColor,
              fontSize: suitFontSize,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBC9C5)
      ..strokeWidth = 4;
    const gap = 9.0;
    final diag = size.width + size.height;
    for (double x = -size.height; x < diag; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

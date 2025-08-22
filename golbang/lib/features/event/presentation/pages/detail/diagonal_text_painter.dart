import 'package:flutter/material.dart';

class DiagonalTextPainter extends CustomPainter {
  final int holeNumber;
  final String par;

  DiagonalTextPainter({required this.holeNumber, required this.par});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    // 대각선
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    const textStyle = TextStyle(color: Colors.black, fontSize: 12);
    final holeTextSpan = TextSpan(text: "$holeNumber홀", style: textStyle);
    final parTextSpan = TextSpan(text: par, style: textStyle);

    final holePainter = TextPainter(
      text: holeTextSpan,
      textDirection: TextDirection.ltr,
    );
    final parPainter = TextPainter(
      text: parTextSpan,
      textDirection: TextDirection.ltr,
    );

    holePainter.layout();
    parPainter.layout();

    // 홀 정보 좌상단
    holePainter.paint(canvas, const Offset(5, 5));
    // 파 정보 우하단
    parPainter.paint(
      canvas,
      Offset(size.width - parPainter.width - 5, size.height - parPainter.height - 5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

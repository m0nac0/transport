import 'package:flutter/material.dart';

/// Paints 1 / 2 lines coming from top and bottom, separated by whitespace in the center and with "serif" ends.
/// Paints nothing if the respective color is null.
class StopLinePainter extends CustomPainter {
  final Color? colorTop;
  final Color? colorBottom;

  static const double strokeWidth = 3;

  StopLinePainter(
    this.colorTop,
    this.colorBottom,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (colorTop != null) {
      var verticalEnd = Offset(size.width / 2, size.height / 2 - 3);
      canvas.drawLine(
          Offset(size.width / 2, 0),
          verticalEnd,
          Paint()
            ..color = colorTop!
            ..strokeWidth = strokeWidth);
      canvas.drawLine(
          verticalEnd + const Offset(-strokeWidth / 2, 0),
          verticalEnd + const Offset(10, 0),
          Paint()
            ..color = colorTop!
            ..strokeWidth = 3);
    }
    if (colorBottom != null) {
      var verticalEnd = Offset(size.width / 2, size.height / 2 + 3);
      canvas.drawLine(
          verticalEnd,
          Offset(size.width / 2, size.height),
          Paint()
            ..color = colorBottom!
            ..strokeWidth = 3);
      canvas.drawLine(
          verticalEnd + const Offset(-strokeWidth / 2, 0),
          verticalEnd + const Offset(10, 0),
          Paint()
            ..color = colorBottom!
            ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(StopLinePainter oldDelegate) =>
      colorTop != oldDelegate.colorTop ||
      colorBottom != oldDelegate.colorBottom;

  @override
  bool shouldRebuildSemantics(StopLinePainter oldDelegate) =>
      colorTop != oldDelegate.colorTop ||
      colorBottom != oldDelegate.colorBottom;
}

/// Paints a vertical bar with a single color.
/// Paints nothing if the color is null.
class ThrougLinePainter extends CustomPainter {
  final Color? color;

  ThrougLinePainter(
    this.color,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (color != null) {
      canvas.drawLine(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          Paint()
            ..color = color!
            ..strokeWidth = 3);
      canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          4,
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(ThrougLinePainter oldDelegate) =>
      color != oldDelegate.color;

  @override
  bool shouldRebuildSemantics(ThrougLinePainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Paints 1 / 2 lines coming from top and bottom, separated by whitespace in the center and with "serif" ends.
/// Paints nothing if the respective color is null.
class StopLines extends StatelessWidget {
  final Color? colorTop;
  final Color? colorBottom;

  const StopLines(this.colorTop, this.colorBottom, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StopLinePainter(colorTop, colorBottom),
    );
  }
}

/// Paints a vertical bar with a single color.
/// Paints nothing if the color is null.
class ThrougLine extends StatelessWidget {
  final Color? color;

  const ThrougLine(this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ThrougLinePainter(color),
    );
  }
}

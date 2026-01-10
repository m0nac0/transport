// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:transport/datamodel/tickers.dart';
import 'package:transport/datamodel/transport_type.dart';
import 'package:transport/ui/util/colors.dart';
import 'package:transport/ui/ticker/ticker_main.dart';
import 'package:transport/l10n/app_localizations.dart';

class TickerLineOrEventTypeWidget extends StatelessWidget {
  const TickerLineOrEventTypeWidget({
    super.key,
    required this.text,
    required this.dividedBackgroundColors,
    required this.backgroundColor,
    required this.textColor,
    this.isWide = false,
    this.borderColor,
    this.roundedCorners = false,
    this.isXl = false,
    this.image,
  });

  TickerLineOrEventTypeWidget.line(TickerLine line,
      {Key? key, bool showSEVIfApplicable = false, bool isXl = false})
      : this(
            key: key,
            dividedBackgroundColors: switch (line.name) {
              "U7" => [Colors.green, Colors.red],
              "U8" => [Colors.red, Colors.orange],
              _ => null
            },
            backgroundColor: (showSEVIfApplicable && (line.sev ?? false))
                ? Colors.white
                : getLineBackgroundColor(line.type, line.name),
            text: line.name,
            textColor: (showSEVIfApplicable && (line.sev ?? false))
                ? Colors.purple
                : getLineTextColor(line.name),
            isWide: line.name.length > 3,
            borderColor: (showSEVIfApplicable && (line.sev ?? false))
                ? Colors.purple
                : null,
            roundedCorners: line.type == TransportType.SBAHN,
            isXl: isXl);

  TickerLineOrEventTypeWidget.event(EventType category,
      {Key? key, bool isXl = false})
      : this(
            key: key,
            dividedBackgroundColors: null,
            backgroundColor: Colors.black,
            text: category.name.toUpperCase(),
            textColor: Colors.white,
            isWide: true,
            isXl: isXl);

  final String text;
  final List<Color>? dividedBackgroundColors;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool isWide;
  final bool roundedCorners;
  final bool isXl;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final double height = isXl ? 40 : 25;

    var textStyle = TextStyle(
        fontWeight: FontWeight.w600,
        color: textColor,
        fontSize: isXl ? 20 : null);
    double minWidth = isXl ? 70 : 50;
    var constraints = BoxConstraints(
      minWidth: minWidth,
      maxWidth: isWide ? 110 : minWidth,
      minHeight: height,
      maxHeight: height,
    );
    if (dividedBackgroundColors != null &&
        dividedBackgroundColors!.length == 2) {
      return Container(
        constraints: constraints,
        child: CustomPaint(
          painter: DividedBackgroundPainter(
              dividedBackgroundColors![0], dividedBackgroundColors![1]),
          child: Center(
              child: Text(text, textAlign: TextAlign.center, style: textStyle)),
        ),
      );
    }
    if (image != null) {
      return Image.asset(
        "assets/$image.png",
        width: minWidth,
        semanticLabel: AppLocalizations.of(context)!.lineLabel(image ?? text),
      );
    }
    return Semantics(
      label: AppLocalizations.of(context)!.lineLabel(text),
      child: IntrinsicWidth(
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                roundedCorners ? BorderRadius.all(Radius.circular(10)) : null,
            border: borderColor != null
                ? Border.all(color: Colors.purple, width: 2.5)
                : null,
            color: backgroundColor,
          ),
          constraints: constraints,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              //TODO: show soccer icon for soccer event
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The text color for line indicators
  static Color getLineTextColor(String firstName) =>
      firstName == "S8" ? Colors.orange : white;

  static Color? getLineBackgroundColorOrNull(
      TransportType? type, String? name) {
    if (type == null || name == null) {
      return null;
    } else {
      return getLineBackgroundColor(type, name);
    }
  }

  /// The background color for line indicators
  static Color getLineBackgroundColor(TransportType type, String firstName) {
    if ("Fussweg" == firstName) {
      return Colors.grey;
    }
    var isNightLine = firstName.startsWith("N");
    return switch (type) {
      TransportType.BUS => busBlue,
      TransportType.TRAM =>
        isNightLine ? Colors.black : Color.fromARGB(255, 208, 46, 38),
      TransportType.UBAHN => switch (firstName) {
          "U1" || "U7" => Color.fromARGB(255, 86, 131, 77),
          "U2" || "U8" => Color.fromARGB(255, 194, 8, 49),
          "U3" => Color.fromARGB(255, 225, 141, 62),
          "U4" => const Color.fromARGB(255, 76, 175, 175),
          "U5" => Color.fromARGB(255, 188, 122, 0),
          "U6" => Color.fromARGB(255, 0, 101, 174),
          _ => Colors.grey,
        },
      TransportType.SBAHN => switch (firstName) {
          "S1" => Colors.blue,
          "S2" => Colors.lightGreen,
          "S3" => Colors.purple,
          "S4" => Colors.red,
          "S5" => Color.fromARGB(255, 0, 84, 126),
          "S6" => Colors.green,
          "S7" => Color.fromARGB(255, 150, 56, 51),
          "S8" => Colors.black,
          "S20" => Colors.pink,
          _ => Colors.green,
        },
      TransportType.REGIONAL_BUS => busBlue,
      TransportType.BAHN => Colors.black,
      TransportType.SCHIFF => Colors.blueAccent,
      TransportType.RUFTAXI => Color.fromARGB(255, 70, 130, 180),
      _ => isNightLine ? Colors.black : busBlue,
    };
  }
}

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:transport/ui/util/format_time.dart';

/// Displays an arrival/departure time, optionally with a delay
/// If delay is set, the text is color coded (red for delay, green for on time)
class ArrivalDepartureTime extends StatelessWidget {
  const ArrivalDepartureTime(
      {super.key,
      required this.time,
      required this.delay,
      this.isSmall = false});

  final DateTime time;
  final int? delay;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    var actualTime = time;
    if (delay != null) {
      if (delay! > 0) {
        actualTime = time.add(Duration(minutes: delay!));
      } else if (delay! < 0) {
        actualTime = time.subtract(Duration(minutes: delay!.abs()));
      }
    }
    String formattedTime = formatOnlyTime(actualTime);
    var style = isSmall
        ? TextStyle(fontSize: 12)
        : TextStyle(fontWeight: FontWeight.bold);

    return Text(
      formattedTime,
      style: delay != null
          ? (TextStyle(
              color: delay! == 0
                  ? Colors.green
                  : (delay! > 0 ? Colors.red : Colors.purpleAccent),
            ).merge(style))
          : style,
    );
  }
}

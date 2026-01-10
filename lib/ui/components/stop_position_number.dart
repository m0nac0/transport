// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:transport/l10n/app_localizations.dart';

class StopPositionNumber extends StatelessWidget {
  const StopPositionNumber({
    super.key,
    required this.stopPositionNumber,
  });

  final String? stopPositionNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Color.fromARGB(255, 87, 175, 62),
            width: 2,
          ),
          color: Color.fromARGB(255, 251, 230, 77)),
      child: Center(
          child: Text(
          stopPositionNumber ?? "",
          semanticsLabel: AppLocalizations.of(context)!.stopPointLabel(stopPositionNumber ?? ""),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color.fromARGB(255, 87, 175, 62),
          ),
        ),
      ),
    );
  }
}

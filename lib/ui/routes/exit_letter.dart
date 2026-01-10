// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:transport/ui/util/colors.dart';

class ExitLetter extends StatelessWidget {
  const ExitLetter({
    super.key,
    required this.exitLetter,
  });

  final String exitLetter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(shape: BoxShape.circle, color: darkGrey),
      child: Center(
        child: Text(
          exitLetter,
          style: const TextStyle(
            // fontWeight: FontWeight.bold,
            fontSize: 13,
            color: white,
          ),
        ),
      ),
    );
  }
}

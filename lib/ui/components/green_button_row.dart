// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:transport/ui/util/colors.dart';

class GreenButtonRow extends StatelessWidget {
  final String text;
  final Function() onPressed;

  const GreenButtonRow(
      {super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ButtonStyle(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                backgroundColor: WidgetStateProperty.all<Color>(
                    Color.fromARGB(255, 33, 161, 32)),
              ),
              child: Text(
                text,
                style: TextStyle(color: white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

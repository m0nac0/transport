// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

class AnimatedClearButton extends StatelessWidget {
  const AnimatedClearButton({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 200),
      opacity: controller.text.isNotEmpty ? 1 : 0,
      child: IconButton(
        icon: Icon(Icons.cancel,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey
                : Colors.white),
        onPressed: () => controller.text = "",
      ),
    );
  }
}

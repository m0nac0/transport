// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

class RightArrowIcon extends StatelessWidget {
  const RightArrowIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.keyboard_arrow_right_sharp,
      size: 28,
    );
  }
}

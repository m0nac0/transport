// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:transport/ui/util/colors.dart';

class DelayText extends StatelessWidget {
  final int? delayInMinutes;
  final BuildContext context;

  const DelayText(this.delayInMinutes, this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      switch (delayInMinutes) {
        null || 0 => "",
        > 0 => "(+$delayInMinutes)",
        < 0 => "(-${delayInMinutes!.abs()})",
        _ => "",
      },
      style: TextStyle(
          color: delayInMinutes == null
              ? Theme.of(context).colorScheme.onBackground
              : getDelayColor(delayInMinutes!)),
    );
  }
}

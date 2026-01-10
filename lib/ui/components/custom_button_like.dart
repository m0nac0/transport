// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

class CustomButtonLike extends StatelessWidget {
  final void Function()? onTap;
  final void Function()? onLongPress;
  final Widget child;

  const CustomButtonLike(
      {super.key, required this.child, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        cursor: onTap != null
            ? WidgetStateMouseCursor.clickable
            : MouseCursor.defer,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          // this means that also e.g. clicks in the empty space of a row trigger the click event
          behavior: HitTestBehavior.opaque,
          child: child,
        ));
  }
}

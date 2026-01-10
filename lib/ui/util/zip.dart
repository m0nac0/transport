// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:math';
import 'package:flutter/material.dart';

List<T> zip<T>(List<T> list1, List<T> list2) {
  return Iterable.generate(max(list1.length, list2.length)).expand((i) sync* {
    if (i < list1.length) yield list1[i];
    if (i < list2.length) yield list2[i];
  }).toList();
}

List<Widget> zipWithPaddingWidget(List<Widget> widgets,
    [Widget padding = const SizedBox(width: 8)]) {
  return zip(widgets, List.filled(max((widgets.length), 0), padding));
}


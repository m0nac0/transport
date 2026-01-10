// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables


import 'package:transport/datamodel/tickers.dart';

import 'package:flutter/material.dart';


final Color greyBg = Color.fromARGB(255, 229, 229, 234); // Colors.grey[200]!;
const Color darkGrey = Color.fromARGB(255, 150, 150, 150);
final Color blueBg = Color.fromARGB(255, 70, 100, 160);
const Color white = Colors.white;
const Color tickerYellow = Color.fromARGB(255, 255, 255, 0);
const Color busBlue = Color.fromARGB(255, 8, 87, 105);
const Color lightGrey = Color.fromARGB(255, 243, 243, 247);

const linkStyle = TextStyle(
    color: Colors.blue,
    decoration: TextDecoration.underline,
    decorationColor: Colors.blue);

Color getTickerColor(Ticker ticker, BuildContext context) {
  return ticker.type == TickerType.disruption
      ? tickerYellow
      : Theme.of(context).colorScheme.surface;
}

Color getTickerTextColor(Ticker ticker, BuildContext context) {
  return ticker.type == TickerType.disruption
      ? Colors.black
      : Theme.of(context).colorScheme.onSurface;
}

ColorSwatch<int> getDelayColor(int delayInMinutes) {
  return ((delayInMinutes > 0)
      ? Colors.red
      : (delayInMinutes < 0 ? Colors.purpleAccent : Colors.green));
}

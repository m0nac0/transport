// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:transport/api/munich_api.dart';
import 'package:transport/datamodel/tickers.dart';

class TickerProvider extends ChangeNotifier {
  List<Ticker> tickers = <Ticker>[];
  DateTime? lastUpdate;
  int? tickerCount;
  MunichApiClient apiClient = MunichApiClient();

  TickerProvider() {
    loadAllTickers();
    Timer.periodic(Duration(minutes: 1), (_) => loadOnlyIncidents());
  }



  List<Ticker> getIncidents() {
    return tickers.where((ticker) => ticker.type == TickerType.disruption).toList();
  }

  Future<void> loadAllTickers() async {
    await apiClient.getTickers(useFib: true).then((value) {
      if (value != null) {
        tickers = value;
        lastUpdate = DateTime.now();
        tickerCount = value
            .where((ticker) => ticker.type == TickerType.disruption)
            .map((ticker) {
              return ticker.lines.map((line) => line.name).toList() + ticker.eventTypes.map((e) => e.name).toList();
            })
            .fold([], (value, element) => value..addAll(element))
            .toSet()
            .length;
      }
    });
    notifyListeners();
  }

  Future<void> loadOnlyIncidents() async {
    await apiClient.getTickers(useFib: true, onlyIncidents: true)
        .then((value) {
      if (value != null) {
        tickerCount = value
            .map((ticker) => ticker.lines.map((line) => line.name).toList())
            .fold([], (value, element) => value..addAll(element))
            .toSet()
            .length;
      }
    });
    notifyListeners();
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport/datamodel/recents_list_item.dart';
import 'package:transport/datamodel/station.dart';


class RecentsListProvider<T extends IdEquality> extends ChangeNotifier {
  final Map<String, dynamic> Function(T) serialize;
  final T? Function(Map<String, dynamic>) unserialize;
  List<RecentsListItem<T>> _previousItems = [];

  List<RecentsListItem<T>> get values => _previousItems;
  String serializationKey;

  RecentsListProvider(this.serialize, this.unserialize, this.serializationKey) {
    loadData();
  }

  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(serializationKey,
        _previousItems.map((e) => jsonEncode(e.toJson(serialize))).toList());
  }

  /// Load Data from shared prefs
  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? previousConnectionsJson =
        prefs.getStringList(serializationKey);
    _previousItems = previousConnectionsJson
            ?.map<RecentsListItem<T>?>(
                (e) => RecentsListItem.fromJson(jsonDecode(e), unserialize))
            .nonNulls
            .toList() ??
        [];
    _previousItems.sort();
    notifyListeners();
  }

  void add(RecentsListItem<T> newItem, {bool keepFavorite = true}) {
    if (keepFavorite) {
      try {
        var previousItem =
            _previousItems.firstWhere((item) => item.itemEquals(newItem));
        newItem = RecentsListItem(
            newItem.item, previousItem.favorite, newItem.lastUse);
      } on StateError {
        //
      }
    }

    var newList = [newItem];
    while (newList.length < 10 && _previousItems.isNotEmpty) {
      var item = _previousItems.removeAt(0);
      if (newList.any((element) => element.itemEquals(item))) continue;
      newList.add(item);
    }
    newList.sort();
    _previousItems = newList.take(10).toList();

    notifyListeners();
    saveData();
  }

  void remove(RecentsListItem<T> itemToRemove) {
    _previousItems.removeWhere((test) => test.itemEquals(itemToRemove));
    notifyListeners();
    saveData();
  }

  void toggleFavorite(RecentsListItem<T> item) {
    add(RecentsListItem(item.item, !item.favorite, item.lastUse),
        keepFavorite: false);
    notifyListeners();
    saveData();
  }
}

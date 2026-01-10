// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the favorite lines for the departure screen
class FavoriteLinesProvider extends ChangeNotifier {
  Set<String> _favoriteLines = <String>{};
  Set<String> get favoriteLines => _favoriteLines;
  final favoritesSerializationKey = "favoriteLines";

  FavoriteLinesProvider() {
    loadFavorites();
  }

  /// Load Data from shared prefs
  Future<void> loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? favoriteLinesJson =
        prefs.getStringList(favoritesSerializationKey);
    _favoriteLines = favoriteLinesJson?.toSet() ?? {};
    notifyListeners();
  }

  Future<void> storeFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(favoritesSerializationKey, _favoriteLines.toList());
  }

  Future<void> toggleFavoriteLine(String lineName) async {
    if (_favoriteLines.contains(lineName)) {
      _favoriteLines.remove(lineName);
    } else {
      _favoriteLines.add(lineName);
    }
    await storeFavorites();
    notifyListeners();
  }
}

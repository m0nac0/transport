// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport/datamodel/favorite_button_item.dart';

/// Manages the favorite locations for the buttons on the main screen
class FavoritesProvider extends ChangeNotifier {
  List<FavoriteButtonItem> _favoriteButtons = [];
  List<FavoriteButtonItem> get favoriteButtons => _favoriteButtons;
  static const String _favoritesSerializationKey = "favorites_buttons";
  SharedPreferences? _sharedPreferences;

  FavoritesProvider() {
    ensureInitialized().then((_) => loadFavoriteButtons());
  }

  Future<void> ensureInitialized() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
  }

  Future<List<FavoriteButtonItem>> loadFavoriteButtons() async {
    await ensureInitialized();
    final List<String>? previousConnectionsJson =
        _sharedPreferences!.getStringList(_favoritesSerializationKey);
    List<FavoriteButtonItem> items = previousConnectionsJson
            ?.map<FavoriteButtonItem?>(
                (e) => FavoriteButtonItem.fromJson(jsonDecode(e)))
            .nonNulls
            .toList() ??
        [];
    items.sort((var a, var b) => a.created.compareTo(b.created));
    _favoriteButtons = items;
    notifyListeners();
    return items;
  }

  _storeFavoriteButtons(List<FavoriteButtonItem> items) async {
    await ensureInitialized();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_favoritesSerializationKey,
        items.map((e) => jsonEncode(e.toJson())).toList());
    notifyListeners();
  }

  Future<void> addFavorite(FavoriteButtonItem newItem) async {
    _favoriteButtons.add(newItem);
    return _storeFavoriteButtons(_favoriteButtons);
  }

  Future<void> _removeFavorite(DateTime oldItemId) async {
    _favoriteButtons.removeWhere((e) => e.created == oldItemId);
  }

  Future<void> removeFavorite(DateTime oldItemId) async {
    _removeFavorite(oldItemId);
    return _storeFavoriteButtons(favoriteButtons);
  }

  Future<void> updateFavorite(
      DateTime oldItemId, FavoriteButtonItem newItem) async {
    await _removeFavorite(oldItemId);
    return addFavorite(newItem);
  }
}

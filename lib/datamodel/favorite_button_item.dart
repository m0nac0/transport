import 'package:flutter/material.dart';
import 'package:transport/datamodel/location_input_model.dart';

class FavoriteButtonItem {
  final String name;
  final IconData icon;
  final Color bgColor;
  final SpecificLocationInput station;

  /// creation time is used as unique id.
  final DateTime created;

  const FavoriteButtonItem(
      this.name, this.icon, this.bgColor, this.station, this.created);

  static FavoriteButtonItem? fromJson(Map<String, dynamic> json) {
    var name = json['name'];
    var icon = IconData(json['icon'], fontFamily: json['iconFontFamily']);
    var bgColor = Color(json['bgColor']);
    var station = SpecificLocationInput.getFromJson(json['station']);
    var created = json.containsKey("created")
        ? DateTime.fromMillisecondsSinceEpoch(json["created"])
        : DateTime.now();
    if (station != null) {
      return FavoriteButtonItem(name, icon, bgColor, station, created);
    } else {
      debugPrint("Failed to deserialize FavoriteButtonItem: $json");
      return null;
    }
  }

  toJson() {
    return {
      'name': name,
      'icon': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'bgColor': bgColor.value,
      'station': station.toJson(),
      "created": created.millisecondsSinceEpoch
    };
  }

  @override
  bool operator ==(Object other) {
    return other is FavoriteButtonItem &&
        name == other.name &&
        icon == other.icon &&
        bgColor == other.bgColor &&
        station == other.station &&
        created == other.created;
  }

  @override
  int get hashCode =>
      name.hashCode +
      icon.hashCode +
      bgColor.hashCode +
      station.hashCode +
      created.hashCode;
}

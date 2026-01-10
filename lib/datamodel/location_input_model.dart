import 'station.dart';

sealed class ResolvedLocationInput extends SpecificLocationInput {
  static ResolvedLocationInput? getFromJson(Map<String, dynamic> json) {
    var type = json["type"];
    return switch (type) {
      "LocationInputStation" => LocationInputStation.fromJson(json),
      "LocationInputAddress" => LocationInputAddress.fromJson(json),
      "LocationInputPoi" => LocationInputPoi.fromJson(json),
      _ => null,
    };
  }
}

sealed class SpecificLocationInput extends LocationInput implements IdEquality {
  @override
  String toLocationString();

  @override
  String? getPlace();

  @override
  toJson();

  static SpecificLocationInput? getFromJson(Map<String, dynamic> json) {
    var type = json["type"];
    return switch (type) {
      "LocationInputCoordinates" => LocationInputCurrentLocation.fromJson(json),
      _ => ResolvedLocationInput.getFromJson(json),
    };
  }
}

/// Represents a location input from the user.
sealed class LocationInput {
  String toLocationString();

  String? getPlace();

  toJson();
}

/// Represents a location input from the user where a specific station was selected.class LocationInputStation extends LocationInput {
class LocationInputStation extends ResolvedLocationInput {
  final Station station;

  LocationInputStation(this.station);

  @override
  toLocationString() {
    return station.name ?? "";
  }

  @override
  String? getPlace() {
    return station.place;
  }

  @override
  toJson() {
    return {"type": "LocationInputStation", "station": station.toJson()};
  }

  LocationInputStation.fromJson(Map<String, dynamic> json)
      : this(Station.fromJson(json["station"]));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationInputStation &&
          runtimeType == other.runtimeType &&
          station == other.station;

  @override
  int get hashCode => station.hashCode;

  @override
  bool equalById(Object other) {
    return other is LocationInputStation && other.station.equalById(station);
  }
}

mixin LocationInputWithCoordinates {
  double get latitude;
  double get longitude;
}

/// Represents a location input from the user where a specific address was selected.
class LocationInputAddress extends ResolvedLocationInput
    with LocationInputWithCoordinates {
  final String name;
  final String place;
  @override
  final double latitude;
  @override
  final double longitude;

  LocationInputAddress(this.name, this.place, this.latitude, this.longitude);

  @override
  toLocationString() {
    return name;
  }

  @override
  String? getPlace() {
    return place;
  }

  @override
  toJson() {
    return {
      "type": "LocationInputAddress",
      "name": name,
      "place": place,
      "latitude": latitude,
      "longitude": longitude,
    };
  }

  LocationInputAddress.fromJson(Map<String, dynamic> json)
      : this(json["name"], json["place"], json["latitude"], json["longitude"]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationInputAddress &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          place == other.place &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      name.hashCode ^ place.hashCode ^ latitude.hashCode ^ longitude.hashCode;

  @override
  bool equalById(Object other) {
    return this == other;
  }
}

/// Represents a location input from the user where a specific POI was selected.
class LocationInputPoi extends ResolvedLocationInput
    with LocationInputWithCoordinates {
  final String name;
  final String place;
  @override
  final double latitude;
  @override
  final double longitude;

  LocationInputPoi(this.name, this.place, this.latitude, this.longitude);

  @override
  toLocationString() {
    return name;
  }

  @override
  String? getPlace() {
    return place;
  }

  @override
  toJson() {
    return {
      "type": "LocationInputPoi",
      "name": name,
      "place": place,
      "latitude": latitude,
      "longitude": longitude,
    };
  }

  LocationInputPoi.fromJson(Map<String, dynamic> json)
      : this(
          json["name"],
          json["place"],
          json["latitude"],
          json["longitude"],
        );

  @override
  bool equalById(Object other) {
    return this == other;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationInputPoi &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          place == other.place &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      name.hashCode ^ place.hashCode ^ latitude.hashCode ^ longitude.hashCode;
}

/// Represents a location input from the user where specific coordinates where selected.
/// Usually, because the user selected "my location".
class LocationInputCurrentLocation extends SpecificLocationInput
    with LocationInputWithCoordinates {
  @override
  final double latitude;
  @override
  final double longitude;

  LocationInputCurrentLocation(this.latitude, this.longitude);

  @override
  toLocationString() {
    return "My location";
  }

  @override
  String? getPlace() {
    return "";
  }

  @override
  toJson() {
    return {
      "type": "LocationInputCoordinates",
      "latitude": latitude,
      "longitude": longitude,
    };
  }

  LocationInputCurrentLocation.fromJson(Map<String, dynamic> json)
      : this(
          json["latitude"],
          json["longitude"],
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationInputPoi &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  bool equalById(Object other) {
    return this == other;
  }
}

class LocationInputCurrentLocationLoading extends LocationInput {
  Future<(double, double)?> position;

  LocationInputCurrentLocationLoading(this.position);

  @override
  toLocationString() {
    return "My location";
  }

  @override
  String? getPlace() {
    return null;
  }

  @override
  toJson() {
    return {
      "type": "LocationInputCurrentLocationLoading",
    };
  }
}

/// Represents a location input from the user where only a string was input.
class LocationInputString extends LocationInput {
  final String string;

  LocationInputString(this.string);

  @override
  toLocationString() {
    return string;
  }

  @override
  String? getPlace() {
    return null;
  }

  @override
  toJson() {
    return {
      "type": "LocationInputString",
      "string": string,
    };
  }

  LocationInputString.fromJson(Map<String, dynamic> json)
      : this(
          json["string"],
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationInputString &&
          runtimeType == other.runtimeType &&
          string == other.string;

  @override
  int get hashCode => string.hashCode;
}

import 'package:transport/datamodel/routes.dart';
import 'package:transport/datamodel/transport_type.dart';

typedef StationID = String;

mixin IdEquality{
  bool equalById(Object other);
}

class Station implements IdEquality {
  final double? latitude;
  final double? longitude;

  /// If globalId is null, this is not a real station but an arbitrary point in
  /// a route (e.g. a POI or address selected as origin or destination)
  final StationID? globalId;
  final int? divaId;
  final String? place;
  final String? name;
  final bool? hasZoomData;
  final bool? elevatorOutOfOrder;
  final bool? escalatorOutOfOrder;
  final List<TransportType>? transportTypes;
  final String? surroundingPlanLink;
  final String? aliases;
  final String? tariffZones;
  final String? abbreviation;

  Station({
    required this.latitude,
    required this.longitude,
    required this.globalId,
    required this.divaId,
    required this.place,
    required this.name,
    required this.hasZoomData,
    required this.elevatorOutOfOrder,
    required this.escalatorOutOfOrder,
    required this.transportTypes,
    required this.surroundingPlanLink,
    required this.aliases,
    required this.tariffZones,
    required this.abbreviation,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      latitude: json['latitude'],
      longitude: json['longitude'],
      globalId: json['globalId'],
      divaId: json['divaId'],
      place: json['place'],
      name: json['name'],
      hasZoomData: json['hasZoomData'],
      elevatorOutOfOrder: json["hasOutOfOrderElevator"],
      escalatorOutOfOrder: json["hasOutOfOrderEscalator"],
      transportTypes: json['transportTypes'] == null
          ? null
          : List<String>.from(json['transportTypes'])
          .map(TransportType.fromString)
          .toList()
        ?..sort((a, b) =>
            TransportType.values.indexOf(a).compareTo(
                TransportType.values.indexOf(b)),),
      surroundingPlanLink: json['surroundingPlanLink'],
      aliases: json['aliases'],
      tariffZones: json['tariffZones'],
      abbreviation: json['abbreviation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'STATION',
      'latitude': latitude,
      'longitude': longitude,
      'globalId': globalId,
      'divaId': divaId,
      'place': place,
      'name': name,
      'hasZoomData': hasZoomData,
      'escalatorOutOfOrder': escalatorOutOfOrder,
      'elevatorOutOfOrder': elevatorOutOfOrder,
      'transportTypes': transportTypes?.map((type) => type.toString()).toList(),
      'surroundingPlanLink': surroundingPlanLink,
      'aliases': aliases,
      'tariffZones': tariffZones,
      'abbreviation': abbreviation,
    };
  }

  /// If globalId is null, this is not a real station but an arbitrary point in
  /// a route (e.g. a POI or address selected as origin or destination)
  bool isRealStation() => globalId != null && globalId!.isNotEmpty;

  @override
  bool equalById(Object other) =>
      other is Station && other.globalId == globalId;


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Station &&
              runtimeType == other.runtimeType &&
              latitude == other.latitude &&
              longitude == other.longitude &&
              globalId == other.globalId &&
              divaId == other.divaId &&
              place == other.place &&
              name == other.name &&
              hasZoomData == other.hasZoomData &&
              elevatorOutOfOrder == other.elevatorOutOfOrder &&
              escalatorOutOfOrder == other.escalatorOutOfOrder &&
              transportTypes == other.transportTypes &&
              surroundingPlanLink == other.surroundingPlanLink &&
              aliases == other.aliases &&
              tariffZones == other.tariffZones &&
              abbreviation == other.abbreviation;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      globalId.hashCode ^
      divaId.hashCode ^
      place.hashCode ^
      name.hashCode ^
      hasZoomData.hashCode ^
      elevatorOutOfOrder.hashCode ^
      escalatorOutOfOrder.hashCode ^
      transportTypes.hashCode ^
      surroundingPlanLink.hashCode ^
      aliases.hashCode ^
      tariffZones.hashCode ^
      abbreviation.hashCode;

}

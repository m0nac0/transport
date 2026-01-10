// ignore_for_file: constant_identifier_names

import 'package:transport/datamodel/station.dart';
import 'package:transport/datamodel/tickers.dart';
import 'package:transport/datamodel/transport_type.dart';

class TransportRoute {
  /// Must not be empty
  final List<RoutingPart> parts;
  final double distance;
  final List<String> zones;

  int get totalMinutes => parts.last.to.plannedDeparture
      .difference(parts.first.from.plannedDeparture)
      .inMinutes;

  DateTime get plannedDeparture => parts.first.from.plannedDeparture;

  DateTime get expectedDeparture => parts.first.from.expectedDeparture;

  DateTime get plannedArrival => parts.last.to.plannedDeparture;

  DateTime get expectedArrival => parts.last.to.expectedDeparture;

  TransportRoute({
    required this.parts,
    required this.distance,
    required this.zones,
  }) : assert(parts.isNotEmpty);

  TransportRoute copyWith({
    List<RoutingPart>? parts,
    double? distance,
    List<String>? zones,
  }) {
    return TransportRoute(
      parts: parts ?? this.parts,
      distance: distance ?? this.distance,
      zones: zones ?? this.zones,
    );
  }
}

class Line {
  final String? label;

  /// Sometimes the API may return a very long label (e.g. "LUFTHANSA EXPRESS BUS"), then we provide a shortLabel (e.g. "LH")
  /// shortLabel should not be null, unless the original label is null (e.g. for walking routes), in which case shortLabel is also null
  final String? shortLabel;
  final TransportType? transportType;
  final String? destination;
  final String? trainType;
  final String? network;
  final String? divaId;
  final bool? sev;
  final bool isWalk;

  String get displayLabel {
    if (shortLabel == null) {
      return "";
    } else {
      if (trainType != null && trainType!.isNotEmpty) {
        return "$trainType $shortLabel";
      } else {
        return shortLabel!;
      }
    }
  }

  Line({
    required this.label,
    required this.shortLabel,
    required this.transportType,
    required this.destination,
    required this.trainType,
    required this.network,
    required this.divaId,
    required this.sev,
    required this.isWalk,
  });

  @override
  bool operator ==(Object other) {
    if (other is Line) {
      return label == other.label &&
          transportType == other.transportType &&
          destination == other.destination &&
          trainType == other.trainType &&
          network == other.network &&
          sev == other.sev;
    } else {
      return super == other;
    }
  }

  @override
  int get hashCode =>
      label.hashCode +
      transportType.hashCode +
      destination.hashCode +
      trainType.hashCode +
      network.hashCode +
      sev.hashCode;
}

class RoutingPoint {
  final Station station;
  final DateTime plannedDeparture;
  final int? delay;
  final String? stopPositionNumber;
  final String? platform;
  final bool? platformChanged;

  DateTime get expectedDeparture => delay == null
      ? plannedDeparture
      : plannedDeparture.add(Duration(minutes: delay!));

  RoutingPoint(
      {required this.station,
      required this.plannedDeparture,
      this.delay,
      this.stopPositionNumber,
      this.platform,
      this.platformChanged});

  bool equalsStationAndPlannedDeparture(RoutingPoint other) {
    return other.station.globalId == station.globalId &&
        other.plannedDeparture == plannedDeparture;
  }

  RoutingPoint copyWith({
    Station? station,
    DateTime? plannedDeparture,
    int? delay,
    String? stopPositionNumber,
    String? platform,
    bool? platformChanged,
  }) {
    return RoutingPoint(
      station: station ?? this.station,
      plannedDeparture: plannedDeparture ?? this.plannedDeparture,
      delay: delay ?? this.delay,
      stopPositionNumber: stopPositionNumber ?? this.stopPositionNumber,
      platform: platform ?? this.platform,
      platformChanged: platformChanged ?? this.platformChanged,
    );
  }
}

enum Occupancy {
  LOW,
  MEDIUM,
  HIGH,
  UNKNOWN,
}

class RoutingPart {
  final RoutingPoint from;
  final RoutingPoint to;
  final List<RoutingPoint> intermediateStops;
  final Line line;
  final Occupancy occupancy;

  int get totalMinutes =>
      to.plannedDeparture.difference(from.plannedDeparture).inMinutes;

  List<Ticker> tickers;
  List<String> lineInfo;
  List<CoordinatePair>? coordinates;
  List<CoordinatePair>? interchangeCoordinates;
  double? distance;
  String? exitLetter;

  RoutingPart(
      {required this.from,
      required this.to,
      required this.intermediateStops,
      required this.line,
      this.tickers = const [],
      this.occupancy = Occupancy.UNKNOWN,
      this.lineInfo = const [],
      this.coordinates,
      this.interchangeCoordinates,
      this.distance,
      this.exitLetter});

  RoutingPart copyWith({
    RoutingPoint? from,
    RoutingPoint? to,
    List<RoutingPoint>? intermediateStops,
    Line? line,
    List<Ticker>? tickers,
    Occupancy? occupancy,
    List<String>? lineInfo,
    List<CoordinatePair>? coordinates,
    List<CoordinatePair>? interchangeCoordinates,
    double? distance,
    String? exitLetter,
  }) {
    return RoutingPart(
      from: from ?? this.from,
      to: to ?? this.to,
      intermediateStops: intermediateStops ?? this.intermediateStops,
      line: line ?? this.line,
      tickers: tickers ?? this.tickers,
      occupancy: occupancy ?? this.occupancy,
      lineInfo: lineInfo ?? this.lineInfo,
      coordinates: coordinates ?? this.coordinates,
      interchangeCoordinates:
          interchangeCoordinates ?? this.interchangeCoordinates,
      distance: distance ?? this.distance,
      exitLetter: exitLetter ?? this.exitLetter,
    );
  }
}

class CoordinatePair {
  final double latitude;
  final double longitude;

  const CoordinatePair(this.latitude, this.longitude);
}

/// A LineInfo is a fixed information string for a line, usually regarding special prices/tickets
class LineInfo {
  String transportType;
  String label;
  String information;

  LineInfo(this.transportType, this.label, this.information);
}

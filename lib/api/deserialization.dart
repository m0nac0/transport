import 'dart:math';

import 'package:transport/datamodel/departures.dart';
import 'package:transport/datamodel/routes.dart';
import 'package:transport/datamodel/station.dart';
import 'package:transport/datamodel/station_devices.dart';
import 'package:transport/datamodel/station_postings.dart';
import 'package:transport/datamodel/tickers.dart';
import 'package:transport/datamodel/transport_type.dart';

Departure getDepartureFromJson(Map<String, dynamic> json) {
  bool realtime = json['realtime'] ?? false;
  var realtimeDepartureTime =
      DateTime.fromMillisecondsSinceEpoch(json['realtimeDepartureTime']);
  var plannedDepartureTime =
      DateTime.fromMillisecondsSinceEpoch(json['plannedDepartureTime']);
  // apparently, when realtime is false, the realtimeDepartureTime is sometimes set to weird values
  // (also, when cancelled is true, but then realtime seems to be false)
  var delayInMinutes = json['delayInMinutes'] as int?;
  DateTime expectedDepartureTime =
      realtime ? realtimeDepartureTime : plannedDepartureTime;
  var label = json['label'] as String?;
  // messages are simple string, usually for scenarios like individual vehicles driving a shortened route
  var messages =
      (json['messages'] as List<dynamic>?)?.map((e) => e as String).toList();
  // similar to messages, but seem to be provided for external vehicles
  var infoMessages = (json['infos'] as List<dynamic>?)
      ?.map((e) => Info(
            message: e['message'] as String,
            type: InfoType.fromString(e['type'] as String),
          ))
      .toList();
  for (String message in messages ?? []) {
    bool isInInfoMessages = false;
    for (var infoMessage in infoMessages ?? []) {
      if (message == infoMessage.message) {
        isInInfoMessages = true;
        break;
      }
    }
    if (!isInInfoMessages) {
      infoMessages = [
        ...?infoMessages,
        Info(message: message, type: InfoType.other)
      ];
    }
  }
  return Departure(
    plannedDepartureTime: plannedDepartureTime,
    realtime: json['realtime'] ?? false,
    delayInMinutes: delayInMinutes,
    expectedDepartureTime: expectedDepartureTime,
    transportType:
        TransportType.fromStringOrNull(json['transportType'] as String?),
    label: label,
    shortLabel: label == null ? null : replaceSpecialLabels(label),
    divaId: json['divaId'] as String?,
    network: json['network'] as String?,
    trainType: json['trainType'] as String?,
    destination: json['destination'] as String?,
    cancelled: json['cancelled'] as bool?,
    sev: json['sev'] as bool?,

    /// While we allow Strings, the platform returned by the API is always numeric or null (in cases like "7c" no platform is returned by the API)
    platform: json['platform'] != null ? "${json['platform']}" : null,
    isPlatformChanged: json['platformChanged'] as bool?,
    infoMessages: infoMessages,
    bannerHash: json['bannerHash'] as String?,
    occupancy: parseOccupancyString(json['occupancy'] as String?),
    stopPointGlobalId: json['stopPointGlobalId'] as String?,
    stopPositionNumber: json['stopPositionNumber']?.toString(),
  );
}

String replaceSpecialLabels(String input) {
  return input.replaceAll("LUFTHANSA EXPRESS BUS", "LH");
}

Occupancy parseOccupancyString(String? occupancyString) {
  return occupancyString == null
      ? Occupancy.UNKNOWN
      : Occupancy.values.firstWhere((element) =>
          element.toString() ==
          "Occupancy.${occupancyString.toString().toUpperCase()}");
}

Station getStationFromJson(Map<String, dynamic> json) {
  return Station(
    latitude: json['latitude'],
    longitude: json['longitude'],
    globalId: json["stationGlobalId"],
    divaId: json["stationDivaId"],
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
      ?..sort(
        (a, b) => TransportType.values
            .indexOf(a)
            .compareTo(TransportType.values.indexOf(b)),
      ),
    surroundingPlanLink: json['surroundingPlanLink'],
    aliases: json['aliases'],
    tariffZones: json['tariffZones'],
    abbreviation: json['abbreviation'],
  );
}

StationAccessibilityData getStationDevicesDataFromJson(
    Map<String, dynamic> data) {
  return StationAccessibilityData(
      data["transportDevices"]?.map<DeviceData>((device) {
        var lastUpdate = device["lastUpdate"];
        return DeviceData(
            device["identifier"],
            switch (device["type"]) {
              "FAHRSTUHL" => DeviceType.elevator,
              "ROLLTREPPE" => DeviceType.escalator,
              _ => DeviceType.other
            },
            switch (device["status"]) {
              "IN_BETRIEB" => DeviceStatus.ok,
              "AUSSER_BETRIEB" => DeviceStatus.broken,
              "UNBEKANNT" || _ => DeviceStatus.unknown
            },
            device["description"],
            lastUpdate == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(lastUpdate),
            device["xcoordinate"],
            device["ycoordinate"]);
      }).toList(),
      data["aggregatedStatusFAHRSTUHL"] == "AUSSER_BETRIEB",
      data["aggregatedStatusROLLTREPPE"] == "AUSSER_BETRIEB");
}

Station getStationFromZDMJSON(Map<String, dynamic> json) {
  return Station(
    latitude: json['latitude'],
    longitude: json['longitude'],
    globalId: json["id"],
    divaId: json['divaId'],
    place: json['place'],
    name: json['name'],
    transportTypes: json['products'] == null
        ? null
        : List<String>.from(json['products'])
            .map(TransportType.fromString)
            .toList()
      ?..sort(
        (a, b) => TransportType.values
            .indexOf(a)
            .compareTo(TransportType.values.indexOf(b)),
      ),
    tariffZones: json['tariffZones'],
    abbreviation: json['abbreviation'],
    surroundingPlanLink: null,
    aliases: null,
    hasZoomData: null,
    elevatorOutOfOrder: null,
    escalatorOutOfOrder: null,
  );
}

TickerLine getTickerLinefromEMSJson(Map<String, dynamic> json) {
  return TickerLine(
      name: json['name'],
      type: TransportType.fromString(json['typeOfTransport']),
      network: json["network"] ?? "MVG",
      //sev is not sent for lines in EMS
      sev: null);
}

TickerLine getTickerLinefromFIBJson(Map<String, dynamic> json) {
  return TickerLine(
      name: json['label'],
      type: TransportType.fromString(json['transportType']),
      network: json["network"] ?? "MVG",
      sev: json["sev"] ?? false);
}

Ticker getTickerfromEMSJson(Map<String, dynamic> json) {
  return Ticker(
    id: json['id'],
    title: json['title'],
    text: json['text'],
    type: json['type'] == 'DISRUPTION'
        ? TickerType.disruption
        : TickerType.planned,
    lines: List<TickerLine>.from(
        json['lines'].map((line) => getTickerLinefromEMSJson(line))),
    incidentStart: json['incidentStart'],
    incidentEnd: json['incidentEnd'],
    activeStart: json['activeStart'],
    activeEnd: json['activeEnd'],
    eventTypes: List<EventType>.from((json['incidents'] ?? []).map((type) {
      switch (type) {
        case "BUS":
          return EventType.bus;
        case "STAMMSTRECKE":
          return EventType.stammstrecke;
        case "TRAM":
          return EventType.tram;
        case "METRO":
          return EventType.ubahn;
        case "FOOTBALL":
          return EventType.fussball;
        default:
          return EventType.other;
      }
    })),
  );
}

Ticker getTickerfromFIBJson(Map<String, dynamic> json) {
  //TODO enable showing all incident durations
  DateTime? incidentStart;
  var startTimestamps = (json["incidentDurations"] as Iterable)
      .map((e) => e["from"] as int?)
      .nonNulls;
  if (startTimestamps.isNotEmpty) {
    incidentStart = DateTime.fromMillisecondsSinceEpoch(
        startTimestamps.reduce((a, b) => min(a, b)));
  }
  DateTime? incidentEnd;
  var endTimestamps = (json["incidentDurations"] as Iterable)
      .map((e) => e["to"] as int?)
      .nonNulls;
  if (endTimestamps.isNotEmpty) {
    incidentEnd = DateTime.fromMillisecondsSinceEpoch(
        endTimestamps.reduce((a, b) => max(a, b)));
  }
  return Ticker(
    title: json['title'],
    text: json['description'],
    type:
        json['type'] == 'INCIDENT' ? TickerType.disruption : TickerType.planned,
    lines: List<TickerLine>.from(
        json['lines'].map((line) => getTickerLinefromFIBJson(line))),
    //validFrom is usually the publication date, but we use it as a fallback
    // null is a possible value, especially for the incidentEnd, where it means "until further notice"
    incidentStart: incidentStart ??
        (json.containsKey("validFrom")
            ? DateTime.fromMillisecondsSinceEpoch(json['validFrom'])
            : null),
    incidentEnd: incidentEnd ??
        (json.containsKey("validTo")
            ? DateTime.fromMillisecondsSinceEpoch(json['validTo'])
            : null),
    eventTypes: List<EventType>.from((json['eventTypes'] ?? []).map((type) {
      switch (type) {
        case "BUS":
          return EventType.bus;
        case "STAMMSTRECKE":
          return EventType.stammstrecke;
        case "TRAM":
          return EventType.tram;
        case "UBAHN":
          return EventType.ubahn;
        case "FUSSBALL":
          return EventType.fussball;
        default:
          return EventType.other;
      }
    })),
    links: List<Link>.from(
      (json['links'] ?? []).map((tuple) {
        var uri = Uri.tryParse(tuple["url"]);
        var text = tuple["text"] ?? "Link";
        if (uri == null) {
          return null;
        }
        return Link(uri, text);
      }).where((e) => e != null),
    ),
  );
}

/// Whether a line is a walk
bool _lineIsWalk(String? lineLabel) {
  return lineLabel == "Fussweg";
}

Line getLineFromJson(Map<String, dynamic> json) {
  var label = json['label'] as String?;
  return Line(
      label: label,
      shortLabel: label == null ? null : replaceSpecialLabels(label),
      transportType:
          TransportType.fromStringOrNull(json['transportType'] as String?),
      destination: json['destination'] as String?,
      trainType: json['trainType'] as String?,
      network: json['network'] as String?,
      divaId: json['divaId'] as String?,
      sev: json['sev'] as bool?,
      isWalk: _lineIsWalk(json['label'] as String?));
}

List<ScheduleOrMap> getSchedulesAndMapsFromJson(List data) {
  return data.map<ScheduleOrMap>((e) {
    var uri = Uri.parse(e["uri"]);
    var direction = e["direction"];
    return switch (e["scheduleKind"]) {
      "CONTEXT_MAP" => OverviewMap(uri, direction),
      "STATION_OVERVIEW_MAP" => StationMap(uri, direction),
      _ => Schedule(
          uri,
          e["scheduleName"],
          switch (e["scheduleKind"]) {
            "BUS" => TransportType.BUS,
            "SUBWAY" => TransportType.UBAHN,
            "TRAM" => TransportType.TRAM,
            "NIGHT_LINE" => TransportType.OTHER,
            _ => TransportType.OTHER,
          },
          direction)
    };
  }).toList();
}

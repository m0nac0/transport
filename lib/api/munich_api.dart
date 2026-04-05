import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:transport/api/deserialization.dart';
import 'package:transport/api/user_agent.dart';
import 'package:transport/datamodel/station_devices.dart';
import 'package:transport/datamodel/station_postings.dart';
import 'package:transport/datamodel/transport_type.dart';
import 'package:transport/packages/polyline/polyline.dart';

import '../datamodel/departures.dart';
import '../datamodel/routes.dart';
import '../datamodel/station.dart';
import '../datamodel/tickers.dart';
import '../datamodel/location_input_model.dart';

// TODO error handling / retry logic
class MunichApiClient {
  static const String _baseUrlApi = kIsWeb
      ? "http://localhost:8000/https://www.mvg.de/api"
      : 'https://www.mvg.de/api';
  static const String _baseUrl = '$_baseUrlApi/bgw-pt/v3';
  static Uri baseUriApi = Uri.parse(_baseUrl);

  static const String _routesEndpoint = 'routes';
  static const String _departuresEndpoint = 'departures';
  static const String _messagesEndpoint = "messages";

  static Uri getUri(String endpointPath, Map<String, String> queryParameters) {
    Uri finalUri = Uri(
      scheme: baseUriApi.scheme,
      host: baseUriApi.host,
      pathSegments: [...baseUriApi.pathSegments, ...endpointPath.split("/")],
      queryParameters: queryParameters,
      // query: queryParameters.entries
      //     .map((entry) => entry.key + "=" + entry.value)
      //     .join("&")
    );
    return finalUri;
  }

  /// Returns a list of departures for a global station id, with an optional limit and offset
  Future<List<Departure>> getDepartures(StationID globalId,
      {int limit = 20, int offsetInMinutes = 0}) async {
    // Referer varies
    var client = UserAgentClient.standard(referer: null);

    final response = await client.get(getUri(_departuresEndpoint, {
      "globalId": globalId,
      "limit": limit.toString(),
      "offsetInMinutes": offsetInMinutes.toString(),
      "transportTypes": "UBAHN,TRAM,SBAHN,BUS,REGIONAL_BUS,BAHN"
    }));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map<Departure>((e) => getDepartureFromJson(e)).toList()
        ..sort((a, b) =>
            a.expectedDepartureTime.compareTo(b.expectedDepartureTime));
    } else {
      return [];
    }
  }

  // Calculates routes from a start and destination station id
  Future<List<TransportRoute>> getRoutesFromLocationInputs(
      SpecificLocationInput start, SpecificLocationInput destinationId,
      {DateTime? time,
      bool timeIsArrival = false,
      List<TransportType> transportTypes = TransportType.regularValues}) async {
    Map<String, String> queryParameters = {};

    if (start is LocationInputStation) {
      queryParameters
          .addAll({"originStationGlobalId": start.station.globalId ?? ""});
    } else if (start is LocationInputWithCoordinates) {
      queryParameters.addAll({
        "originLatitude":
            (start as LocationInputWithCoordinates).latitude.toString(),
        "originLongitude":
            (start as LocationInputWithCoordinates).longitude.toString()
      });
    }

    if (destinationId is LocationInputStation) {
      queryParameters.addAll(
          {"destinationStationGlobalId": destinationId.station.globalId ?? ""});
    } else if (destinationId is LocationInputWithCoordinates) {
      queryParameters.addAll({
        "destinationLatitude":
            (destinationId as LocationInputWithCoordinates).latitude.toString(),
        "destinationLongitude":
            (destinationId as LocationInputWithCoordinates).longitude.toString()
      });
    }

    if (time != null) {
      queryParameters.addAll({
        "routingDateTime": time.toUtc().toIso8601String(),
        "routingDateTimeIsArrival": timeIsArrival.toString(),
      });
    }
    queryParameters.addAll({
      "transportTypes": transportTypes
          .where((e) => e != TransportType.OTHER)
          .map((t) => t.name)
          .join(","),
    });

    Uri uri = getUri(_routesEndpoint, queryParameters);
    var client = UserAgentClient.standard();

    final response = await client.get(
      uri,
    );

    if (response.statusCode == 200) {
      final routes = jsonDecode(response.body);
      if (routes is List == false || routes.isEmpty) {
        return [];
      }
      var result = <TransportRoute>[];
      for (var route in routes) {
        try {
          var parts = <RoutingPart>[];
          for (var part in route['parts']) {
            int? delayDefault = part["realTime"] == true ? 0 : null;
            final origin = RoutingPoint(
                station:
                    getStationFromJson(part['from'] as Map<String, dynamic>),
                plannedDeparture:
                    DateTime.parse(part["from"]["plannedDeparture"]),
                delay: part["from"]["departureDelayInMinutes"] ?? delayDefault,
                stopPositionNumber:
                    part["departureStopPositionNumber"]?.toString(),
                platform: part["from"]["platform"]?.toString(),
                platformChanged: part["from"]["platformChanged"] as bool?);
            final destination = RoutingPoint(
                station: getStationFromJson(part['to'] as Map<String, dynamic>),
                plannedDeparture:
                    DateTime.parse(part["to"]["plannedDeparture"]),
                delay: part["to"]["arrivalDelayInMinutes"] ?? delayDefault,
                stopPositionNumber:
                    part["arrivalStopPositionNumber"]?.toString(),
                platform: part["to"]["platform"]?.toString(),
                platformChanged: part["to"]["platformChanged"] as bool?);
            List<RoutingPoint> intermediateStops = (part["intermediateStops"]
                    as List)
                .map<RoutingPoint>((stop) => RoutingPoint(
                    station: getStationFromJson(stop as Map<String, dynamic>),
                    plannedDeparture: DateTime.parse(stop["plannedDeparture"]),
                    delay: stop["arrivalDelayInMinutes"] ??
                        stop["departureDelayInMinutes"] ??
                        delayDefault,
                    stopPositionNumber: stop["stopPositionNumber"]?.toString(),
                    platform: stop["platform"]?.toString(),
                    platformChanged: stop["platformChanged"] as bool?))
                .toList();
            Line line = getLineFromJson(part["line"] as Map<String, dynamic>);
            String? occupancyString = part["occupancy"];
            var occupancy = parseOccupancyString(occupancyString);
            var coordinates = decodePolyline(part["pathPolyline"]);
            var interchangeCoordinates =
                decodePolyline(part["interchangePathPolyline"]);
            double? distance = part["distance"] as double?;
            String? exitLetter = part["exitLetter"] as String?;
            parts.add(RoutingPart(
              from: origin,
              to: destination,
              intermediateStops: intermediateStops,
              line: line,
              occupancy: occupancy,
              coordinates: coordinates
                  ?.map((e) => CoordinatePair(e[0] * 1.0, e[1] * 1.0))
                  .toList(),
              interchangeCoordinates: interchangeCoordinates
                  ?.map((e) => CoordinatePair(e[0] * 1.0, e[1] * 1.0))
                  .toList(),
              distance: distance,
              exitLetter: exitLetter,
              tickers: ((part["infos"] as List?) ?? [])
                  .map<Ticker>((ticker) => Ticker(
                      title: ticker["message"],
                      type: switch (ticker["type"]) {
                        "INCIDENT" ||
                        "EARLY_TERMINATION" =>
                          TickerType.disruption,
                        _ => TickerType.planned
                      },
                      isExternal: true))
                  .toList(),
            ));
          }
          var zones = (route["ticketingInformation"]['zones'] as List)
              .map<String>((zone) => zone.toString())
              .toList();
          result.add(TransportRoute(
              parts: parts,
              distance: route['distance'] as double,
              zones: zones));
        } on FormatException catch (e) {
          debugPrint("Skipped route $e");
        }
      }
      return result;
    } else {
      throw Exception(
          'Failed to calculate route: ${response.statusCode} $uri ${response.body} }');
    }
  }

  Future<(TransportRoute route, bool manuallyStitchedParts)?> getUpdatedRoute(
      TransportRoute oldRoute) async {
    var locationInputFrom = oldRoute.parts.first.from.station.isRealStation()
        ? LocationInputStation(oldRoute.parts.first.from.station)
        : LocationInputAddress(
            oldRoute.parts.first.from.station.name ?? "",
            oldRoute.parts.first.from.station.place ?? "",
            oldRoute.parts.first.from.station.latitude ?? 0,
            oldRoute.parts.first.from.station.longitude ?? 0);
    var locationInputTo = oldRoute.parts.last.to.station.isRealStation()
        ? LocationInputStation(oldRoute.parts.last.to.station)
        : LocationInputAddress(
            oldRoute.parts.last.to.station.name ?? "",
            oldRoute.parts.last.to.station.place ?? "",
            oldRoute.parts.last.to.station.latitude ?? 0,
            oldRoute.parts.last.to.station.longitude ?? 0);
    var routes = await getRoutesFromLocationInputs(
        locationInputFrom, locationInputTo,
        time: oldRoute.plannedDeparture,
        transportTypes: oldRoute.parts
            .map((part) => part.line.transportType ?? TransportType.OTHER)
            .where((e) => e != TransportType.OTHER)
            .toList());
    for (var newRoute in routes) {
      if (newRoute.parts.length != oldRoute.parts.length) {
        continue;
      }
      bool matches = true;
      for (var i = 0; i < newRoute.parts.length; i++) {
        var newPart = newRoute.parts[i];
        var oldPart = oldRoute.parts[i];
        if (!newPart.from.equalsStationAndPlannedDeparture(oldPart.from) ||
            !newPart.to.equalsStationAndPlannedDeparture(oldPart.to) ||
            newPart.line != oldPart.line) {
          matches = false;
          break;
        }
      }
      if (matches) {
        return (newRoute, false);
      }
    }
    // No matching route found
    List<RoutingPart> newParts = [];
    for (var oldPart in oldRoute.parts) {
      //TODO parallelize
      var newRoutesForPart = await getRoutesFromLocationInputs(
          LocationInputStation(oldPart.from.station),
          LocationInputStation(oldPart.to.station),
          time: oldPart.from.plannedDeparture,
          transportTypes: oldPart.line.transportType == null
              ? TransportType.regularValues
              : [oldPart.line.transportType!]);

      bool matches = false;
      for (var newRoute in newRoutesForPart) {
        if (newRoute.parts.length != 1) {
          continue;
        }
        var newPart = newRoute.parts[0];

        if (!newPart.from.equalsStationAndPlannedDeparture(oldPart.from) ||
            !newPart.to.equalsStationAndPlannedDeparture(oldPart.to) ||
            newPart.line != oldPart.line) {
          continue;
        } else {
          matches = true;
          newParts.add(newPart);
          break;
        }
      }
      if (!matches) {
        //Found not match for this part
        return null;
      }
    }
    return (TransportRoute(parts: newParts, distance: 0, zones: []), true);
  }

  /// Returns a list of ticker messages (incidents and planned), sorted by priority and line.
  Future<List<Ticker>?> getTickers(
      {bool onlyIncidents = false, bool useFib = false}) async {
    http.Response response;
    try {
      var client = UserAgentClient.standard(
          referer: "https://www.mvg.de/verbindungen/betriebsmeldungen.html");
      response = await client.get(useFib
          ? getUri(_messagesEndpoint,
              onlyIncidents ? {"messageTypes": "INCIDENT"} : {})
          : Uri.parse('$_baseUrlApi/ems/tickers'));
    } on Exception {
      return null;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      var allTickers = List<Ticker>.from(data.map((ticker) => useFib
          ? getTickerfromFIBJson(ticker)
          : getTickerfromEMSJson(ticker)));
      allTickers.sort((a, b) {
        //TODO: reuse this sorting method on tickerpage

        // Sort disruptions before planned
        if (a.type == TickerType.disruption && b.type == TickerType.planned) {
          return -1;
        }
        if (a.type == TickerType.planned && b.type == TickerType.disruption) {
          return 1;
        }
        if (a.eventTypes.length != b.eventTypes.length) {
          // If one has more events, sort it first (typically there will only be 1 or 0 event types)
          return -1 * a.eventTypes.length.compareTo(b.eventTypes.length);
        }
        if (a.lines.isEmpty) {
          return -1;
        } else {
          if (b.lines.isEmpty) {
            return 1;
          }

          final aMinTransportTypeOrder = a.lines
              .map((e) => TransportType.transportTypeOrder(e.type))
              .reduce((value, element) => min(value, element));
          final bMinTransportTypeOrder = b.lines
              .map((e) => TransportType.transportTypeOrder(e.type))
              .reduce((value, element) => min(value, element));
          if (aMinTransportTypeOrder != bMinTransportTypeOrder) {
            return aMinTransportTypeOrder.compareTo(bMinTransportTypeOrder);
          }
          final intRegex = RegExp(r'[^\d]*(\d+)[^\d]*');
          var lineNumberA = int.tryParse(a.lines.first.name) ??
              int.tryParse(intRegex.firstMatch(a.lines.first.name)?.group(1) ??
                  a.lines.first.name);
          var lineNumberB = int.tryParse(b.lines.firstOrNull?.name ?? "") ??
              int.tryParse(intRegex.firstMatch(b.lines.first.name)?.group(1) ??
                  b.lines.first.name);
          if (lineNumberA != null && lineNumberB != null) {
            // Compare numerical lines
            return lineNumberA.compareTo(lineNumberB);
          }
          return a.lines.first.name.compareTo(b.lines.firstOrNull?.name ?? "");
        }
      });

      if (onlyIncidents) {
        return allTickers
            .where((element) => element.type == TickerType.disruption)
            .toList();
      } else {
        return allTickers;
      }
    } else {
      return null;
    }
  }

  Future<StationAccessibilityData?> getStationAccessibilityData(
      StationID stationId) async {
    http.Response response;
    try {
      var client = UserAgentClient.standard(
          referer:
              "https://www.mvg.de/ueber-die-mvg/unser-engagement/barrierefreiheit/zoom.html");
      response = await client.get(
        // URL + "/map" returns the corresponding "map" image
        Uri.parse("https://www.mvg.de/.rest/mvgZoom/api/stations/$stationId"),
      );
      final data = jsonDecode(response.body);
      return getStationDevicesDataFromJson(data);
    } on Exception {
      return null;
    }
  }

  String getStationAccessibilityMapUrl(StationID stationId) {
    // The map url is not included in the api response, but can be constructed from the station id
    return 'https://www.mvg.de/.rest/mvgZoom/api/stations/$stationId/map';
  }

  /// Returns a Station object with some properties filled (notably abbreviation)
  /// that are missing from other endpoints.
  Future<Station?> getStationInfo(StationID globalId) async {
    // Referer varies
    var client = UserAgentClient.standard(referer: null);

    var uri = Uri(
      scheme: "https",
      host: "www.mvg.de",
      path: ".rest/zdm/stations/$globalId",
    );
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return getStationFromZDMJSON(data);
    } else {
      return null;
    }
  }

  Future<List<TickerLine>?> getLines(StationID globalId) async {
    // Referer varies
    var client = UserAgentClient.standard(referer: null);

    var uri = getUri("lines/$globalId", {});
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Set<TickerLine>.from(
          data.map<TickerLine>((e) => getTickerLinefromFIBJson(e))).toList()
        ..sort((TickerLine a, TickerLine b) {
          if (TransportType.transportTypeOrder(a.type) !=
              TransportType.transportTypeOrder(b.type)) {
            return TransportType.transportTypeOrder(a.type)
                .compareTo(TransportType.transportTypeOrder(b.type));
          }
          return a.name.compareTo(b.name);
        });
    } else {
      return null;
    }
  }

  /// Returns a list of departures for a global station id, with an optional limit and offset
  Future<List<ScheduleOrMap>?> getScheduleAndMaps(String abbreviation) async {
    // Referer varies
    var client = UserAgentClient.standard(referer: null);

    var uri = Uri(
        scheme: "https",
        host: "www.mvg.de",
        path: ".rest/aushang/stations",
        queryParameters: {"id": abbreviation});
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return getSchedulesAndMapsFromJson(data);
    } else {
      return null;
    }
  }
}

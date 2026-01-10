import 'dart:async';
import 'package:transport/api/munich_api.dart';
import 'package:transport/datamodel/station_devices.dart';
import 'package:transport/datamodel/station_postings.dart';
import 'package:transport/datamodel/transport_type.dart';

import '../datamodel/departures.dart';
import '../datamodel/routes.dart';
import '../datamodel/station.dart';
import '../datamodel/tickers.dart';
import '../datamodel/location_input_model.dart';

class TransitDataRepository {
  MunichApiClient apiClient = MunichApiClient();
  final Map<StationID, Future<List<TickerLine>?>> _linesCache = {};

  Future<List<Ticker>?> getTickers({bool onlyIncidents = false}) async {
    return apiClient.getTickers(onlyIncidents: onlyIncidents, useFib: true);
  }

  Future<List<Departure>> getDepartures(StationID globalId,
      {int limit = 20, int offsetInMinutes = 0}) async {
    return apiClient.getDepartures(globalId,
        limit: limit, offsetInMinutes: offsetInMinutes);
  }

  Future<List<TransportRoute>> getRoutesFromLocationInputs(
      SpecificLocationInput origin, SpecificLocationInput destination,
      {DateTime? time,
      bool timeIsArrival = false,
      List<TransportType> transportTypes = TransportType.regularValues}) async {
    return apiClient.getRoutesFromLocationInputs(origin, destination,
        time: time,
        timeIsArrival: timeIsArrival,
        transportTypes: transportTypes);
  }

  Future<(TransportRoute route, bool manuallyStitchedParts)?> getUpdatedRoute(
      TransportRoute oldRoute) async {
    return apiClient.getUpdatedRoute(oldRoute);
  }

  Future<Station?> getStationInfo(StationID globalId) async {
    return apiClient.getStationInfo(globalId);
  }

  Future<List<TickerLine>?> getLines(StationID globalId) async {
    if (_linesCache.containsKey(globalId)) {
      return _linesCache[globalId];
    }
    var result = await apiClient.getLines(globalId);
    if (result != null) {
      _linesCache[globalId] = Future.value(result);
    }
    return result;
  }

  Future<List<ScheduleOrMap>?> getScheduleAndMaps(Station station) async {
    Future<List<ScheduleOrMap>?> surroundingPlanFuture;
    var surroundingPlanLink = station.surroundingPlanLink;
    if (surroundingPlanLink != null) {
      surroundingPlanFuture = apiClient.getScheduleAndMaps(surroundingPlanLink);
    } else {
      surroundingPlanFuture = Future.value(null);
    }

    var stationAbbreviationFuture = Future<List<ScheduleOrMap>?>.value(null);

    if (station.globalId != null) {
      // We retrieve the station info. Then, if the abbreviation is actually
      // different from the surroundingPlanLink, we get the correct schedules,
      // but keep the map from surroundingPlanLink. (This happens for some
      // stations which are close to a "big" station and have no separate map.)
      var stationResult =
          await apiClient.getStationInfo(station.globalId!); //.then((station) {
      if (stationResult != null) {
        if (stationResult.abbreviation != surroundingPlanLink &&
            stationResult.abbreviation != null) {
          stationAbbreviationFuture =
              apiClient.getScheduleAndMaps(stationResult.abbreviation!);
        }
      }
    }

    final (surroundingPlanResult, stationAbbreviationResult) =
        await (surroundingPlanFuture, stationAbbreviationFuture).wait;
    return [
      ...?stationAbbreviationResult,
      ...?surroundingPlanResult?.whereType<StationOrOverviewMap>()
    ];
  }

  Future<StationAccessibilityData?> getStationAccessibilityData(
      Station station) async {
    return apiClient.getStationAccessibilityData(station.divaId.toString());
  }

  String getStationAccessibilityMapUrl(Station station) {
    return apiClient.getStationAccessibilityMapUrl(station.divaId.toString());
  }
}

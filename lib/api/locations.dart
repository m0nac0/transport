import 'dart:convert';

import 'package:transport/api/munich_api.dart';
import 'package:transport/datamodel/station.dart';
import 'package:transport/api/user_agent.dart';

import '../datamodel/location_input_model.dart';

const String _locationsEndpoint = 'locations';
const String _nearbyStationsEndpoint = "stations/nearby";

/// Returns a single station for a String query
Future<Station?> getSingleStation(String query) async {
  final result = await getLocations(query, stationsOnly: true);
  return result.whereType<LocationInputStation>().firstOrNull?.station;
}

List<ResolvedLocationInput> mapJsonLocationsToResolvedLocationInputs(
    List data) {
  return data
      .map<ResolvedLocationInput?>((e) => switch (e['type']) {
            "STATION" => LocationInputStation(Station.fromJson(e)),
            "ADDRESS" => LocationInputAddress(
                e["name"], e["place"], e["latitude"], e["longitude"]),
            "POI" => LocationInputPoi(
                e["name"], e["place"], e["latitude"], e["longitude"]),
            _ => null
          })
      .nonNulls
      .toList();
}

/// Returns a list of LocationInputs for a String query
Future<List<ResolvedLocationInput>> getLocations(String query,
    {bool stationsOnly = false}) async {
  var client = UserAgentClient.standard();
  Uri finalUri = MunichApiClient.getUri(_locationsEndpoint,
      {"query": query, if (stationsOnly) "locationTypes": "STATION"});
  final response = await client.get(
    finalUri,
  );
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return mapJsonLocationsToResolvedLocationInputs(data);
  } else {
    return [];
  }
}

/// Returns a list of nearby LocationInputs for a location
Future<List<ResolvedLocationInput>?> getNearbyLocations(
    double latitude, double longitude,
    {bool stationsOnly = false}) async {
  var client = UserAgentClient.standard();

  Uri finalUri = MunichApiClient.getUri(_nearbyStationsEndpoint,
      {"latitude": latitude.toString(), "longitude": longitude.toString()});
  final response = await client.get(
    finalUri,
  );
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data
        .map((jsonDict) => LocationInputStation(Station.fromJson(jsonDict)))
        .toList();
  } else {
    return null;
  }
}

Future<Station?> getStationFromLocationInput(
    LocationInput locationResult) async {
  if (locationResult is LocationInputStation) {
    return locationResult.station;
  } else {
    return await getSingleStation(locationResult.toLocationString());
  }
}

Future<SpecificLocationInput?> getSpecificLocationInputFromLocationInput(
    LocationInput locationInput) async {
  if (locationInput is SpecificLocationInput) {
    return locationInput;
  } else if (locationInput is LocationInputString) {
    return (await getLocations(locationInput.string)).firstOrNull;
  } else if (locationInput is LocationInputCurrentLocationLoading) {
    //TODO show an indicator that we are waiting for the position
    var position = await locationInput.position;
    if (position == null) {
      return null;
    } else {
      return LocationInputCurrentLocation(position.$1, position.$2);
    }
  } else {
    return null;
  }
}

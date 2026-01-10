import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport/datamodel/routes.dart';
import 'package:transport/datamodel/transport_type.dart';

/// Note that the SettingsModel will initially not expose the correct values,
/// until the initialize method has completed!
class SettingsProvider extends ChangeNotifier {
  static const String _serializationKey = "settings";
  late SharedPreferences prefs;
  bool _initialized = false;

  SettingsProvider() {
    initialize();
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    prefs = await SharedPreferences.getInstance();
    _sbahnEnabled =
        prefs.getBool("${_serializationKey}_sbahnEnabled") ?? _sbahnEnabled;
    _ubahnEnabled =
        prefs.getBool("${_serializationKey}_ubahnEnabled") ?? _ubahnEnabled;
    _busEnabled =
        prefs.getBool("${_serializationKey}_busEnabled") ?? _busEnabled;
    _tramEnabled =
        prefs.getBool("${_serializationKey}_tramEnabled") ?? _tramEnabled;
    _zugEnabled =
        prefs.getBool("${_serializationKey}_zugEnabled") ?? _zugEnabled;
    _routeMainPage_showStations =
        prefs.getBool("${_serializationKey}_routeMainPage_showStations") ??
            _routeMainPage_showStations;
    _showOccupancyIndicators =
        prefs.getBool("${_serializationKey}_showOccupancyIndicators") ??
            _showOccupancyIndicators;
    _showAnimatedDelay =
        prefs.getBool("${_serializationKey}_showAnimatedDelay") ??
            _showAnimatedDelay;
    _developerMode =
        prefs.getBool("${_serializationKey}_developerMode") ?? _developerMode;
    _jsonLogsEnabled = prefs.getBool("${_serializationKey}_jsonLogsEnabled") ??
        _jsonLogsEnabled;
    _defaultMapHeight =
        prefs.getDouble("${_serializationKey}_defaultMapHeight") ??
            _defaultMapHeight;
    _useLocalStyle =
        prefs.getBool("${_serializationKey}_useLocalStyle") ?? _useLocalStyle;
    await _updateMapTilePathForFilename(
        prefs.getString("${_serializationKey}_mapTilePath"));
    _initialized = true;
    notifyListeners();
  }

  List<TransportType> getEnabledTransportTypes() {
    return [
      TransportType.SCHIFF,
      TransportType.RUFTAXI,
      if (zugEnabled) TransportType.BAHN,
      if (ubahnEnabled) TransportType.UBAHN,
      if (tramEnabled) TransportType.TRAM,
      if (sbahnEnabled) TransportType.SBAHN,
      if (busEnabled) TransportType.BUS,
      if (busEnabled) TransportType.REGIONAL_BUS,
    ];
  }

  bool _sbahnEnabled = true;

  bool get sbahnEnabled => _sbahnEnabled;

  set sbahnEnabled(bool newValue) {
    _sbahnEnabled = newValue;
    prefs.setBool("${_serializationKey}_sbahnEnabled", newValue);
    notifyListeners();
  }

  bool _ubahnEnabled = true;

  bool get ubahnEnabled => _ubahnEnabled;

  set ubahnEnabled(bool newValue) {
    _ubahnEnabled = newValue;
    prefs.setBool("${_serializationKey}_ubahnEnabled", newValue);
    notifyListeners();
  }

  bool _busEnabled = true;

  bool get busEnabled => _busEnabled;

  set busEnabled(bool newValue) {
    _busEnabled = newValue;
    prefs.setBool("${_serializationKey}_busEnabled", newValue);
    notifyListeners();
  }

  bool _tramEnabled = true;

  bool get tramEnabled => _tramEnabled;

  set tramEnabled(bool newValue) {
    _tramEnabled = newValue;
    prefs.setBool("${_serializationKey}_tramEnabled", newValue);
    notifyListeners();
  }

  bool _zugEnabled = true;

  bool get zugEnabled => _zugEnabled;

  set zugEnabled(bool newValue) {
    _zugEnabled = newValue;
    prefs.setBool("${_serializationKey}_zugEnabled", newValue);
    notifyListeners();
  }

  bool _routeMainPage_showStations = false;

  bool get routeMainPage_showStations => _routeMainPage_showStations;

  set routeMainPage_showStations(bool newValue) {
    _routeMainPage_showStations = newValue;
    prefs.setBool("${_serializationKey}_routeMainPage_showStations", newValue);
    notifyListeners();
  }

  bool _showOccupancyIndicators = true;

  bool get showOccupancyIndicators => _showOccupancyIndicators;

  set showOccupancyIndicators(bool newValue) {
    _showOccupancyIndicators = newValue;
    prefs.setBool("${_serializationKey}_showOccupancyIndicators", newValue);
    notifyListeners();
  }

  bool _showAnimatedDelay = false;
  bool get showAnimatedDelay => _showAnimatedDelay;
  set showAnimatedDelay(bool newValue) {
    _showAnimatedDelay = newValue;
    prefs.setBool("${_serializationKey}_showAnimatedDelay", newValue);
    notifyListeners();
  }

  bool _developerMode = false;

  bool get developerMode => _developerMode;

  set developerMode(bool newValue) {
    _developerMode = newValue;
    prefs.setBool("${_serializationKey}_developerMode", newValue);
    notifyListeners();
  }

  bool _jsonLogsEnabled = false;

  bool get jsonLogsEnabled => _jsonLogsEnabled;

  set jsonLogsEnabled(bool newValue) {
    _jsonLogsEnabled = newValue;
    prefs.setBool("${_serializationKey}_jsonLogsEnabled", newValue);
    notifyListeners();
  }

  bool _useLocalStyle = false;

  bool get useLocalStyle => _useLocalStyle;

  set useLocalStyle(bool newValue) {
    _useLocalStyle = newValue;
    prefs.setBool("${_serializationKey}_useLocalStyle", newValue);
    notifyListeners();
  }

  double _defaultMapHeight = 200;

  double get defaultMapHeight => _defaultMapHeight;

  set defaultMapHeight(double newValue) {
    _defaultMapHeight = newValue;
    prefs.setDouble("${_serializationKey}_defaultMapHeight", newValue);
    notifyListeners();
  }

  String? _mapTilePath;

  String? get mapTilePath => _mapTilePath;

  set mapTilePath(String? newValue) {
    var serializationKeyPath = "${_serializationKey}_mapTilePath";
    if (newValue != null) {
      //Copy file to app dir
      String fileName = p.basename(newValue);
      getApplicationSupportDirectory().then((dir) {
        String savePath = p.join(dir.path, fileName);
        File(newValue).copy(savePath).then((newFile) async {
          prefs.setString(serializationKeyPath, fileName);
          await _updateMapTilePathForFilename(fileName);
          notifyListeners();
        });
      });
    } else {
      prefs.remove(serializationKeyPath);
      notifyListeners();
    }
  }

  Future<void> _updateMapTilePathForFilename(String? fileName) async {
    // set file from (current) app dir and file name
    // Required because iOS will change the directory on app updates (but move contents)
    if (fileName != null) {
      var dir = await getApplicationSupportDirectory();
      String savePath = p.join(dir.path, fileName);
      _mapTilePath = savePath;
    }
  }
}

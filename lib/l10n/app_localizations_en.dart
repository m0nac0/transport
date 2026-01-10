// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get connection => 'Connection';

  @override
  String get station => 'Station';

  @override
  String get route => 'Route';

  @override
  String get routes => 'Routes';

  @override
  String get departures => 'Departures';

  @override
  String get incidents => 'Incidents';

  @override
  String get more => 'More';

  @override
  String get letsGo => 'Let\'s go!';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get now => 'Now';

  @override
  String get lastUpdate => 'Last update: ';

  @override
  String get back => 'Back';

  @override
  String get departuresFromHere => 'Departures from here';

  @override
  String get walkingTimeToStation => 'Your walking time to the station';

  @override
  String get done => 'Done';

  @override
  String inMinutes(Object minutes) {
    return 'in $minutes Min.';
  }

  @override
  String get errorLoadingStation => 'Error loading station';

  @override
  String get detailsForStation => 'Details for station';

  @override
  String get routeNotFoundManualUpdate =>
      'Route not found! Parts were manually updated; connections may be unreachable.';

  @override
  String get routeUpdated => 'Route updated!';

  @override
  String get undo => 'Undo';

  @override
  String get routeUpdateFailed => 'Unable to update route!';

  @override
  String timeLabel(Object minutes) {
    return 'Time: $minutes Min.';
  }

  @override
  String get platform => 'Platform';

  @override
  String get timetablesAndMap => 'Timetables & local map';

  @override
  String get delete => 'Delete';

  @override
  String get departure => 'Departure';

  @override
  String get arrival => 'Arrival';

  @override
  String get reset => 'Reset';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get waitingForLocalMapStyle => 'Waiting for local map style';

  @override
  String get routeCalcFailedUnknown =>
      'Route calculation failed: origin/destination unknown';

  @override
  String get routeCalcFailedNoRoutes =>
      'Route calculation failed: no routes found';

  @override
  String get routeShareFailed => 'Unable to prepare route for sharing';

  @override
  String get showMyLocation => 'Show my location';

  @override
  String get dontShowMyLocation => 'Don\'t show my location';

  @override
  String get currentlyEnabled => 'Currently enabled';

  @override
  String get currentlyDisabled => 'Currently disabled';

  @override
  String get loading => 'Loading...';

  @override
  String get earlier => 'Earlier';

  @override
  String get later => 'Later';

  @override
  String get chooseColor => 'Choose color';

  @override
  String get chooseIcon => 'Choose icon';

  @override
  String get changeColor => 'Change color';

  @override
  String get symbol => 'Symbol';

  @override
  String get name => 'Name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get address => 'Address';

  @override
  String get enterAddressHint => 'Enter the address / station';

  @override
  String get save => 'Save';

  @override
  String get favoritesNote =>
      'Favorites are only saved locally on your device.\nLong press them to edit/delete them.';

  @override
  String get filterBy => 'Filter by: ';

  @override
  String get numberAbbrev => 'Nr.';

  @override
  String get search => 'Search...';

  @override
  String get noTitle => 'No title';

  @override
  String get transitTitle => 'Transit';

  @override
  String get swapStartDestination => 'Swap start and destination';

  @override
  String get transportModes => 'Transport modes';

  @override
  String get uBahn => 'U-Bahn';

  @override
  String get bus => 'Bus';

  @override
  String get tram => 'Tram';

  @override
  String get sBahn => 'S-Bahn';

  @override
  String get train => 'Train';

  @override
  String get userInterface => 'User interface';

  @override
  String get occupancyIndicator => 'Show occupancy indicator';

  @override
  String get animatedDelayInRoutesList =>
      'Animated delay indicator in routes list';

  @override
  String get maps => 'Maps';

  @override
  String get localMaps => 'Local maps';

  @override
  String chooseMapFile(Object path) {
    return 'Choose map file ($path selected)';
  }

  @override
  String get developerSettings => 'Developer settings';

  @override
  String get jsonLogs => 'JSON logs';

  @override
  String get noneChosen => 'None';

  @override
  String get map => 'Map';

  @override
  String get escalatorsElevators => 'Escalators and elevators';

  @override
  String get myLocation => 'My location';

  @override
  String get myLocationLoading => 'My location (loading)';

  @override
  String get myLocationFailed => 'My location (failed!)';

  @override
  String get routeDetails => 'Route Details';

  @override
  String get settings => 'Settings';

  @override
  String get addFavorite => 'Add Favorite';

  @override
  String lineLabel(Object line) {
    return 'Line $line';
  }

  @override
  String footpathMinutes(Object minutes) {
    return 'Footpath $minutes Min.';
  }

  @override
  String get footpath => 'Footpath';

  @override
  String get incidentOnLine => 'Incident on this line';

  @override
  String departureArrival(Object departure, Object arrival) {
    return 'Departure $departure; Arrival $arrival';
  }

  @override
  String zonesLabel(Object zones) {
    return 'Zones: $zones';
  }

  @override
  String get noMapAvailable => 'No map available';

  @override
  String get overviewMap => 'Overview map';

  @override
  String get otherPlan => 'Other plan';

  @override
  String get unknownDirection => 'Unknown direction';

  @override
  String get lines => 'Lines';

  @override
  String minutesAgo(Object minutes) {
    return '$minutes min. ago';
  }

  @override
  String hoursAndMinutes(Object hours, Object minutes) {
    return '$hours:$minutes h';
  }

  @override
  String hoursAndMinutesAgo(Object hours, Object minutes) {
    return '$hours:$minutes h ago';
  }

  @override
  String get replacementService => 'Replacement service';

  @override
  String get notAvailable => 'n/a';

  @override
  String get deviceInService => 'In service';

  @override
  String get deviceUnknown => 'Unknown';

  @override
  String get deviceBroken => 'Out of service';

  @override
  String get locationHint => 'Stop, address, ...';

  @override
  String get controllerNullError => 'Controller is null';

  @override
  String errorLoadingStops(Object error) {
    return 'Error loading stops.geojson: $error';
  }

  @override
  String stopPointLabel(Object number) {
    return 'Stop point $number';
  }

  @override
  String durationLabel(Object duration) {
    return 'Duration $duration';
  }

  @override
  String exitLabel(Object exit) {
    return 'Exit $exit';
  }

  @override
  String loadMap(Object direction) {
    return '$direction load';
  }

  @override
  String get loadSuffix => 'load';
}

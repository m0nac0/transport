import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @station.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get station;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @routes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routes;

  /// No description provided for @departures.
  ///
  /// In en, this message translates to:
  /// **'Departures'**
  String get departures;

  /// No description provided for @incidents.
  ///
  /// In en, this message translates to:
  /// **'Incidents'**
  String get incidents;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get letsGo;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last update: '**
  String get lastUpdate;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @departuresFromHere.
  ///
  /// In en, this message translates to:
  /// **'Departures from here'**
  String get departuresFromHere;

  /// No description provided for @walkingTimeToStation.
  ///
  /// In en, this message translates to:
  /// **'Your walking time to the station'**
  String get walkingTimeToStation;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @inMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {minutes} Min.'**
  String inMinutes(Object minutes);

  /// No description provided for @errorLoadingStation.
  ///
  /// In en, this message translates to:
  /// **'Error loading station'**
  String get errorLoadingStation;

  /// No description provided for @detailsForStation.
  ///
  /// In en, this message translates to:
  /// **'Details for station'**
  String get detailsForStation;

  /// No description provided for @routeNotFoundManualUpdate.
  ///
  /// In en, this message translates to:
  /// **'Route not found! Parts were manually updated; connections may be unreachable.'**
  String get routeNotFoundManualUpdate;

  /// No description provided for @routeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Route updated!'**
  String get routeUpdated;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @routeUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update route!'**
  String get routeUpdateFailed;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time: {minutes} Min.'**
  String timeLabel(Object minutes);

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @timetablesAndMap.
  ///
  /// In en, this message translates to:
  /// **'Timetables & local map'**
  String get timetablesAndMap;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @departure.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get departure;

  /// No description provided for @arrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get arrival;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @waitingForLocalMapStyle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for local map style'**
  String get waitingForLocalMapStyle;

  /// No description provided for @routeCalcFailedUnknown.
  ///
  /// In en, this message translates to:
  /// **'Route calculation failed: origin/destination unknown'**
  String get routeCalcFailedUnknown;

  /// No description provided for @routeCalcFailedNoRoutes.
  ///
  /// In en, this message translates to:
  /// **'Route calculation failed: no routes found'**
  String get routeCalcFailedNoRoutes;

  /// No description provided for @routeShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to prepare route for sharing'**
  String get routeShareFailed;

  /// No description provided for @showMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Show my location'**
  String get showMyLocation;

  /// No description provided for @dontShowMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show my location'**
  String get dontShowMyLocation;

  /// No description provided for @currentlyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Currently enabled'**
  String get currentlyEnabled;

  /// No description provided for @currentlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Currently disabled'**
  String get currentlyDisabled;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlier;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @chooseColor.
  ///
  /// In en, this message translates to:
  /// **'Choose color'**
  String get chooseColor;

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose icon'**
  String get chooseIcon;

  /// No description provided for @changeColor.
  ///
  /// In en, this message translates to:
  /// **'Change color'**
  String get changeColor;

  /// No description provided for @symbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get symbol;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @enterAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the address / station'**
  String get enterAddressHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @favoritesNote.
  ///
  /// In en, this message translates to:
  /// **'Favorites are only saved locally on your device.\nLong press them to edit/delete them.'**
  String get favoritesNote;

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by: '**
  String get filterBy;

  /// No description provided for @numberAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Nr.'**
  String get numberAbbrev;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @noTitle.
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get noTitle;

  /// No description provided for @transitTitle.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get transitTitle;

  /// No description provided for @swapStartDestination.
  ///
  /// In en, this message translates to:
  /// **'Swap start and destination'**
  String get swapStartDestination;

  /// No description provided for @transportModes.
  ///
  /// In en, this message translates to:
  /// **'Transport modes'**
  String get transportModes;

  /// No description provided for @uBahn.
  ///
  /// In en, this message translates to:
  /// **'U-Bahn'**
  String get uBahn;

  /// No description provided for @bus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get bus;

  /// No description provided for @tram.
  ///
  /// In en, this message translates to:
  /// **'Tram'**
  String get tram;

  /// No description provided for @sBahn.
  ///
  /// In en, this message translates to:
  /// **'S-Bahn'**
  String get sBahn;

  /// No description provided for @train.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get train;

  /// No description provided for @userInterface.
  ///
  /// In en, this message translates to:
  /// **'User interface'**
  String get userInterface;

  /// No description provided for @occupancyIndicator.
  ///
  /// In en, this message translates to:
  /// **'Show occupancy indicator'**
  String get occupancyIndicator;

  /// No description provided for @animatedDelayInRoutesList.
  ///
  /// In en, this message translates to:
  /// **'Animated delay indicator in routes list'**
  String get animatedDelayInRoutesList;

  /// No description provided for @maps.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get maps;

  /// No description provided for @localMaps.
  ///
  /// In en, this message translates to:
  /// **'Local maps'**
  String get localMaps;

  /// No description provided for @chooseMapFile.
  ///
  /// In en, this message translates to:
  /// **'Choose map file ({path} selected)'**
  String chooseMapFile(Object path);

  /// No description provided for @developerSettings.
  ///
  /// In en, this message translates to:
  /// **'Developer settings'**
  String get developerSettings;

  /// No description provided for @jsonLogs.
  ///
  /// In en, this message translates to:
  /// **'JSON logs'**
  String get jsonLogs;

  /// No description provided for @noneChosen.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneChosen;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @escalatorsElevators.
  ///
  /// In en, this message translates to:
  /// **'Escalators and elevators'**
  String get escalatorsElevators;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @myLocationLoading.
  ///
  /// In en, this message translates to:
  /// **'My location (loading)'**
  String get myLocationLoading;

  /// No description provided for @myLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'My location (failed!)'**
  String get myLocationFailed;

  /// No description provided for @routeDetails.
  ///
  /// In en, this message translates to:
  /// **'Route Details'**
  String get routeDetails;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add Favorite'**
  String get addFavorite;

  /// No description provided for @lineLabel.
  ///
  /// In en, this message translates to:
  /// **'Line {line}'**
  String lineLabel(Object line);

  /// No description provided for @footpathMinutes.
  ///
  /// In en, this message translates to:
  /// **'Footpath {minutes} Min.'**
  String footpathMinutes(Object minutes);

  /// No description provided for @footpath.
  ///
  /// In en, this message translates to:
  /// **'Footpath'**
  String get footpath;

  /// No description provided for @incidentOnLine.
  ///
  /// In en, this message translates to:
  /// **'Incident on this line'**
  String get incidentOnLine;

  /// No description provided for @departureArrival.
  ///
  /// In en, this message translates to:
  /// **'Departure {departure}; Arrival {arrival}'**
  String departureArrival(Object departure, Object arrival);

  /// No description provided for @zonesLabel.
  ///
  /// In en, this message translates to:
  /// **'Zones: {zones}'**
  String zonesLabel(Object zones);

  /// No description provided for @noMapAvailable.
  ///
  /// In en, this message translates to:
  /// **'No map available'**
  String get noMapAvailable;

  /// No description provided for @overviewMap.
  ///
  /// In en, this message translates to:
  /// **'Overview map'**
  String get overviewMap;

  /// No description provided for @otherPlan.
  ///
  /// In en, this message translates to:
  /// **'Other plan'**
  String get otherPlan;

  /// No description provided for @unknownDirection.
  ///
  /// In en, this message translates to:
  /// **'Unknown direction'**
  String get unknownDirection;

  /// No description provided for @lines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get lines;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min. ago'**
  String minutesAgo(Object minutes);

  /// No description provided for @hoursAndMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}:{minutes} h'**
  String hoursAndMinutes(Object hours, Object minutes);

  /// No description provided for @hoursAndMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}:{minutes} h ago'**
  String hoursAndMinutesAgo(Object hours, Object minutes);

  /// No description provided for @replacementService.
  ///
  /// In en, this message translates to:
  /// **'Replacement service'**
  String get replacementService;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'n/a'**
  String get notAvailable;

  /// No description provided for @deviceInService.
  ///
  /// In en, this message translates to:
  /// **'In service'**
  String get deviceInService;

  /// No description provided for @deviceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get deviceUnknown;

  /// No description provided for @deviceBroken.
  ///
  /// In en, this message translates to:
  /// **'Out of service'**
  String get deviceBroken;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'Stop, address, ...'**
  String get locationHint;

  /// No description provided for @controllerNullError.
  ///
  /// In en, this message translates to:
  /// **'Controller is null'**
  String get controllerNullError;

  /// No description provided for @errorLoadingStops.
  ///
  /// In en, this message translates to:
  /// **'Error loading stops.geojson: {error}'**
  String errorLoadingStops(Object error);

  /// No description provided for @stopPointLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop point {number}'**
  String stopPointLabel(Object number);

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration {duration}'**
  String durationLabel(Object duration);

  /// No description provided for @exitLabel.
  ///
  /// In en, this message translates to:
  /// **'Exit {exit}'**
  String exitLabel(Object exit);

  /// No description provided for @loadMap.
  ///
  /// In en, this message translates to:
  /// **'{direction} load'**
  String loadMap(Object direction);

  /// No description provided for @loadSuffix.
  ///
  /// In en, this message translates to:
  /// **'load'**
  String get loadSuffix;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

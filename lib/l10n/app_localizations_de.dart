// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get connection => 'Verbindung';

  @override
  String get station => 'Haltestelle';

  @override
  String get route => 'Verbindung';

  @override
  String get routes => 'Verbindungen';

  @override
  String get departures => 'Abfahrten';

  @override
  String get incidents => 'Meldungen';

  @override
  String get more => 'Mehr';

  @override
  String get letsGo => 'Und los!';

  @override
  String get from => 'Ab';

  @override
  String get to => 'An';

  @override
  String get now => 'Jetzt';

  @override
  String get lastUpdate => 'Stand: ';

  @override
  String get back => 'Zurück';

  @override
  String get departuresFromHere => 'Abfahrten von hier';

  @override
  String get walkingTimeToStation => 'Ihre Gehzeit zur Haltestelle';

  @override
  String get done => 'Fertig';

  @override
  String inMinutes(Object minutes) {
    return 'in $minutes Min.';
  }

  @override
  String get errorLoadingStation => 'Fehler beim Laden der Station';

  @override
  String get detailsForStation => 'Details zur Station';

  @override
  String get routeNotFoundManualUpdate =>
      'Route wurde nicht mehr gefunden! Teile wurden manuell aktualisiert, Anschlüsse werden ggf. nicht erreicht!';

  @override
  String get routeUpdated => 'Route wurde aktualisiert!';

  @override
  String get undo => 'Rückgängig';

  @override
  String get routeUpdateFailed => 'Keine Aktualisierung der Route möglich!';

  @override
  String timeLabel(Object minutes) {
    return 'Zeit: $minutes Min.';
  }

  @override
  String get platform => 'Gleis';

  @override
  String get timetablesAndMap => 'Fahrpläne & Umgebungsplan';

  @override
  String get delete => 'Löschen';

  @override
  String get departure => 'Abfahrt';

  @override
  String get arrival => 'Ankunft';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get waitingForLocalMapStyle => 'Warte auf lokalen Kartenstil';

  @override
  String get routeCalcFailedUnknown =>
      'Routenberechnung fehlgeschlagen: Start/Ziel unbekannt';

  @override
  String get routeCalcFailedNoRoutes =>
      'Routenberechnung fehlgeschlagen: Keine Routen gefunden';

  @override
  String get routeShareFailed => 'Fehler beim Vorbereiten der Routenteilung';

  @override
  String get showMyLocation => 'Standort anzeigen';

  @override
  String get dontShowMyLocation => 'Standort nicht anzeigen';

  @override
  String get currentlyEnabled => 'Derzeit aktiviert';

  @override
  String get currentlyDisabled => 'Derzeit deaktiviert';

  @override
  String get loading => 'Lädt ...';

  @override
  String get earlier => 'Früher';

  @override
  String get later => 'Später';

  @override
  String get chooseColor => 'Farbe wählen';

  @override
  String get chooseIcon => 'Symbol wählen';

  @override
  String get changeColor => 'Farbe ändern';

  @override
  String get symbol => 'Symbol';

  @override
  String get name => 'Name';

  @override
  String get enterYourName => 'Geben Sie Ihren Namen ein';

  @override
  String get address => 'Adresse';

  @override
  String get enterAddressHint => 'Geben Sie die Adresse / Haltestelle ein';

  @override
  String get save => 'Speichern';

  @override
  String get favoritesNote =>
      'Favoriten werden nur lokal auf Ihrem Gerät gespeichert.\nLanges Drücken, um sie zu bearbeiten/löschen.';

  @override
  String get filterBy => 'Filtern nach: ';

  @override
  String get numberAbbrev => 'Nr.';

  @override
  String get search => 'Suchen...';

  @override
  String get noTitle => 'Kein Titel';

  @override
  String get transitTitle => 'Transit';

  @override
  String get swapStartDestination => 'Start und Ziel tauschen';

  @override
  String get transportModes => 'Verkehrsmittel';

  @override
  String get uBahn => 'U-Bahn';

  @override
  String get bus => 'Bus';

  @override
  String get tram => 'Tram';

  @override
  String get sBahn => 'S-Bahn';

  @override
  String get train => 'Zug';

  @override
  String get userInterface => 'Benutzeroberfläche';

  @override
  String get occupancyIndicator => 'Indikator für Fahrzeugbelegung anzeigen';

  @override
  String get animatedDelayInRoutesList =>
      'Animierte Verspätungsanzeige in Routenliste';

  @override
  String get maps => 'Karten';

  @override
  String get localMaps => 'Lokale Karten';

  @override
  String chooseMapFile(Object path) {
    return 'Kartendatei wählen ($path gewählt)';
  }

  @override
  String get developerSettings => 'Entwicklereinstellungen';

  @override
  String get jsonLogs => 'JSON logs';

  @override
  String get noneChosen => 'Keine';

  @override
  String get map => 'Karte';

  @override
  String get escalatorsElevators => 'Aufzüge und Rolltreppen';

  @override
  String get myLocation => 'Mein Standort';

  @override
  String get myLocationLoading => 'Mein Standort (lädt)';

  @override
  String get myLocationFailed => 'Mein Standort (Fehler!)';

  @override
  String get routeDetails => 'Verbindungsdetails';

  @override
  String get settings => 'Einstellungen';

  @override
  String get addFavorite => 'Favorit hinzufügen';

  @override
  String lineLabel(Object line) {
    return 'Linie $line';
  }

  @override
  String footpathMinutes(Object minutes) {
    return 'Fußweg $minutes Min.';
  }

  @override
  String get footpath => 'Fussweg';

  @override
  String get incidentOnLine => 'Störung auf dieser Linie';

  @override
  String departureArrival(Object departure, Object arrival) {
    return 'Abfahrt $departure; Ankunft $arrival';
  }

  @override
  String zonesLabel(Object zones) {
    return 'Zonen: $zones';
  }

  @override
  String get noMapAvailable => 'Keine Karte verfügbar';

  @override
  String get overviewMap => 'Übersichtskarte';

  @override
  String get otherPlan => 'Sonstiger Plan';

  @override
  String get unknownDirection => 'Unbekannte Richtung';

  @override
  String get lines => 'Linien';

  @override
  String minutesAgo(Object minutes) {
    return 'vor $minutes Min.';
  }

  @override
  String hoursAndMinutes(Object hours, Object minutes) {
    return '$hours:$minutes Std.';
  }

  @override
  String hoursAndMinutesAgo(Object hours, Object minutes) {
    return 'vor $hours:$minutes Std.';
  }

  @override
  String get replacementService => 'Schienenersatzverkehr';

  @override
  String get notAvailable => 'k. A.';

  @override
  String get deviceInService => 'In Betrieb';

  @override
  String get deviceUnknown => 'Unbekannt';

  @override
  String get deviceBroken => 'Außer Betrieb';

  @override
  String get locationHint => 'Haltestelle, Adresse, ...';

  @override
  String get controllerNullError => 'Controller ist null';

  @override
  String errorLoadingStops(Object error) {
    return 'Fehler beim Laden von stops.geojson: $error';
  }

  @override
  String stopPointLabel(Object number) {
    return 'Haltepunkt $number';
  }

  @override
  String durationLabel(Object duration) {
    return 'Dauer $duration';
  }

  @override
  String exitLabel(Object exit) {
    return 'Ausgang $exit';
  }

  @override
  String loadMap(Object direction) {
    return '$direction laden';
  }

  @override
  String get loadSuffix => 'laden';
}

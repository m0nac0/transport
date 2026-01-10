import 'package:transport/datamodel/routes.dart';
import 'package:transport/datamodel/tickers.dart';
import 'package:transport/datamodel/transport_type.dart';

/// A message delivered by the API that is similar to a ticker message, but only delivered for individual trains by the departures endpoint.
enum InfoType {
  incident,
  info,
  other;

  static InfoType fromString(String string) {
    return InfoType.values.firstWhere((e) => e.name == string.toLowerCase(),
        orElse: () => InfoType.other);
  }
}

class Info {
  final String message;
  final InfoType type;

  Info({
    required this.message,
    required this.type,
  });
}

class Departure {
  final DateTime plannedDepartureTime;
  final bool realtime;
  final int? delayInMinutes;
  final DateTime expectedDepartureTime;
  final TransportType? transportType;
  final String? label;

  /// Sometimes the API may return a very long label (e.g. "LUFTHANSA EXPRESS BUS"), then we provide a shortLabel (e.g. "LH")
  final String? shortLabel;
  final String? divaId;
  final String? network;
  final String? trainType;
  final String? destination;
  final bool? cancelled;
  final bool? sev;
  final String? platform;
  final bool? isPlatformChanged;

  /// e.g. if the route is unexpectedly shortened for a specific vehicle
  final List<Info>? infoMessages;
  final String? bannerHash;
  final Occupancy? occupancy;
  final String? stopPointGlobalId;
  final String? stopPositionNumber;
  List<Ticker> tickers;

  bool get isCancelled => cancelled ?? false;

  /// Shows the label and prepends the train type if available (e.g. ICE)
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

  Departure(
      {required this.plannedDepartureTime,
      this.realtime = false,
      this.delayInMinutes,
      required this.expectedDepartureTime,
      this.transportType,
      this.label,
      this.shortLabel,
      this.divaId,
      this.network,
      this.trainType,
      this.destination,
      this.cancelled,
      this.sev,
      this.platform,
      this.isPlatformChanged,
      this.infoMessages,
      this.bannerHash,
      this.occupancy,
      this.stopPointGlobalId,
      this.stopPositionNumber,
      this.tickers = const []});
}

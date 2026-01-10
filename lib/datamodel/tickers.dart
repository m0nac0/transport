import 'package:transport/datamodel/departures.dart';
import 'package:transport/datamodel/routes.dart';
import 'package:transport/datamodel/transport_type.dart';

class TickerLine {
  final String name;
  final TransportType type;
  late String network;
  final bool? sev;

  TickerLine({
    required this.name,
    required this.type,
    String network = "swm",
    this.sev,
  }){
    this.network = network.toLowerCase();
  }

  TickerLine.fromDeparture(Departure e)
      : name = e.displayLabel,
        type = e.transportType ?? TransportType.OTHER,
        network = e.network?.toLowerCase() ?? "swm",
        sev = e.sev;

  @override
  bool operator ==(Object other) {
    if (other is TickerLine) {
      return name == other.name &&
          type == other.type &&
          network.toLowerCase() == other.network.toLowerCase() &&
          sev == other.sev;
    }
    return false;
  }

  @override
  int get hashCode =>
      name.hashCode + type.hashCode + network.hashCode + sev.hashCode;

  @override
  String toString() {
    return 'TickerLine{name: $name, type: $type, network: $network, sev: $sev}';
  }
}

enum TickerType { disruption, planned }

//TODO find out about others
enum EventType {
  bus({TransportType.BUS, TransportType.REGIONAL_BUS}),
  stammstrecke ({TransportType.SBAHN}),
  tram ({TransportType.TRAM}),
  ubahn ({TransportType.UBAHN}),
  fussball ({}),
  other({});

  final Set<TransportType> concernedTransportTypes;
  const EventType(this.concernedTransportTypes);
}

class Link {
  final Uri uri;
  final String title;

  Link(this.uri, this.title);
}

class Ticker {
  final String? id;
  final String? title;
  final String? text;
  final TickerType? type;
  final List<TickerLine> lines;
  final DateTime? incidentStart;
  final DateTime? incidentEnd;
  final DateTime? activeStart;
  final DateTime? activeEnd;
  final List<EventType> eventTypes;
  final List<Link> links;

  /// For ticker messages that are supplied during routing e.g. for long-distance
  /// trains and for which we don't have details and which are not returned by
  /// the tickers API.
  final bool isExternal;

  Ticker(
      {this.id,
      this.title,
      this.text,
      this.type,
      this.lines = const [],
      this.incidentStart,
      this.incidentEnd,
      this.activeStart,
      this.activeEnd,
      this.eventTypes = const [],
      this.links = const [],
      this.isExternal = false});

  List<Ticker> splitByLines() {
    if (lines.isEmpty) {
      return [this];
    }
    var linesMap = <String, Ticker>{};
    for (var line in lines) {
      if (linesMap.containsKey(line.name)) {
        linesMap[line.name]!.lines.add(line);
      } else {
        linesMap[line.name] = Ticker(
            id: id,
            title: title,
            text: text,
            type: type,
            lines: [line],
            incidentStart: incidentStart,
            incidentEnd: incidentEnd,
            activeStart: activeStart,
            activeEnd: activeEnd,
            eventTypes: eventTypes,
            links: links);
      }
    }
    return linesMap.values.toList();
  }

  static Map<String?, List<Ticker>> groupByLines(List<Ticker> tickers) {
    var linesMap = <String?, List<Ticker>>{};
    for (var ticker in tickers) {
      if (ticker.lines.isEmpty) {
        if (linesMap.containsKey(null)) {
          linesMap[null]!.add(ticker);
        } else {
          linesMap[null] = [ticker];
        }
      }
      for (var line in ticker.lines) {
        var lineName = line.name;
        if (linesMap.containsKey(lineName)) {
          if (!linesMap[lineName]!.contains(ticker)) {
            linesMap[lineName]!.add(ticker);
          }
        } else {
          linesMap[lineName] = [ticker];
        }
      }
    }

    return linesMap;
  }

  @override
  String toString() {
    return 'Ticker{id: $id, title: $title, text: $text, type: $type, lines: $lines, incidentStart: $incidentStart, incidentEnd: $incidentEnd, activeStart: $activeStart, activeEnd: $activeEnd, eventTypes: $eventTypes, links: $links, isExternal: $isExternal}';
  }
}

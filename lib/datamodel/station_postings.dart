import 'package:transport/datamodel/routes.dart';
import 'package:transport/datamodel/transport_type.dart';

abstract class ScheduleOrMap {
  Uri uri;
  String? direction;

  ScheduleOrMap(this.uri, this.direction);
}

class Schedule extends ScheduleOrMap {
  String? name;
  TransportType type;

  Schedule(Uri uri, this.name, this.type, String direction)
      : super(uri, direction);
}

abstract class StationOrOverviewMap extends ScheduleOrMap {
  StationOrOverviewMap(Uri uri, String? direction) : super(uri, direction);
}

class StationMap extends StationOrOverviewMap {
  StationMap(Uri uri, String direction) : super(uri, direction);
}

class OverviewMap extends StationOrOverviewMap {
  OverviewMap(Uri uri, String direction) : super(uri, direction);
}
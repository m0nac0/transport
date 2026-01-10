class StationAccessibilityData{
  final List<DeviceData> devices;
  final bool hasOutOfOrderEscalator;
  final bool hasOutOfOrderElevator;

  const StationAccessibilityData(this.devices, this.hasOutOfOrderElevator, this.hasOutOfOrderEscalator);
}

class DeviceData{
  final String? id;
  final DeviceType type;
  final DeviceStatus status;
  final String? description;
  final DateTime? lastUpdate;
  final int? xCoordinate;
  final int? yCoordinate;

  DeviceData(this.id, this.type, this.status, this.description, this.lastUpdate, this.xCoordinate, this.yCoordinate);
}

enum DeviceType{ escalator, elevator, other}
enum DeviceStatus {ok, unknown, broken}
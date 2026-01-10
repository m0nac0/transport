// ignore_for_file: constant_identifier_names

enum TransportType {
  SCHIFF,
  RUFTAXI,
  BAHN,
  UBAHN,
  SBAHN,
  TRAM,
  BUS,
  REGIONAL_BUS,
  OTHER;

  static TransportType fromString(String string) {
    return TransportType.values.firstWhere(
        (e) => e.name == string.toUpperCase(),
        orElse: () => TransportType.OTHER);
  }

  static TransportType? fromStringOrNull(String? string) {
    if (string == null) {
      return null;
    }
    return TransportType.values.firstWhere(
        (e) => e.name == string.toUpperCase(),
        orElse: () => TransportType.OTHER);
  }

  /// All "real" values (excludes OTHER)
  static const List<TransportType> regularValues = [
    SCHIFF,
    RUFTAXI,
    BAHN,
    UBAHN,
    TRAM,
    SBAHN,
    BUS,
    REGIONAL_BUS,
  ];

  static int transportTypeOrder(TransportType? type) {
    switch (type) {
      case TransportType.UBAHN:
        return 1;
      case TransportType.SBAHN:
        return 2;
      case TransportType.TRAM:
        return 3;
      case TransportType.BUS:
        return 4;
      case TransportType.REGIONAL_BUS:
        return 5;
      case TransportType.BAHN:
        return 6;
      default:
        return 7;
    }
  }
}

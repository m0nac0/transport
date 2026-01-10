import 'package:transport/datamodel/station.dart';

/// Stores a single item of a recent stations/connections list on the main screen.
class RecentsListItem<T extends IdEquality>
    implements Comparable<RecentsListItem<T>> {
  final T item;
  final bool favorite;
  final DateTime lastUse;

  RecentsListItem(this.item, this.favorite, this.lastUse);

  toJson(Map<String, dynamic> Function(T) serialize) {
    return {
      'item': serialize(item),
      'favorite': favorite,
      'lastUse': lastUse.millisecondsSinceEpoch,
    };
  }

  static RecentsListItem<S>? fromJson<S extends IdEquality>(
      Map<String, dynamic> json,
      S? Function(Map<String, dynamic>) unserialize) {
    var item = unserialize(json['item']);
    if (item == null) {
      return null;
    }
    return RecentsListItem(item, json['favorite'],
        DateTime.fromMillisecondsSinceEpoch(json['lastUse']));
  }

  // First compare by favorite status, then by lastUse
  @override
  int compareTo(RecentsListItem<T> other) {
    if (favorite && !other.favorite) return -1;
    if (!favorite && other.favorite) return 1;
    return (-1) * lastUse.compareTo(other.lastUse);
  }

  bool itemEquals(RecentsListItem<T> other) {
    return item.equalById(other.item);
  }
}

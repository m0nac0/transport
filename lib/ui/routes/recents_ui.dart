import 'package:flutter/material.dart';
import 'package:transport/data/recents.dart';
import 'package:transport/datamodel/location_input_model.dart';
import 'package:transport/datamodel/station.dart';
import 'package:transport/l10n/app_localizations.dart';
import 'package:transport/ui/util/colors.dart';

class RecentStationsList extends StatelessWidget {
  final RecentsListProvider<Station> previousStations;
  final void Function(Station) onTap;

  const RecentStationsList({
    super.key,
    required this.previousStations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Theme.of(context).colorScheme.surfaceBright,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListenableBuilder(
            listenable: previousStations,
            builder: (context, _) => ListView.separated(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final listItem = previousStations.values.elementAt(index);
                  final station = listItem.item;
                  var isFavorite = listItem.favorite;
                  return SingleFavoriteConnectionRow(
                    station.name ?? "",
                    station.place ?? "",
                    null,
                    null,
                    onTap: () => onTap(station),
                    onDismissed: () => previousStations.remove(listItem),
                    onFavoriteToggle: () =>
                        previousStations.toggleFavorite(listItem),
                    favorite: isFavorite,
                  );
                },
                separatorBuilder: (context, index) => const Divider(
                      color: darkGrey,
                      height: 5,
                      thickness: 0.5,
                    ),
                itemCount: previousStations.values.length),
          ),
        ),
      ),
    );
  }
}

/// One row of a recent/favorite connection
class SingleFavoriteConnectionRow extends StatelessWidget {
  final String startStation;
  final String startPlace;
  final String? endStation;
  final String? endPlace;
  final void Function() onTap;
  final void Function() onDismissed;
  final void Function() onFavoriteToggle;
  final bool favorite;

  const SingleFavoriteConnectionRow(
      this.startStation, this.startPlace, this.endStation, this.endPlace,
      {super.key,
      required this.onTap,
      required this.onDismissed,
      required this.favorite,
      required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    var placeTextStyle = TextStyle(color: Colors.grey[700], fontSize: 13);
    return Dismissible(
      direction: DismissDirection.endToStart,
      key: Key(startStation.toString() +
          (endStation?.toString() ?? "null") +
          favorite.toString()),
      onDismissed: (_) => onDismissed(),
      background: ColoredBox(
        color: Colors.red,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.white),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.delete, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
        child: SizedBox(
          height: endStation == null ? 30 : null,
          child: SingleFavoriteRow(
            favorite: favorite,
            onFavoriteToggle: onFavoriteToggle,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        startStation,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(" "),
                      Text(
                        startPlace,
                        style: placeTextStyle,
                      ),
                    ],
                  ),
                  if (endStation != null)
                    Wrap(
                      children: [
                        Text(
                          endStation!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(" "),
                        Text(
                          endPlace ?? "",
                          style: placeTextStyle,
                        ),
                      ],
                    ),
                ]),
          ),
        ),
      ),
    );
  }
}

class SingleFavoriteRow extends StatelessWidget {
  final Widget child;
  final void Function() onFavoriteToggle;
  final bool favorite;

  const SingleFavoriteRow(
      {super.key,
      required this.child,
      required this.onFavoriteToggle,
      required this.favorite});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
        child: child,
      ),
      IconButton(
          onPressed: onFavoriteToggle,
          padding: const EdgeInsets.all(0),
          icon: Icon(
            favorite ? Icons.star : Icons.star_outline,
            color: darkGrey,
            size: 32,
          )),
    ]);
  }
}

class PreviousConnection implements IdEquality {
  final SpecificLocationInput start;
  final SpecificLocationInput end;

  const PreviousConnection(
    this.start,
    this.end,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviousConnection &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode + 2 * end.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'start': start.toJson(),
      'end': end.toJson(),
    };
  }

  static PreviousConnection? fromJson(Map<String, dynamic> json) {
    var start = SpecificLocationInput.getFromJson(json['start']);
    var end = SpecificLocationInput.getFromJson(json['end']);
    if (start == null || end == null) {
      debugPrint(
          "SpecificLocationInput deserialization failed${start?.toString() ?? ""}${end?.toString() ?? ""}");
      return null;
    }
    return PreviousConnection(
      start,
      end,
    );
  }

  @override
  bool equalById(Object other) {
    return other is PreviousConnection &&
        start.equalById(other.start) &&
        end.equalById(other.end);
  }
}

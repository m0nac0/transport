
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transport/datamodel/recents_list_item.dart';
import 'package:transport/ui/routes/recents_ui.dart';
import 'package:transport/ui/util/colors.dart';
import 'package:transport/datamodel/station.dart';
import 'package:transport/ui/components/green_button_row.dart';
import 'package:transport/ui/components/header.dart';

import '../../api/locations.dart';
import '../../datamodel/location_input_model.dart';
import '../components/location_input_ui.dart';
import '../../data/recents.dart';
import 'departures_details.dart';
import 'package:transport/l10n/app_localizations.dart';

class Departures extends StatefulWidget {
  const Departures({super.key});

  @override
  State<Departures> createState() => _DeparturesState();
}

class _DeparturesState extends State<Departures> {
  LocationInput? locationResult;
  int offsetInMinutes = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(title: AppLocalizations.of(context)!.departures),
        InputRow(
          initialResult: locationResult,
          onInput: (locationResult) => setState(() {
            this.locationResult = locationResult;
          }),
          hint: AppLocalizations.of(context)!.from,
          backgroundColor: Theme.of(context).colorScheme.surfaceBright,
          stationsOnly: true,
          currentLocation: false,
        ),
        const Divider(height: 1),
        TextButton(
          onPressed: () {
            showModalBottomSheet(
                context: context,
                builder: (context) => DepartureOffsetPicker(
                      offsetInMinutes: offsetInMinutes,
                      onOffsetChanged: (newOffset) => setState(() {
                        offsetInMinutes = newOffset;
                      }),
                    ));
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onBackground,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.schedule),
              Container(
                width: 10,
              ),
              Text(offsetInMinutes == 0
                  ? AppLocalizations.of(context)!.now
                  : AppLocalizations.of(context)!.inMinutes(offsetInMinutes)),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          child: GreenButtonRow(
              text: AppLocalizations.of(context)!.letsGo,
              onPressed: () async {
                if (locationResult == null) {
                  return;
                }
                var station =
                    await getStationFromLocationInput(locationResult!);
                if (station != null && station.globalId != null) {
                  if (context.mounted) {
                    context
                        .read<RecentsListProvider<Station>>()
                        .add(RecentsListItem(station, false, DateTime.now()));
                    Navigator.of(context).pushNamed("/singleDepartures",
                        arguments: SingleStationDeparturesArguments(
                            station, offsetInMinutes));
                  }
                }
              }),
        ),
        RecentStationsList(
            previousStations: context.watch<RecentsListProvider<Station>>(),
            onTap: (station) => setState(() {
                  locationResult = LocationInputStation(station);
                })),
      ],
    );
  }
}


/// Shows a picker to select the offset in minutes for the departures list
class DepartureOffsetPicker extends StatelessWidget {
  DepartureOffsetPicker(
      {super.key,
      required this.offsetInMinutes,
      required this.onOffsetChanged});
  final minutes = List<int>.generate(60, (i) => i);
  final int offsetInMinutes;
  final Function(int) onOffsetChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          Container(
            color: blueBg,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.walkingTimeToStation,
                      style: const TextStyle(
                          color: Colors.white, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  TextButton(
                    child: Text(
                      AppLocalizations.of(context)!.done,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              looping: true,
              itemExtent: 32,
              scrollController: FixedExtentScrollController(
                initialItem: offsetInMinutes,
              ),
              onSelectedItemChanged: (int selectedItem) {
                onOffsetChanged(minutes[selectedItem]);
              },
              children: List<Widget>.generate(minutes.length, (int index) {
                return Center(child: Text(minutes[index].toString()));
              }),
            ),
          ),
        ],
      ),
    );
  }
}

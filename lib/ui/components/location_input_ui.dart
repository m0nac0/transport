import 'package:flutter/foundation.dart';
import 'package:transport/ui/components/animated_clear_button.dart';
import 'package:transport/ui/components/custom_button_like.dart';
import 'package:transport/ui/favorites/favorite_buttons.dart';
import 'package:transport/ui/util/map_transport_type_to_widget.dart';
import 'package:transport/ui/util/zip.dart';
import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';

import 'package:transport/l10n/app_localizations.dart';

import '../../api/locations.dart';
import '../../datamodel/station.dart';
import '../util/colors.dart';
import '../../datamodel/location_input_model.dart';

/// Textfield for start and destination
class InputRow extends StatefulWidget {
  final void Function(LocationInput?) onInput;
  final LocationInput? initialResult;
  final String hint;
  final Color backgroundColor;
  final void Function()? onTapHint;
  final bool stationsOnly;
  final bool currentLocation;

  const InputRow(
      {super.key,
      required this.onInput,
      required this.initialResult,
      required this.hint,
      required this.currentLocation,
      this.backgroundColor = white,
      this.onTapHint,
      this.stationsOnly = false});

  @override
  State<InputRow> createState() => _InputRowState();
}

class _InputRowState extends State<InputRow> {
  VoidCallback? listener;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final initialLocationTextStyle = TextStyle(
        color: widget.initialResult == null ? darkGrey : null,
        fontWeight: widget.initialResult != null ? FontWeight.bold : null,
        fontSize: 14);
    return Container(
      color: widget.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: (kReleaseMode &&
                (Platform.isLinux || Platform.isMacOS || Platform.isWindows))
            // On desktop platforms, we show a textfield with an autocomplete
            // Every time the user types a character, selects an autocomplete option
            // or fills the input from the recents/favorites list, the textfield is rebuilt.
            ? Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: TextButton(
                      onPressed: () => widget.onTapHint?.call(),
                      child: Text(
                        widget.hint,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Autocomplete<Station>(
                      onSelected: (Station station) {
                        widget.onInput(LocationInputStation(station));
                      },
                      displayStringForOption: (Station station) =>
                          station.name ?? "",
                      optionsBuilder: (textEditingValue) async {
                        final stations = (await getLocations(
                                textEditingValue.text,
                                stationsOnly: true))
                            .whereType<LocationInputStation>()
                            .map((e) => (e).station);
                        return stations;
                      },
                      fieldViewBuilder: (context, textEditingController,
                          focusNode, onFieldSubmitted) {
                        if (listener != null) {
                          textEditingController.removeListener(listener!);
                        }
                        textEditingController.value = TextEditingValue(
                            text:
                                widget.initialResult?.toLocationString() ?? "");
                        listener = () {
                          var locationResult =
                              LocationInputString(textEditingController.text);
                          widget.onInput(locationResult);
                        };
                        textEditingController.addListener(listener!);
                        return TextFormField(
                          focusNode: focusNode,
                          onFieldSubmitted: (String string) {
                            onFieldSubmitted();
                            var locationResult = LocationInputString(string);
                            widget.onInput(locationResult);
                          },
                          controller: textEditingController,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.locationHint,
                                hintStyle: TextStyle(fontWeight: FontWeight.normal),
                                border: InputBorder.none,
                              ),
                        );
                      },
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: TextButton(
                      onPressed: () => widget.onTapHint?.call(),
                      child: Text(
                        widget.hint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomButtonLike(
                      child: Container(
                        height: 40,
                        alignment: Alignment.centerLeft,
                        child: widget.initialResult
                                is LocationInputCurrentLocationLoading
                            ? FutureBuilder(
                                future: (widget.initialResult
                                        as LocationInputCurrentLocationLoading)
                                    .position
                                        .then<String?>(
                                          (_) => context.mounted
                                            ? AppLocalizations.of(context)!
                                              .myLocation
                                            : null,
                                          onError: (_) => context.mounted
                                            ? AppLocalizations.of(context)!
                                              .myLocationFailed
                                            : null),
                                builder: (BuildContext context,
                                    AsyncSnapshot<String?> snapshot) {
                                  return Text(
                                      switch (snapshot.connectionState) {
                                        ConnectionState.waiting =>
                                          AppLocalizations.of(context)!
                                              .myLocationLoading,
                                        _ => snapshot.data ??
                                            AppLocalizations.of(context)!
                                                .notAvailable
                                      },
                                      style: initialLocationTextStyle);
                                },
                              )
                            : 
                          Text(
                                widget.initialResult == null
                                        ? AppLocalizations.of(context)!.locationHint
                                    : widget.initialResult!.toLocationString(),
                                style: initialLocationTextStyle),
                      ),
                      onTap: () async {
                        final LocationInput? newStation =
                            await InputSheet.openInputSheetForController(
                                context,
                                TextEditingController(
                                    text: widget.initialResult
                                        ?.toLocationString()),
                                widget.stationsOnly,
                                widget.currentLocation);
                        setState(() {
                          widget.onInput(newStation);
                        });
                      },
                    ),
                  ),
                  IconButton(
                    splashRadius: 1,
                    icon: const Icon(
                      Icons.place_outlined,
                      color: darkGrey,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
      ),
    );
  }
}

class InputSheet extends StatefulWidget {
  const InputSheet({
    super.key,
    required this.controller,
    required this.stationsOnly,
    required this.currentLocation,
  });

  final TextEditingController controller;
  final bool stationsOnly;
  final bool currentLocation;

  @override
  State<InputSheet> createState() => _InputSheetState();

  static Future<LocationInput?> openInputSheetForController(
      BuildContext context,
      TextEditingController controller,
      bool stationsOnly,
      bool currentLocation) async {
    final newStation = (await showModalBottomSheet<LocationInput>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: InputSheet(
                  controller: controller,
                  stationsOnly: stationsOnly,
                  currentLocation: currentLocation));
        }));
    return newStation;
  }
}

class _InputSheetState extends State<InputSheet> {
  String currentInput = " ";
  List<ResolvedLocationInput> currentStations = [];

  @override
  void initState() {
    super.initState();

    widget.controller.selection = TextSelection(
        baseOffset: 0, extentOffset: widget.controller.text.length);
    callback() async {
      if (currentInput != widget.controller.text) {
        final String input = widget.controller.text;
        final stations =
            await getLocations(input, stationsOnly: widget.stationsOnly);
        if (mounted) {
          setState(() {
            currentStations = stations;
            currentInput = input;
          });
        }
      }
    }

    widget.controller.addListener(callback);
    callback();
    setState(() {
      currentInput = widget.controller.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: blueBg,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    controller: widget.controller,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                      hintStyle: const TextStyle(fontWeight: FontWeight.normal),
                      prefixIcon: const Icon(Icons.search),
                      prefixIconColor:
                          Theme.of(context).colorScheme.onBackground,
                      suffixIcon:
                          AnimatedClearButton(controller: widget.controller),
                      //suffixIconColor: Colors.grey,
                      hintText: AppLocalizations.of(context)!.locationHint,
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                      focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                      fillColor: Theme.of(context).colorScheme.background,
                      filled: true,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop<ResolvedLocationInput>(),
                  child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: TextStyle(color: white),
                    ),
                )
              ],
            ),
          ),
        ),
        if (widget.controller.text.isEmpty && !widget.stationsOnly)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FavoritesButtonsRow(
              onTap: (LocationInput e) =>
                  Navigator.of(context).pop<LocationInput>(e),
              currentLocation: widget.currentLocation,
            ),
          ),
        if ((widget.controller.text.isEmpty || currentStations.isEmpty) &&
            widget.stationsOnly)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FavoriteButton(
                icon: Icons.location_on,
                color: Colors.white,
                borderColor: Colors.black,
                onTap: () => loadNearbyStations(context)),
          ),
        Expanded(
          child: ListView.separated(
              itemBuilder: (context, index) {
                var currentStation = currentStations[index];
                return CustomButtonLike(
                    onTap: () {
                      Navigator.of(context)
                          .pop<ResolvedLocationInput>(currentStation);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(switch (currentStation.runtimeType) {
                            //TODO use better stop icon
                            LocationInputStation =>
                              Icons.directions_bus_outlined,
                            LocationInputAddress => Icons.house_outlined,
                            LocationInputPoi => Icons.place_outlined,
                            _ => Icons.place_outlined
                          }),
                          Container(
                            width: 8,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(currentStation.toLocationString()),
                              Text(
                                currentStation.getPlace() ?? "",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (currentStation is LocationInputStation)
                            ...zipWithPaddingWidget(
                              currentStation.station.transportTypes
                                      ?.map((type) =>
                                          mapTransportTypeToWidget(context, type, false))
                                      .toList() ??
                                  [],
                              const SizedBox(width: 4),
                            )

                          //TODO extend Row so entire row is clickable
                        ],
                      ),
                    ));
              },
              separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: darkGrey,
                  ),
              itemCount: currentStations.length),
        ),
      ],
    );
  }

  Future<void> loadNearbyStations(BuildContext context) async {
    var positionResult = await determinePositionOrShowSnackbar(context);
    if (positionResult != null) {
      var (lat, lng) = positionResult;
      var locations = await getNearbyLocations(lat, lng);
      if (locations != null) {
        setState(() {
          currentStations = locations;
        });
      }
    }
  }
}

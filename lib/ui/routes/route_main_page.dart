// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transport/data/settings_model.dart';
import 'package:transport/data/recents.dart';
import 'package:transport/datamodel/station.dart';

import 'package:transport/l10n/app_localizations.dart';
import 'package:transport/ui/components/custom_button_like.dart';
import 'package:transport/ui/components/green_button_row.dart';
import 'package:transport/ui/components/header.dart';
import 'package:transport/ui/routes/recents_ui.dart';
import 'package:transport/ui/routes/routes_list.dart';
import 'package:transport/ui/util/format_time.dart';

import '../util/colors.dart';
import '../../datamodel/location_input_model.dart';
import '../components/location_input_ui.dart';
import '../favorites/favorite_buttons.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  LocationInput? fromLocationInput;
  LocationInput? toLocationInput;
  DateTime? selectedDate;
  bool timeForDeparture = true;
  bool isFromInputSelected = true;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final greyBorder = BorderSide(width: 0.5, color: darkGrey);
    DateTime selectedDateOrNow = selectedDate ?? DateTime.now();
    return Consumer<SettingsProvider>(
        builder: (BuildContext context, SettingsProvider settings,
                Widget? child) =>
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Header(
                  title: AppLocalizations.of(context)!.transitTitle,
                  italic: true,
                  bold: true,
                  actions: [
                    (
                      Icons.settings,
                      () {
                        Navigator.pushNamed(context, "/settings");
                      }
                    )
                  ],
                ),
                InputRow(
                  onInput: (result) {
                    setState(() {
                      fromLocationInput = result;
                      isFromInputSelected = false;
                    });
                  },
                  initialResult: fromLocationInput,
                  hint: AppLocalizations.of(context)!.from,
                  backgroundColor: isFromInputSelected
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.background,
                  onTapHint: () {
                    setState(() {
                      isFromInputSelected = true;
                    });
                  },
                  currentLocation: true,
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                ),
                InputRow(
                  initialResult: toLocationInput,
                  onInput: (result) {
                    setState(() {
                      toLocationInput = result;
                    });
                  },
                  hint: AppLocalizations.of(context)!.to,
                  backgroundColor: isFromInputSelected
                      ? Theme.of(context).colorScheme.background
                      : Theme.of(context).colorScheme.surface,
                  onTapHint: () {
                    setState(() {
                      isFromInputSelected = false;
                    });
                  },
                  currentLocation: true,
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onBackground,
                      ),
                      onPressed: () async {
                        //  DateTime? picked = await showDatePicker(
                        //   context: context,
                        //   initialDate: selectedDate,
                        //   firstDate: DateTime(2015, 8),
                        //   lastDate: DateTime(2101),
                        // );
                        var result = await showCupertinoModalPopup<
                                (DateTime picked, bool now)?>(
                            useRootNavigator: false,
                            context: context,
                            builder: (_) {
                              DateTime? picked = selectedDate;
                              return Container(
                                height: 360,
                                color: Theme.of(context).colorScheme.background,
                                child: Column(
                                  children: [
                                    StatefulBuilder(
                                      builder: (context, innerSetState) =>
                                          Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CupertinoSegmentedControl<bool>(
                                          selectedColor: blueBg,
                                          // Provide horizontal padding around the children.
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          // This represents a currently selected segmented control.
                                          groupValue: timeForDeparture,
                                          // Callback that sets the selected segmented control.
                                          onValueChanged: (bool value) {
                                            innerSetState(() {
                                              timeForDeparture = value;
                                            });
                                            setState(() {
                                              timeForDeparture = value;
                                            });
                                          },
                                          children: <bool, Widget>{
                                            true: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20),
                                              child: Text(AppLocalizations.of(context)!.departure),
                                            ),
                                            false: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20),
                                              child: Text(AppLocalizations.of(context)!.arrival),
                                            ),
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 200,
                                      child: CupertinoDatePicker(
                                          use24hFormat: true,
                                          initialDateTime: picked,
                                          onDateTimeChanged: (val) {
                                            picked = val;
                                          }),
                                    ),
                                    TextButton(
                                      child: Text(AppLocalizations.of(context)!.reset),
                                      onPressed: () {
                                        // setState(() {
                                        //   selectedDate = null;
                                        // });
                                        Navigator.of(context)
                                            .pop((DateTime.now(), true));
                                      },
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        TextButton(
                                          child: Text(AppLocalizations.of(context)!.cancel),
                                          onPressed: () {
                                            // setState(() {
                                            //   selectedDate = null;
                                            // });
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        FilledButton(
                                          child: Text(AppLocalizations.of(context)!.ok),
                                          onPressed: () => Navigator.of(context)
                                              .pop((picked??DateTime.now(), picked==null)),
                                        )
                                      ],
                                    ),

                                    // Close the modal
                                  ],
                                ),
                              );
                            });
                        if (result != null) {
                          var (picked, now) = result;
                          setState(() {
                            if (now) {
                              selectedDate = null;
                            } else {
                              selectedDate = picked;
                            }
                          });
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          if (selectedDate == null)
                            Text(AppLocalizations.of(context)!.now)
                          else if (DateUtils.dateOnly(DateTime.now()) ==
                              DateUtils.dateOnly(selectedDateOrNow))
                            Text(formatOnlyTime(selectedDateOrNow),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                ))
                          else
                            Text('  ${formatDateTime(selectedDateOrNow)}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                )),
                        ],
                      ),
                    ),
                    ExcludeSemantics(
                      child: Text(
                        "|",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          var temp = fromLocationInput;
                          fromLocationInput = toLocationInput;
                          toLocationInput = temp;
                        });
                      },
                      icon: const Icon(
                        Icons.swap_vert_sharp,
                        semanticLabel: "",
                      ),
                      tooltip: AppLocalizations.of(context)!.swapStartDestination,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ],
                ),
                GreenButtonRow(
                  text: AppLocalizations.of(context)!.letsGo,
                  onPressed: () {
                    if (fromLocationInput != null && toLocationInput != null) {
                      Navigator.of(context).pushNamed("/routes",
                          arguments: RoutesListScreenArguments(
                              fromLocationInput!,
                              toLocationInput!,
                              selectedDateOrNow,
                              timeIsArrival: !timeForDeparture));
                    }
                  },
                ),
                //Tabs for Connection and Station
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: CustomButtonLike(
                          onTap: () => setState(() {
                                context
                                    .read<SettingsProvider>()
                                    .routeMainPage_showStations = false;
                              }),
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: settings.routeMainPage_showStations
                                  ? Theme.of(context).colorScheme.background
                                  : Theme.of(context).colorScheme.surfaceBright,
                              border: Border(
                                top: settings.routeMainPage_showStations
                                    ? BorderSide.none
                                    : greyBorder,
                                right: greyBorder,
                                bottom: !settings.routeMainPage_showStations
                                    ? BorderSide.none
                                    : greyBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)!.connection,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )),
                    ),
                    Expanded(
                      child: CustomButtonLike(
                          onTap: () => setState(() {
                                context
                                    .read<SettingsProvider>()
                                    .routeMainPage_showStations = true;
                              }),
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: settings.routeMainPage_showStations
                                  ? Theme.of(context).colorScheme.surfaceBright
                                  : Theme.of(context).colorScheme.background,
                              border: Border(
                                top: !settings.routeMainPage_showStations
                                    ? BorderSide.none
                                    : greyBorder,
                                bottom: settings.routeMainPage_showStations
                                    ? BorderSide.none
                                    : greyBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)!.station,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )),
                    ),
                  ],
                ),
                Container(
                  color: Theme.of(context).colorScheme.surfaceBright,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FavoritesButtonsRow(
                      onTap: (LocationInput locationInput) {
                        setState(() {
                          if (isFromInputSelected) {
                            setState(() {
                              fromLocationInput = locationInput;
                              isFromInputSelected = !isFromInputSelected;
                            });
                          } else {
                            setState(() {
                              toLocationInput = locationInput;
                            });
                          }
                        });
                      },
                      currentLocation: true,
                    ),
                  ),
                ),
                // List of previous connections
                // Expanded here is needed to allow the ListView to be scrollable
                if (!settings.routeMainPage_showStations)
                  Expanded(
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceBright,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Consumer<RecentsListProvider<PreviousConnection>>(
                          builder: (BuildContext context,
                                  RecentsListProvider<PreviousConnection>
                                      recentConnectionsList,
                                  Widget? child) =>
                              ListView.separated(
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    var listItem = recentConnectionsList.values
                                        .toList()[index];
                                    var startStation = listItem.item.start;
                                    var endStation = listItem.item.end;
                                    return SingleFavoriteConnectionRow(
                                      startStation.toLocationString(),
                                      startStation.getPlace() ?? "",
                                      endStation.toLocationString(),
                                      endStation.getPlace(),
                                      favorite: recentConnectionsList.values
                                          .toList()[index]
                                          .favorite,
                                      onFavoriteToggle: () =>
                                          recentConnectionsList
                                              .toggleFavorite(listItem),
                                      onTap: () {
                                        setState(() {
                                          fromLocationInput = startStation;
                                          toLocationInput = endStation;
                                        });
                                      },
                                      onDismissed: () => recentConnectionsList
                                          .remove(listItem),
                                    );
                                  },
                                  separatorBuilder: (context, index) => Divider(
                                        color: darkGrey,
                                        height: 12,
                                        thickness: 0.5,
                                      ),
                                  itemCount:
                                      recentConnectionsList.values.length),
                        ),
                      ),
                    ),
                  )
                else
                  RecentStationsList(
                      previousStations: context.watch<RecentsListProvider<Station>>(),
                      onTap: (station) {
                        setState(() {
                          if (isFromInputSelected) {
                            fromLocationInput = LocationInputStation(station);
                            isFromInputSelected = !isFromInputSelected;
                          } else {
                            toLocationInput = LocationInputStation(station);
                          }
                        });
                      }),

                // Only if we want to show routes here
                // routes != null
                //     ? Expanded(
                //         child: RoutesList(routes: routes))
                //     : const Text("No route")
              ],
            ));
  }
}

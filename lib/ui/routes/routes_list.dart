// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:flutter/material.dart' hide TickerProvider;
import 'package:provider/provider.dart';
import 'package:transport/data/munich_transit_data_repository.dart';
import 'package:transport/data/settings_model.dart';
import 'package:transport/data/ticker_provider.dart';
import 'package:transport/datamodel/recents_list_item.dart';
import 'package:transport/datamodel/station.dart';
import 'package:transport/datamodel/transport_type.dart';
import 'package:transport/packages/result.dart';
import 'package:transport/ui/routes/recents_ui.dart';
import 'package:transport/ui/util/colors.dart';
import 'package:transport/data/recents.dart';
import 'package:transport/ui/components/custom_button_like.dart';
import 'package:transport/ui/components/header.dart';
import 'package:transport/ui/components/right_arrow_icon.dart';
import 'package:transport/ui/routes/arrival_departure_time.dart';
import 'package:transport/ui/routes/route_details.dart';
import 'package:transport/l10n/app_localizations.dart';
import 'package:transport/ui/util/format_time.dart';
import 'package:transport/ui/util/map_transport_type_to_widget.dart';

import '../../api/locations.dart';
import '../../datamodel/departures.dart';
import '../../datamodel/routes.dart';
import '../../datamodel/tickers.dart';
import '../../datamodel/location_input_model.dart';

class RoutesListScreenArguments {
  final LocationInput from, to;
  final DateTime dateTime;
  final bool timeIsArrival;

  RoutesListScreenArguments(this.from, this.to, this.dateTime,
      {this.timeIsArrival = false});
}

class RoutesListScreen extends StatefulWidget {
  final RoutesListScreenArguments arguments;

  const RoutesListScreen({super.key, required this.arguments});

  @override
  State<RoutesListScreen> createState() => _RoutesListScreenState();
}

class APIException implements Exception {
  final String? message;

  APIException(this.message);

  @override
  String toString() => "APIException: $message";
}

class RoutesListViewModel extends ChangeNotifier {
  final TransitDataRepository transitDataRepository;
  final SettingsProvider settingsModel;
  final RecentsListProvider<PreviousConnection> recentConnections;
  final RecentsListProvider<Station> recentStations;
  final TickerProvider tickerProvider;
  // We save the from/to station.
  // This way we can keep displaying them when loading new routes.
  Station? fromStation;
  Station? toStation;
  LocationInput originInput;
  LocationInput destinationInput;
  DateTime dateTime;
  final bool timeIsArrival;
  // null means loading, value [] means loaded but no routes found, otherwise the list of routes
  Result<List<TransportRoute>>? routes;

  RoutesListViewModel(
      this.transitDataRepository,
      this.settingsModel,
      this.recentConnections,
      this.recentStations,
      this.tickerProvider,
      this.originInput,
      this.destinationInput,
      this.dateTime,
      this.timeIsArrival) {
    calculateRoutes();
  }

  Future<void> calculateRoutes() async {
    SpecificLocationInput? resolvedFrom =
        await getSpecificLocationInputFromLocationInput(originInput);
    SpecificLocationInput? resolvedTo =
        await getSpecificLocationInputFromLocationInput(destinationInput);
    if (resolvedFrom == null || resolvedTo == null) {
      routes = Result.error(
          APIException("At least one of the locations could not be resolved"));
      notifyListeners();
      return;
    }

    var routesFuture = transitDataRepository.getRoutesFromLocationInputs(
      resolvedFrom,
      resolvedTo,
      time: dateTime,
      timeIsArrival: timeIsArrival,
      transportTypes: settingsModel.getEnabledTransportTypes(),
    );

    var nonEmptyRoutes = await enhanceRoutesFuture(routesFuture);

    if (nonEmptyRoutes.isNotEmpty) {
      var newFirstRoute = nonEmptyRoutes.first;
      if (newFirstRoute.parts.isNotEmpty) {
        recentConnections.add(RecentsListItem<PreviousConnection>(
            PreviousConnection(resolvedFrom, resolvedTo),
            false,
            DateTime.now()));
        if (resolvedFrom is LocationInputStation) {
          recentStations.add(
              RecentsListItem(resolvedFrom.station, false, DateTime.now()));
        }
        if (resolvedTo is LocationInputStation) {
          recentStations
              .add(RecentsListItem(resolvedTo.station, false, DateTime.now()));
        }

        routes = Result.ok(nonEmptyRoutes);
        fromStation = newFirstRoute.parts.first.from.station;
        toStation = newFirstRoute.parts.last.to.station;
        notifyListeners();

        enhanceRoutesWithDepartures(nonEmptyRoutes).then((value) {
          routes = Result.ok(value);
          notifyListeners();
        });
      }
    } else {
      routes = Result.ok([]);
      notifyListeners();
    }
  }

  /// Enhances future routes by requesting incidents and line information and adding them
  /// to the routes where applicable.
  Future<List<TransportRoute>> enhanceRoutesFuture(
      Future<List<TransportRoute>> routes) async {
    var incidents = tickerProvider.getIncidents();
    return routes.then((routes) {
      var nonEmptyRoutes = enhanceRoutes(incidents, routes);
      return nonEmptyRoutes;
    });
  }

  /// Adds incident and line information to routes.
// TODO also add planned changes that are currently active
  static List<TransportRoute> enhanceRoutes(
      List<Ticker> incidents, List<TransportRoute> routes) {
    incidents = incidents.expand((element) => element.splitByLines()).toList();
    var nonEmptyRoutes =
        routes.where((element) => element.parts.isNotEmpty).toList();
    for (var route in nonEmptyRoutes) {
      for (var part in route.parts) {
        part.tickers = part.tickers +
            incidents
                .where((incident) =>
                    incident.lines.any((incidentLine) =>
                        incidentLine.name == part.line.label &&
                        incidentLine.network == part.line.network) ||
                    incident.eventTypes.any((eventType) =>
                        eventType.name.toLowerCase() ==
                        part.line.transportType?.name.toLowerCase()))
                .toList();
      }
    }
    return nonEmptyRoutes;
  }

  /// Enhances routes by requesting realtime departure information for each part
  Future<List<TransportRoute>> enhanceRoutesWithDepartures(
      List<TransportRoute> routes) async {
    // Create list of futures for all departure requests
    Map<String, Future<List<Departure>>> departureFuturesCache = {};
    var departureFutures = routes
        .expand((route) => route.parts.map((part) {
              var difference = part.from.expectedDeparture
                  .difference(DateTime.now())
                  .inMinutes;
              var stationGlobalId = part.from.station.globalId;
              if (stationGlobalId == null || difference < 0) {
                return Future.value(null);
              }
              if (departureFuturesCache.containsKey(stationGlobalId)) {
                return departureFuturesCache[stationGlobalId]!;
              } else {
                var departures = transitDataRepository.getDepartures(
                    stationGlobalId,
                    limit: 100,
                    offsetInMinutes: max(0, difference - 1));
                departureFuturesCache[stationGlobalId] = departures;
                return departures;
              }
            }))
        .toList();

    // Wait for all departure requests
    var departureResults = await Future.wait(departureFutures);

    // Index to track which departure result we're processing
    var resultIndex = 0;
    bool anyDiffered = false;
    bool anyAdditional = false;

    // Update each route part with matching departure information
    for (var route in routes) {
      var parts = route.parts;
      for (var i = 0; i < parts.length; i++) {
        var part = parts[i];
        if (part.line.label != "Fussweg") {
          var departures = departureResults[resultIndex];
          if (departures == null) {
            resultIndex++;
            continue;
          } else {
            // Find matching departure
            var matchingDeparture = departures
                .where((dep) =>
                    ((dep.divaId == part.line.divaId && dep.divaId != null) ||
                        (dep.label == part.line.label &&
                            dep.transportType == part.line.transportType &&
                            dep.trainType == part.line.trainType)) &&
                    dep.destination == part.line.destination &&
                    dep.plannedDepartureTime
                            .difference(part.from.plannedDeparture) <
                        Duration(seconds: 1))
                .firstOrNull;
            if (matchingDeparture == null &&
                part.line.transportType != TransportType.BAHN) {
              //TODO show alerts to the user; also if differing opinion on cancellation/SEV
              debugPrint(
                  'No matching departure found for ${part.line.transportType} ${part.line.displayLabel} from ${part.from.station.name}');
            }
            if (part.from.delay == null &&
                matchingDeparture?.delayInMinutes != null) {
              // Update delay information
              part = part.copyWith(
                  from: part.from
                      .copyWith(delay: matchingDeparture!.delayInMinutes));
              anyAdditional = true;
            }
            if (matchingDeparture != null &&
                part.from.delay != null &&
                part.from.delay != matchingDeparture.delayInMinutes) {
              anyDiffered = true;
              debugPrint(
                  'Found mismatching delays for ${part.line.transportType} ${part.line.displayLabel} from ${part.from.station.name}: part.from.delay=${part.from.delay}, matchingDeparture.delayInMinutes=${matchingDeparture.delayInMinutes}, plannedTime=${part.from.plannedDeparture.toIso8601String()}');
            }
            if (matchingDeparture != null &&
                (part.line.sev != matchingDeparture.sev ||
                    matchingDeparture.isCancelled)) {
              anyDiffered = true;
              debugPrint(
                  'Found mismatching cancellation/SEV for ${part.line.transportType} ${part.line.displayLabel} from ${part.from.station.name}: part.from.sev=${part.line.sev}, matchingDeparture.sev=${matchingDeparture.sev}, matchingDeparture.isCancelled=${matchingDeparture.isCancelled}');
            }
          }
        }
        parts[i] = part;
        resultIndex++;
      }
      route = route.copyWith(parts: parts);
    }
    if (anyDiffered || anyAdditional) {
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text('Found ${anyDiffered ? "differing" : ""} ${anyAdditional ? "additional" : ""} realtime data from departures than in routes'),
      //   duration: Duration(seconds: 30),
      // ));
    }
    return routes;
  }

  Future<void> refresh() async {
    dateTime = DateTime
        .now(); //TODO probably not correct when the user set a different time
    await calculateRoutes();
  }

  Future<void> getEarlierRoutes() async {
    dateTime = dateTime.subtract(Duration(minutes: 10));
    await calculateRoutes();
  }

  Future<void> getLaterRoutes() async {
    // If we have routes, take the departure/arrival of the last route, else just add 10 minutes
    if (routes is Ok<List<TransportRoute>> &&
        (routes as Ok<List<TransportRoute>>).value.isNotEmpty) {
      var routesValue = (routes as Ok<List<TransportRoute>>).value;
      var lastRoute = routesValue.lastOrNull;
      dateTime = (timeIsArrival
              ? lastRoute?.plannedArrival
              : lastRoute?.plannedDeparture) ??
          dateTime.add(Duration(minutes: 10));
      await calculateRoutes();
    } else {
      return;
    }
  }

  String? getRouteShareText(BuildContext context, int index) {
    if (routes == null ||
        routes is Error ||
        (routes as Ok<List<TransportRoute>>).value.length <= index) {
      return null;
    }
    final route = (routes as Ok<List<TransportRoute>>).value[index];
    final loc = AppLocalizations.of(context)!;
    final fromName = route.parts.first.from.station.name;
    final toName = route.parts.last.to.station.name;
    final zones = route.zones.map((e) => e == "0" ? "M" : e.toString()).join(",");
    String text =
        "${loc.route}: $fromName - $toName\n\n${formatOnlyDate(route.parts.first.from.expectedDeparture)} | ${loc.durationLabel("${route.totalMinutes} Min.")} | ${loc.zonesLabel(zones)}\n\n";
    for (var part in route.parts) {
      text +=
          "${formatOnlyTime(part.from.expectedDeparture)} ${part.from.station.name}\n";
      text += part.line.isWalk
          ? loc.footpathMinutes(part.totalMinutes.toString()) + "\n"
          : "${part.line.transportType?.name} ${part.line.displayLabel} ${loc.to} ${part.line.destination}\n";
      text +=
          "${formatOnlyTime(part.to.expectedDeparture)} ${part.to.station.name}\n\n";
    }
    return text;
  }
}

class _RoutesListScreenState extends State<RoutesListScreen> {
  late final RoutesListViewModel viewModel;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    viewModel = RoutesListViewModel(
        context.read<TransitDataRepository>(),
        context.read<SettingsProvider>(),
        context.read<RecentsListProvider<PreviousConnection>>(),
        context.read<RecentsListProvider<Station>>(),
        context.read<TickerProvider>(),
        widget.arguments.from,
        widget.arguments.to,
        widget.arguments.dateTime,
        widget.arguments.timeIsArrival);
    // calculateRoutes();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          title: AppLocalizations.of(context)!.routes,
          showBackButton: true,
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, oldWidget) => RefreshIndicator.adaptive(
                onRefresh: viewModel.refresh,
                child: RoutesList(
                  routes: viewModel.routes,
                  from: viewModel.fromStation,
                  to: viewModel.toStation,
                  onGetEarlierRoutes: viewModel.getEarlierRoutes,
                  onGetLaterRoutes: viewModel.getLaterRoutes,
                  onRouteTap: (index) {
                    Navigator.pushNamed(context, "/routeDetails",
                        arguments:
                            RouteDetailsScreenArguments(viewModel, index));
                  },
                )),
          ),
        ),
      ],
    );
  }
}

class RoutesList extends StatelessWidget {
  const RoutesList({
    super.key,
    required this.routes,
    required this.from,
    required this.to,
    required this.onGetEarlierRoutes,
    required this.onGetLaterRoutes,
    required this.onRouteTap,
  });

  final Result<List<TransportRoute>>? routes;
  final Station? from;
  final Station? to;
  final VoidCallback onGetEarlierRoutes;
  final VoidCallback onGetLaterRoutes;
  final Function(int) onRouteTap;

  //TODO: Idea: initially scroll the "earlier" button out of view
  // (needs a scrollController, possibly a jumpTo delayed slightly after routes != null the first time, and probably a large container at the end of the list to allow overscroll)
  //However: this does not easily work with the refreshindicator

  @override
  Widget build(BuildContext context) {
    var fromStation = from;
    var toStation = to;

    var fromName = fromStation?.name ?? "";
    var fromPlace = fromStation?.place ?? "";
    var toName = toStation?.name ?? "";
    var toPlace = toStation?.place ?? "";
    return Column(
      children: [
        Container(
          color: Theme.of(context).brightness == Brightness.light
              ? Theme.of(context).colorScheme.background
              : Theme.of(context).colorScheme.surface,
              child: Semantics(
                label: "${AppLocalizations.of(context)!.route} ${AppLocalizations.of(context)!.from} $fromName ${AppLocalizations.of(context)!.to} $toName ${toPlace.isNotEmpty ? toPlace : ''}",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fromName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        fromPlace,
                        style: TextStyle(
                            fontSize: 12, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.arrow_right),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        toPlace,
                        style: TextStyle(
                            fontSize: 12, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(
          thickness: 3,
          color: Colors.black,
        ),
        Builder(builder: (context) {
          switch (routes) {
            case null:
              return Center(child: Text(AppLocalizations.of(context)!.loading));
            case Error<List<TransportRoute>>():
              return Center(
                  child: Text(
                      AppLocalizations.of(context)!.routeCalcFailedUnknown));
            case Ok<List<TransportRoute>>():
              {
                var routes = (this.routes as Ok<List<TransportRoute>>).value;
                if (routes.isEmpty) {
                  return Center(
                      child: Text(AppLocalizations.of(context)!
                          .routeCalcFailedNoRoutes));
                } else {
                  return Expanded(
                      child: ListView.separated(
                    itemCount: routes.length + 2,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        //TODO nicer button
                        return TextButton(
                            onPressed: onGetEarlierRoutes,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_upward),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(AppLocalizations.of(context)!.earlier)
                              ],
                            ));
                      }
                      if (index == routes.length + 1) {
                        return TextButton(
                            onPressed: onGetLaterRoutes,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_downward),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(AppLocalizations.of(context)!.later)
                              ],
                            ));
                      }
                      final route = routes[index - 1];
                      return RouteRow(route, onTap: () {
                        onRouteTap(index - 1);
                      });
                    },
                    separatorBuilder: (context, index) => const Divider(
                      color: darkGrey,
                      thickness: 0.5,
                    ),
                  ));
                }
              }
          }
        })
      ],
    );
  }
}

class RouteRow extends StatefulWidget {
  final TransportRoute route;
  final void Function() onTap;

  const RouteRow(this.route, {super.key, required this.onTap});

  @override
  State<RouteRow> createState() => _RouteRowState();
}

class _RouteRowState extends State<RouteRow> {
  Timer? animationTimer;

  bool showDelay = false;

  void ensureTimer() {
    animationTimer ??= Timer.periodic(Duration(seconds: 2), (_) {
      setState(() {
        showDelay = !showDelay;
      });
    });
  }

  @override
  void dispose() {
    animationTimer?.cancel();
    super.dispose();
  }

  final TextStyle upperTextStyle = TextStyle(fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    Duration duration =
        widget.route.expectedDeparture.difference(DateTime.now());
    //TODO: departure or arrival delay?
    var formattedDepartureString =
        formatOnlyTime(widget.route.expectedDeparture);
    var formattedArrivalString = formatOnlyTime(widget.route.expectedArrival);
    var anyIsDelayed = widget.route.parts.any((e) {
      return e.from.delay != null && e.from.delay! != 0;
    });

    bool animate = context.read<SettingsProvider>().showAnimatedDelay;

    return Padding(
      padding: (!animate && anyIsDelayed)
          ? const EdgeInsets.fromLTRB(6, 6, 6, 0)
          : const EdgeInsets.all(6.0),
      child: CustomButtonLike(
        onTap: widget.onTap,
        child: Row(
          children: [
            Semantics(
                  label: AppLocalizations.of(context)!.departureArrival(
                      formattedDepartureString, formattedArrivalString),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ArrivalDepartureTime(
                      time: widget.route.plannedDeparture,
                      delay: widget.route.parts.first.from.delay),
                  // If the last part is a walk, it includes the possible delay from the previous part
                  ArrivalDepartureTime(
                    time: widget.route.plannedArrival,
                    delay: widget.route.parts.last.to.delay,
                    isSmall: true,
                  ),
                ],
              ),
            ),
            Container(
              width: 10,
            ),
            ...widget.route.parts.map(
              (e) {
                var isDelayed = e.from.delay != null && e.from.delay! != 0;
                if (isDelayed && animate) {
                  ensureTimer();
                }
                var lineText = Text(
                  e.line.displayLabel,
                  style: TextStyle(fontSize: 12),
                  key: ValueKey("lineText"),
                );
                var delayText = Text(
                  "${(e.from.delay ?? 0) > 0 ? "+" : ""}${e.from.delay}"
                      .padRight(e.line.displayLabel.length, " "),
                  style: TextStyle(
                      fontSize: 12, color: getDelayColor(e.from.delay ?? 0)),
                  key: ValueKey("delayText"),
                );
                return Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                  child: (e.line.isWalk
                      ? Column(
                          children: [
                            Icon(
                              Icons.directions_walk,
                              semanticLabel:
                                  AppLocalizations.of(context)!.footpath,
                            ),
                            Text("")
                          ],
                        )
                      : Semantics(
                          label:
                              "${e.line.transportType?.name ?? ""} ${e.line.displayLabel}",
                          child: Column(
                            children: [
                                Badge(
                                label: Icon(
                                  Icons.warning,
                                  color: tickerYellow,
                                  semanticLabel:
                                      AppLocalizations.of(context)!.incidentOnLine,
                                ),
                                offset: Offset(0, -8),
                                largeSize: 16,
                                backgroundColor: Colors.transparent,
                                isLabelVisible: e.tickers.isNotEmpty,
                                child: mapTransportTypeToWidget(
                                  context, e.line.transportType, e.line.sev),
                              ),
                              !animate
                                  ? Column(
                                      children: [
                                        lineText,
                                        if (isDelayed) delayText,
                                      ],
                                    )
                                  : AnimatedSwitcher(
                                      duration: Duration(milliseconds: 500),
                                      child: isDelayed && showDelay
                                          ? delayText
                                          : lineText,
                                    )
                            ],
                          ),
                        )),
                );
              },
            ),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatDurationLocalized(duration, context),
                  semanticsLabel: "${AppLocalizations.of(context)!.departure} ${formatDurationLocalized(duration, context)}",
                  style: upperTextStyle.merge(TextStyle(
                      color: widget.route.parts.first.from.delay != null &&
                              widget.route.parts.first.from.delay! > 0
                          ? Colors.red
                          : blueBg)),
                ),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                          .durationLabel("${widget.route.totalMinutes} Min."),
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                )
              ],
            ),
            const RightArrowIcon()
          ],
        ),
      ),
    );
  }
}

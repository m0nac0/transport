// ignore_for_file: prefer_const_constructors

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transport/data/munich_transit_data_repository.dart';
import 'package:transport/data/settings_model.dart';
import 'package:transport/datamodel/tickers.dart';
import 'package:transport/datamodel/transport_type.dart';
import 'package:transport/packages/result.dart';
import 'package:transport/ui/components/custom_button_like.dart';
import 'package:transport/ui/components/delay_text.dart';
import 'package:transport/ui/components/header.dart';
import 'package:transport/ui/components/occupancy_indicator.dart';
import 'package:transport/ui/components/stop_position_number.dart';
import 'package:transport/ui/components/ticker_line_or_event_type_widget.dart';
import 'package:transport/ui/routes/arrival_departure_time.dart';
import 'package:transport/ui/routes/exit_letter.dart';
import 'package:transport/ui/routes/route_bar_painter.dart';
import 'package:transport/ui/routes/routes_list.dart';
import 'package:flutter/material.dart' hide TickerProvider;
import 'package:transport/ui/util/colors.dart';
import 'package:transport/datamodel/station.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:maplibre_gl/maplibre_gl.dart' hide Error;
import 'package:transport/data/ticker_provider.dart';
import 'package:transport/ui/util/format_time.dart';

import '../../datamodel/routes.dart';
import '../map/map_util.dart';
import 'package:transport/l10n/app_localizations.dart';

class RouteDetailsScreenArguments {
  final RoutesListViewModel viewModel;
  final int startIndex;

  const RouteDetailsScreenArguments(this.viewModel, this.startIndex);
}

class RouteDetailsScreen extends StatefulWidget {
  final RoutesListViewModel viewModel;
  final int startIndex;

  const RouteDetailsScreen(
      {super.key, required this.viewModel, required this.startIndex});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  late PageController controller;

  final GlobalKey key = GlobalKey();
  final GlobalKey headerKey = GlobalKey();
  late double mapHeight;

  @override
  void initState() {
    controller = PageController(initialPage: widget.startIndex);
    mapHeight = context
        .read<SettingsProvider>()
        .defaultMapHeight; //widget.initialMapHeight;
    super.initState();
  }

  /// Shares the currently displayed route through the system share mechanism
  /// in text form.
  void shareRoute() {
    final index = (controller.page ?? controller.initialPage).round();
    final shareText = widget.viewModel.getRouteShareText(context, index);
    if (shareText == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.routeShareFailed)));
      return;
    }
    //To avoid issues on iPads according to the plugin docs
    final box = context.findRenderObject() as RenderBox?;
    Share.share(
      shareText,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  List<Widget> getMainContent(RoutesListViewModel viewModel) {
    switch (widget.viewModel.routes) {
      case null:
        return [Center(child: Text(AppLocalizations.of(context)!.loading))];
      case Error<List<TransportRoute>>():
        return [
          Center(
              child: Text(AppLocalizations.of(context)!.routeCalcFailedUnknown))
        ];
      case Ok<List<TransportRoute>>():
        var routes =
            (widget.viewModel.routes as Ok<List<TransportRoute>>).value;
        return [
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => RouteMap(
                mapHeight,
                routes[controller.hasClients
                    ? (controller.page ?? 0).round()
                    : 0]),
          ),
          Expanded(
            child: PageView(
              controller: controller,
              children: Iterable.generate(routes.length, (index) => index)
                  .map<RouteDetailsWithMap>((index) => RouteDetailsWithMap(
                        viewModel: widget.viewModel,
                        routeIndex: index,
                        initialMapHeight: mapHeight,
                        onDrag: (double? primaryDelta) {
                          if (primaryDelta != null) {
                            double newMapHeight =
                                max(0, mapHeight + primaryDelta);
                            final RenderBox? renderBoxRed = key.currentContext
                                ?.findRenderObject() as RenderBox?;
                            final size = renderBoxRed?.size;
                            newMapHeight = min(
                                (size?.height ?? double.infinity) -
                                    85 -
                                    ((headerKey.currentContext
                                                    ?.findRenderObject()
                                                as RenderBox?)
                                            ?.size
                                            .height
                                            .round() ??
                                        0),
                                newMapHeight);
                            setState(() {
                              mapHeight = newMapHeight;
                            });
                          }
                        },
                        onDragEnd: () {
                          Provider.of<SettingsProvider>(context, listen: false)
                              .defaultMapHeight = mapHeight;
                        },
                        containerKey: key,
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SmoothPageIndicator(
              controller: controller, // PageController
              count: routes.length,
              effect: ScrollingDotsEffect(
                maxVisibleDots: 5,
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: blueBg,
              ),
              onDotClicked: (int i) {
                if (i > (controller.page?.round() ?? 0)) {
                  controller.nextPage(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOut);
                } else {
                  controller.previousPage(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOut);
                }
              }, // your preferred effect
            ),
          )
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      children: [
        Header(
          key: headerKey,
          title: AppLocalizations.of(context)?.routeDetails ?? "",
          showBackButton: true,
          actions: [
            (Icons.share, shareRoute),
          ],
        ),
        ...getMainContent(widget.viewModel)
      ],
    );
  }
}

class RouteMap extends StatefulWidget {
  final double mapHeight;
  final TransportRoute route;

  const RouteMap(this.mapHeight, this.route, {super.key});

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  bool useLocalStyle = true;
  String? localStyleString;
  late MaplibreMapController controller;
  TransportRoute? currentlyDisplayedRoute;

  bool myLocationEnabled = false;

  @override
  void initState() {
    super.initState();
    if (platformSupportsMap) {
      useLocalStyle = context.read<SettingsProvider>().useLocalStyle;
      initMapAssets();
    }
  }

  @override
  void didUpdateWidget(covariant RouteMap oldWidget) {
    if (widget.route != currentlyDisplayedRoute &&
        currentlyDisplayedRoute != null) {
      showRouteOnMap(widget.route);
    }
    super.didUpdateWidget(oldWidget);
  }

  void showRouteOnMap(TransportRoute route) {
    double? minLat, minLng, maxLat, maxLng;
    controller.clearLines();
    controller.clearSymbols();
    for (var part in route.parts) {
      var coordinates = part.coordinates;
      var interchangeCoordinates = part.interchangeCoordinates;
      if (coordinates != null && coordinates.isNotEmpty) {
        String generatedColor =
            (TickerLineOrEventTypeWidget.getLineBackgroundColorOrNull(
                        part.line.transportType, part.line.label) ??
                    Colors.black)
                .toHexStringRGB();

        controller.addLine(LineOptions(
            lineWidth: 3,
            lineColor: generatedColor,
            geometry: coordinates
                .map((e) => LatLng(e.latitude, e.longitude))
                .toList()));
        for (var coordinatePair in coordinates) {
          //Determine total minimum bounding box for the route
          minLat = min(coordinatePair.latitude, minLat ?? double.infinity);
          minLng = min(coordinatePair.longitude, minLng ?? double.infinity);
          maxLat =
              max(coordinatePair.latitude, maxLat ?? double.negativeInfinity);
          maxLng =
              max(coordinatePair.longitude, maxLng ?? double.negativeInfinity);
        }
      }
      if (interchangeCoordinates != null && interchangeCoordinates.isNotEmpty) {
        String color = Colors.grey.toHexStringRGB();

        controller.addLine(LineOptions(
            lineWidth: 3,
            lineColor: color,
            geometry: interchangeCoordinates
                .map((e) => LatLng(e.latitude, e.longitude))
                .toList()));
        for (var coordinatePair in interchangeCoordinates) {
          //Determine total minimum bounding box for the route
          minLat = min(coordinatePair.latitude, minLat ?? double.infinity);
          minLng = min(coordinatePair.longitude, minLng ?? double.infinity);
          maxLat =
              max(coordinatePair.latitude, maxLat ?? double.negativeInfinity);
          maxLng =
              max(coordinatePair.longitude, maxLng ?? double.negativeInfinity);
        }
      }
    }
    controller.addSymbols(
        route.parts
            .map((part) => [
                  ...part.intermediateStops
                      .where((point) => (point.station.latitude != null &&
                          point.station.longitude != null))
                      .map<SymbolOptions>((point) =>
                          stationToSymbolOptions(point.station, filled: false)),
                  if (part.coordinates?.firstOrNull != null)
                    SymbolOptions(
                      geometry: LatLng(part.coordinates!.first.latitude,
                          part.coordinates!.first.longitude),
                      iconImage: "circle_11",
                    ),
                  if (part.coordinates?.lastOrNull != null)
                    SymbolOptions(
                      geometry: LatLng(part.coordinates!.last.latitude,
                          part.coordinates!.last.longitude),
                      iconImage: "circle_11",
                    ),
                ])
            .fold([], (list1, list2) => [...list1, ...list2]),
        route.parts
            .map((part) => [
                  ...part.intermediateStops
                      .where((point) => (point.station.latitude != null &&
                          point.station.longitude != null))
                      .map<Map<String, String>>(
                          (point) => stationToSymbolData(point.station)),
                  if (part.from.station.latitude != null &&
                      part.from.station.longitude != null)
                    stationToSymbolData(part.from.station),
                  if (part.to.station.latitude != null &&
                      part.to.station.longitude != null)
                    stationToSymbolData(part.to.station),
                ])
            .fold([], (list1, list2) => [...?list1, ...list2]));

    // Move the map camera to the minimum bounding box for the entire route
    if (minLat != null && minLng != null && maxLat != null && maxLng != null) {
      controller.animateCamera(
          CameraUpdate.newLatLngBounds(
              LatLngBounds(
                  southwest: LatLng(minLat, minLng),
                  northeast: LatLng(maxLat, maxLng)),
              left: 10,
              bottom: 10,
              top: 10,
              right: 10),
          duration: Duration(seconds: 1));
    }
    currentlyDisplayedRoute = route;
  }

  SymbolOptions stationToSymbolOptions(Station station, {bool filled = true}) {
    return SymbolOptions(
      geometry: LatLng(station.latitude!, station.longitude!),
      iconImage: filled ? "circle_11" : "circle_stroked_11",
    );
  }

  Map<String, String> stationToSymbolData(Station station) {
    return {
      "name": station.name ?? AppLocalizations.of(context)!.notAvailable,
      "id": station.globalId ?? AppLocalizations.of(context)!.notAvailable,
    };
  }

  void initMapAssets() async {
    if (useLocalStyle || platformSupportsMap) {
      var styleFilePath = await loadAssets(context);
      setState(() {
        localStyleString = styleFilePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mapHeight <= 0) {
      return Container();
    }
    if (platformSupportsMap && (!useLocalStyle || localStyleString != null)) {
      var initialCameraPosition = CameraPosition(
          target: LatLng(
              widget.route.parts.first.from.station.latitude ?? 48.13743,
              widget.route.parts.first.from.station.longitude ?? 11.57549),
          zoom: 12);
      return SizedBox(
        height: widget.mapHeight,
        child: Stack(
          children: [
            MaplibreMap(
              styleString: (useLocalStyle && localStyleString != null)
                  ? localStyleString!
                  : themedKeyedAPIStyle(context),
              initialCameraPosition: initialCameraPosition,
              onMapCreated: (controller) => this.controller = controller,
              myLocationEnabled: myLocationEnabled,
              myLocationRenderMode: myLocationEnabled
                  ? MyLocationRenderMode.COMPASS
                  : MyLocationRenderMode.NORMAL,
              compassEnabled: true,
              compassViewPosition: CompassViewPosition.TopLeft,
              onStyleLoadedCallback: () {
                controller.onSymbolTapped.add((symbol) {
                  showModalBottomSheet(
                      context: context,
                      builder: (context) => StationTappedSheet(
                          stationName: symbol.data?["name"],
                          globalId: symbol.data?["id"]));
                });
                showRouteOnMap(widget.route);

                // Future<void> addImageFromAsset(String assetName) async {
                //   final ByteData bytes = await rootBundle.load("assets/$assetName");
                //   final Uint8List list = bytes.buffer.asUint8List();
                //   await controller.addImage(assetName, list);
                // }
                //
                // addImageFromAsset("ubahn-small.png")
                //     .then((_) => controller.addSymbol(
                //           SymbolOptions(
                //             geometry: LatLng(
                //                 widget.route.parts.first.from.station.latitude ??
                //                     48.13743,
                //                 widget.route.parts.first.from.station.longitude ??
                //                     11.57549),
                //             iconImage: "ubahn-small.png",
                //           ),
                //         ));
              },
            ),
            Positioned(
                top: 12,
                right: 8,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      myLocationEnabled = !myLocationEnabled;
                    });
                  },
                  icon:
                      Icon(myLocationEnabled ? Icons.gps_fixed : Icons.gps_off),
                    tooltip: "${myLocationEnabled ? AppLocalizations.of(context)!.dontShowMyLocation : AppLocalizations.of(context)!.showMyLocation}. ${myLocationEnabled ? AppLocalizations.of(context)!.currentlyEnabled : AppLocalizations.of(context)!.currentlyDisabled}",
                ))
          ],
        ),
      );
    } else if (!kReleaseMode) {
      return SizedBox(
          height: widget.mapHeight,
          child: Placeholder(
            child: Text(widget.route.plannedDeparture.toIso8601String()),
          ));
    } else {
      return Container();
    }
  }
}

class StationTappedSheet extends StatefulWidget {
  final String? stationName;
  final String? globalId;

  const StationTappedSheet({
    super.key,
    required this.stationName,
    required this.globalId,
  });

  @override
  State<StationTappedSheet> createState() => _StationTappedSheetState();
}

class _StationTappedSheetState extends State<StationTappedSheet> {
  late Future<Station?>? stationFuture;

  @override
  void initState() {
    super.initState();
    if (widget.globalId != null) {
      stationFuture = context
          .read<TransitDataRepository>()
          .getStationInfo(widget.globalId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: stationFuture == null
          ? Text(AppLocalizations.of(context)!.errorLoadingStation)
          : FutureBuilder(
              builder: (context, snapshot) => Column(
                children: [
                  Text(
                      (snapshot.hasData
                              ? snapshot.data!.name
                              : widget.stationName) ??
                          "n/a",
                      style: TextStyle(fontSize: 20)),
                  snapshot.hasData
                      ? TextButton(
                          onPressed: () {
                            if (snapshot.data != null) {
                              Navigator.pushNamed(context, '/stationDetails',
                                  arguments: snapshot.data);
                            }
                          },
                          child: Text(
                              AppLocalizations.of(context)!.detailsForStation))
                      : CircularProgressIndicator()
                ],
              ),
              future: stationFuture,
            ),
    );
  }
}

class RouteDetailsWithMap extends StatefulWidget {
  final RoutesListViewModel viewModel;
  final int routeIndex;
  final double initialMapHeight;
  final void Function(double?) onDrag;
  final void Function() onDragEnd;
  final GlobalKey containerKey;

  const RouteDetailsWithMap(
      {super.key,
      required this.viewModel,
      required this.routeIndex,
      required this.initialMapHeight,
      required this.onDrag,
      required this.onDragEnd,
      required this.containerKey});

  @override
  State<RouteDetailsWithMap> createState() => _RouteDetailsWithMapState();
}

class _RouteDetailsWithMapState extends State<RouteDetailsWithMap> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: RouteDetails(
          viewModel: widget.viewModel,
          routeIndex: widget.routeIndex,
          onDrag: widget.onDrag,
          onDragEnd: widget.onDragEnd,
        ))
      ],
    );
  }
}

const routePartsMinHeight = 56.0;

class RouteDetails extends StatefulWidget {
  final RoutesListViewModel viewModel;
  final int routeIndex;
  final void Function(double?) onDrag;
  final void Function() onDragEnd;

  const RouteDetails(
      {super.key,
      required this.viewModel,
      required this.routeIndex,
      required this.onDrag,
      required this.onDragEnd});

  @override
  State<RouteDetails> createState() => _RouteDetailsState();
}

class _RouteDetailsState extends State<RouteDetails> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final routes = widget.viewModel.routes;
    switch (routes) {
      case null:
        return Center(child: Text(AppLocalizations.of(context)!.loading));
      case Error<List<TransportRoute>>():
        return Center(
            child: Text(AppLocalizations.of(context)!.routeCalcFailedUnknown));
      case Ok<List<TransportRoute>>():
        if (routes.value.length <= widget.routeIndex) {
          return Center(
              child:
                  Text(AppLocalizations.of(context)!.routeCalcFailedUnknown));
        }
        var route = routes.value[widget.routeIndex];
        var children = <Widget>[];
        DateTime? nextArrival;
        int? nextArrivalDelay;
        String? nextArrivalStopPositionNumber;
        String? nextArrivalPlatform;
        bool? nextArrivalPlatformIsChanged;
        Color? lastLineColor;
        bool showNextArrivalPlatform = false;
        var routeParts = route.parts;

        for (RoutingPart part in routeParts) {
          var lineColor =
              TickerLineOrEventTypeWidget.getLineBackgroundColorOrNull(
                  part.line.transportType, part.line.label);
          children.add(RouteStopRow(
            station: part.from.station,
            departure: part.from.plannedDeparture,
            departureDelay: part.from.delay,
            arrival: nextArrival,
            arrivalDelay: nextArrivalDelay,
            departureStopPositionNumber: part.from.stopPositionNumber,
            departurePlatform: part.from.platform,
            isDeparturePlatformChanged: part.from.platformChanged,
            arrivalStopPositionNumber: nextArrivalStopPositionNumber,
            arrivalPlatform: nextArrivalPlatform,
            isArrivalPlatformChanged: nextArrivalPlatformIsChanged,
            elevatorOutOfOrder: part.from.station.elevatorOutOfOrder,
            escalatorOutOfOrder: part.from.station.escalatorOutOfOrder,
            isRealStop: true,
            showArrivalPlatform: showNextArrivalPlatform,
            showDeparturePlatform:
                part.line.transportType != TransportType.UBAHN,
            previousLineColor: lastLineColor,
            nextLineColor: lineColor,
            departureExitLetter: part.exitLetter,
          ));
          // "departure time" of this part's "to" is actually the arrival time
          nextArrival = part.to.plannedDeparture;
          nextArrivalDelay = part.to.delay;
          nextArrivalStopPositionNumber = part.to.stopPositionNumber;
          nextArrivalPlatform = part.to.platform;
          nextArrivalPlatformIsChanged = part.to.platformChanged;
          showNextArrivalPlatform =
              part.line.transportType != TransportType.UBAHN;
          lastLineColor = lineColor;

          children.add(RouteSingleLineRow(part: part));
          if (part.tickers.isNotEmpty) {
            children.add(Container(
              color: tickerYellow,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var ticker in part.tickers)
                      CustomButtonLike(
                        onTap: () {
                          Navigator.pushNamed(context, '/tickerDetails',
                              arguments: [ticker]); //TODO show all tickers?!
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ticker.title ?? "",
                                style: TextStyle(
                                  fontSize: 13,
                                  // Switch text color depending on dark mode
                                  color: getTickerTextColor(ticker, context),
                                ),
                              ),
                            ),
                            if (ticker.incidentStart != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.timelapse,
                                    size: 14,
                                    color: getTickerTextColor(ticker, context),
                                  ),
                                  Container(
                                    width: 4,
                                  ),
                                  Text(
                                    formatOnlyTime(ticker.incidentStart!),
                                    style: TextStyle(
                                        color: getTickerTextColor(
                                            ticker, context)),
                                  ),
                                ],
                              )
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ));
          }
          if (part.lineInfo.isNotEmpty) {
            children.add(Container(
              color: tickerYellow,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var lineInfo in part.lineInfo)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lineInfo,
                              style: TextStyle(
                                fontSize: 13,
                                // Switch text color depending on dark mode
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ));
          }
        }

        RoutingPart lastPart = routeParts.last;
        children.add(RouteStopRow(
          station: lastPart.to.station,
          arrival: nextArrival,
          arrivalDelay: nextArrivalDelay,
          arrivalPlatform: lastPart.to.platform,
          isArrivalPlatformChanged: lastPart.to.platformChanged,
          arrivalStopPositionNumber: lastPart.to.stopPositionNumber,
          elevatorOutOfOrder: lastPart.to.station.elevatorOutOfOrder,
          escalatorOutOfOrder: lastPart.to.station.escalatorOutOfOrder,
          isRealStop: true,
          showArrivalPlatform:
              lastPart.line.transportType != TransportType.UBAHN,
          previousLineColor:
              TickerLineOrEventTypeWidget.getLineBackgroundColorOrNull(
                  lastPart.line.transportType, lastPart.line.label),
          departureExitLetter: lastPart.exitLetter,
        ));

        var sortedZones = route.zones;
        sortedZones.sort();
        sortedZones = sortedZones.map((e) => e == "0" ? "M" : e).toList();

        return Container(
          color: Theme.of(context).colorScheme.surfaceBright, //.grey[200],
          child: RefreshIndicator.adaptive(
            onRefresh: () async {
              var result = await context
                  .read<TransitDataRepository>()
                  .getUpdatedRoute(route);
              if (result != null) {
                var (newRoute, manuallyStitchedTogether) = result;

                if (context.mounted) {
                  var enhancedRoute = RoutesListViewModel.enhanceRoutes(
                      context.read<TickerProvider>().getIncidents(),
                      [newRoute]).firstOrNull;
                  if (enhancedRoute != null) {
                    newRoute = enhancedRoute;
                  }
                }

                TransportRoute oldRoute = route;
                setState(() {
                  route = newRoute;
                });
                // TODO re-enable after refactor?
                // enhanceRoutesWithDepartures([newRoute], context).then((value) {
                //   if (context.mounted) {
                //     setState(() {
                //       route = value.firstOrNull ?? route;
                //     });
                //   }
                // });
                var snackBar = SnackBar(
                    duration: Duration(seconds: 20),
                    content: Text(manuallyStitchedTogether
                        ? AppLocalizations.of(context)!
                            .routeNotFoundManualUpdate
                        : AppLocalizations.of(context)!.routeUpdated),
                    action: SnackBarAction(
                        label: AppLocalizations.of(context)!.undo,
                        onPressed: () {
                          if (mounted) {
                            setState(() {
                              route = oldRoute;
                            });
                          }
                        }));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              } else {
                var snackBar = SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.routeUpdateFailed));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              }
            },
            child: Column(
              //mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .timeLabel(route.totalMinutes),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              AppLocalizations.of(context)!.zonesLabel(sortedZones.join(',')),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragStart: (details) {},
                          onVerticalDragUpdate: (details) {
                            widget.onDrag(details.primaryDelta);
                          },
                          onVerticalDragEnd: (details) {
                            widget.onDragEnd();
                          },
                          child: SizedBox(
                            height: 30,
                            width: 30,
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                width: 25,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: darkGrey,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
                ),
                Expanded(
                    child: ListView(
                  children: children,
                )),
              ],
            ),
          ),
        );
    }
  }
}

class RouteSingleLineRow extends StatefulWidget {
  const RouteSingleLineRow({
    super.key,
    required this.part,
  });

  final RoutingPart part;

  @override
  State<RouteSingleLineRow> createState() => _RouteSingleLineRowState();
}

class _RouteSingleLineRowState extends State<RouteSingleLineRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    var isWalk = widget.part.line.isWalk;
    var hasOccupancy = widget.part.occupancy != Occupancy.UNKNOWN;
    var canExpand = !isWalk && widget.part.intermediateStops.isNotEmpty;
    var lineColor = TickerLineOrEventTypeWidget.getLineBackgroundColorOrNull(
        widget.part.line.transportType, widget.part.line.label);
    return Container(
      color: Theme.of(context).colorScheme.surfaceBright, // Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            // required to detect clicks in the Spacer
            behavior: HitTestBehavior.translucent,
            onTap: () {
              setState(() {
                _isExpanded = canExpand && !_isExpanded;
              });
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      constraints:
                          BoxConstraints(minHeight: routePartsMinHeight),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            DelayText(widget.part.from.delay, context),
                            DelayText(widget.part.to.delay, context),
                          ]),
                    ),

                    Container(
                      constraints: BoxConstraints.expand(width: 20),
                      child: ThrougLine(lineColor),
                    ),
                    // We need to create the same padding as in a RouteStopRow
                    hiddenStopPositionNumberSized,
                    SizedBox(
                      width: 8,
                    ),
                    (isWalk)
                        ? Row(
                            children: [
                              Icon(Icons.directions_walk),
                              Text(
                                  "${widget.part.totalMinutes} Min. Fußweg (${widget.part.distance != null ? "${widget.part.distance!.round()} m)" : ""} "),
                            ],
                          )
                        : SizedBox(
                            height: 30,
                            child: TickerLineOrEventTypeWidget.line(
                              TickerLine(
                                  name: widget.part.line.displayLabel,
                                  type: widget.part.line.transportType ??
                                      TransportType.OTHER,
                                  sev: widget.part.line.sev),
                              showSEVIfApplicable: true,
                            ),
                          ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 10,
                      child: Text(
                        '${widget.part.line.destination}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Display occupancy icons if known, 1/2/3 out of 3 persons filled, remaining outlined
                    if (hasOccupancy &&
                        context.watch<SettingsProvider>().showOccupancyIndicators)
                      OccupancyIndicator(occupancy: widget.part.occupancy),
                    if (canExpand)
                      Icon(_isExpanded ? Icons.expand_less : Icons.expand_more)
                  ],
                ),
              ),
            ),
          ),
          if (_isExpanded)
            Column(
              children: [
                for (var stop in widget.part.intermediateStops)
                  RouteStopRow(
                    station: stop.station,
                    arrival: stop.plannedDeparture,
                    arrivalDelay: stop.delay,
                    color: Theme.of(context).colorScheme.surfaceBright,
                    // Colors.grey[200],
                    arrivalPlatform: stop.platform,
                    isArrivalPlatformChanged: stop.platformChanged,
                    showArrivalPlatform:
                        widget.part.line.transportType != TransportType.UBAHN,
                    previousLineColor: lineColor,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// An invisible widget with the size of a stop position number
/// Useful for creating the same padding if no stop position number is shown
var hiddenStopPositionNumberSized = Visibility(
    visible: false,
    maintainSize: true,
    maintainAnimation: true,
    maintainState: true,
    child: StopPositionNumber(stopPositionNumber: ""));

class RouteStopRow extends StatelessWidget {
  final Station station;
  final DateTime? arrival;
  final int? arrivalDelay;
  final DateTime? departure;
  final int? departureDelay;
  final Color? color;
  final String? departureStopPositionNumber;
  final String? departurePlatform;
  final bool? isDeparturePlatformChanged;
  final String? arrivalStopPositionNumber;
  final String? arrivalPlatform;
  final bool? isArrivalPlatformChanged;
  final bool? elevatorOutOfOrder;
  final bool? escalatorOutOfOrder;
  final bool isRealStop;
  final bool showArrivalPlatform;
  final bool showDeparturePlatform;
  final Color? previousLineColor;
  final Color? nextLineColor;
  final String? arrivalExitLetter;
  final String? departureExitLetter;

  const RouteStopRow(
      {super.key,
      required this.station,
      this.arrival,
      this.arrivalDelay,
      this.departure,
      this.departureDelay,
      this.color,
      this.departureStopPositionNumber,
      this.departurePlatform,
      this.isDeparturePlatformChanged,
      this.arrivalStopPositionNumber,
      this.arrivalPlatform,
      this.isArrivalPlatformChanged,
      this.elevatorOutOfOrder,
      this.escalatorOutOfOrder,
      this.isRealStop = false,
      this.showArrivalPlatform = true,
      this.showDeparturePlatform = true,
      this.arrivalExitLetter,
      this.departureExitLetter,
      this.previousLineColor,
      this.nextLineColor});

  @override
  Widget build(BuildContext context) {
    Widget platformText(
        String? platform,
        String? stopPositionNumber,
        DateTime? arrivalOrDeparture,
        bool? isPlatformChanged,
        String? exitLetter,
        {bool hide = false}) {
      if (arrivalOrDeparture == null) {
        // If neither arrival nor departure is set, this is the beginning or end of the route
        return const SizedBox();
      } else {
          if (!hide && platform != null && platform != stopPositionNumber) {
          return Text(
            "${AppLocalizations.of(context)!.platform} $platform",
            style: TextStyle(
                fontSize: 12,
                color: isPlatformChanged == true ? Colors.red : null),
          );
        } else {
          if (exitLetter != null && exitLetter.isNotEmpty) {
            return Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.exitLabel("") ,
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                ExitLetter(exitLetter: exitLetter)
              ],
            );
          }
          // We are at a changing point, but the platform is missing or redundant because it is already displayed as a stop position number
          // Hide the platform text, but keep the space for it
          // (Otherwise users could be confused whether a platform at a changing point is a departure or arrival platform)
          return Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Text("${AppLocalizations.of(context)!.platform}  "));
        }
      }
    }

    return Container(
      constraints:
          BoxConstraints(minHeight: (isRealStop) ? routePartsMinHeight : 0.0),
      color: color ?? Theme.of(context).colorScheme.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: CustomButtonLike(
          onTap: station.isRealStation()
              ? () {
                  Navigator.pushNamed(context, '/stationDetails',
                      arguments: station);
                }
              : null,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 50,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      arrival != null
                          ? ArrivalDepartureTime(
                              time: arrival!, delay: arrivalDelay)
                          : const SizedBox(),
                      departure != null
                          ? ArrivalDepartureTime(
                              time: departure!, delay: departureDelay)
                          : const SizedBox(),
                    ],
                  ),
                ),
                // const SizedBox(width: 8),
                Container(
                  constraints: BoxConstraints.expand(width: 20),
                  child: isRealStop
                      ? StopLines(previousLineColor, nextLineColor)
                      : ThrougLine(previousLineColor),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // If the stop position is missing (i.e. not start or end of route, but no stopPosition for arrival or departure),
                    // display an empty widget of the same size. That ensures that for changing points, it is clear whether a stop
                    // position is for the departure or arrival.
                    arrivalStopPositionNumber != null
                        ? StopPositionNumber(
                            stopPositionNumber: arrivalStopPositionNumber)
                        : arrival != null
                            ? hiddenStopPositionNumberSized
                            : const SizedBox(),
                    departureStopPositionNumber != null
                        ? StopPositionNumber(
                            stopPositionNumber: departureStopPositionNumber)
                        : departure != null
                            ? hiddenStopPositionNumberSized
                            : const SizedBox(),
                  ],
                ),
                //if (arrivalStopPositionNumber != null) Text("  ${arrivalStopPositionNumber}"),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    station.name == null
                        ? ""
                        : station.name!.contains(station.place!) ||
                                station.place == "München"
                            ? station.name!
                            : "${station.name}, ${station.place}",
                    style: isRealStop
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null,
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    platformText(
                        arrivalPlatform,
                        arrivalStopPositionNumber,
                        arrival,
                        isArrivalPlatformChanged,
                        hide: !showArrivalPlatform,
                        arrivalExitLetter),
                    platformText(
                        departurePlatform,
                        departureStopPositionNumber,
                        departure,
                        isDeparturePlatformChanged,
                        hide: !showDeparturePlatform,
                        departureExitLetter),
                  ],
                ),
                Visibility(
                    visible: (elevatorOutOfOrder ?? false),
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Icon(Icons.elevator_sharp,
                        color: Colors.red, size: 20)),
                Visibility(
                    visible: (escalatorOutOfOrder ?? false),
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Icon(Icons.escalator_sharp,
                        color: Colors.red, size: 20)),
                SizedBox(
                  width: 5,
                ),
                if (station.isRealStation())
                  Icon(Icons.arrow_forward_ios, size: 14)
              ],
            ),
          ),
        ),
      ),
    );
  }
}


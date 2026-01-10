import 'dart:async';

import 'package:flutter/material.dart' hide TickerProvider;
import 'package:provider/provider.dart';
import 'package:transport/data/munich_transit_data_repository.dart';
import 'package:transport/data/settings_model.dart';
import 'package:transport/data/ticker_provider.dart';
import 'package:transport/datamodel/tickers.dart';
import 'package:transport/datamodel/transport_type.dart';
import 'package:transport/ui/util/colors.dart';
import 'package:transport/datamodel/station.dart';
import 'package:transport/ui/components/custom_button_like.dart';
import 'package:transport/ui/components/delay_text.dart';
import 'package:transport/ui/components/header.dart';
import 'package:transport/ui/components/occupancy_indicator.dart';
import 'package:transport/ui/components/right_arrow_icon.dart';
import 'package:transport/ui/components/stop_position_number.dart';
import 'package:transport/ui/components/ticker_line_or_event_type_widget.dart';
import 'package:transport/ui/ticker/ticker_main.dart';
import 'package:transport/l10n/app_localizations.dart';
import 'package:transport/ui/util/format_time.dart';
import 'package:transport/ui/util/map_transport_type_to_widget.dart';
import 'package:transport/ui/util/zip.dart';

import '../../datamodel/departures.dart';

class SingleStationDeparturesArguments {
  final Station station;
  final int offsetInMinutes;

  SingleStationDeparturesArguments(this.station, this.offsetInMinutes);
}

class SingleStationDeparturesViewModel extends ChangeNotifier {
  late TransitDataRepository transitDataRepository;
  late TickerProvider tickerProvider;
  final Station station;

  /// All lines departing from this station. If the full list can't be loaded, this will be null (and the lines departing in the next time will NOT be used as a fallback)
  late Future<List<TickerLine>?> availableLinesFuture;
  late Future<List<Departure>> departuresFuture;

  /// All incidents concerning this station, filtered to only include incidents for lines that are departing from this station (based on the availableLinesFuture, or if that is null, based on the lines of the departures in the next time)
  late Future<List<Ticker>> incidentsFuture;
  final int offsetInMinutes;

  SingleStationDeparturesViewModel(
      {required this.transitDataRepository,
      required this.tickerProvider,
      required this.station,
      required this.offsetInMinutes}) {
    departuresFuture = reloadDepartures();
    if (station.globalId != null) {
      availableLinesFuture = transitDataRepository.getLines(station.globalId!);
    } else {
      availableLinesFuture = Future.value(null);
    }

    var allIncidents = tickerProvider
        .getIncidents()
        .map((ticker) => ticker.splitByLines())
        .expand((element) => element)
        .toList();
    // We wait until we have the lines, then we filter the incidents to only include those affecting those lines.
    incidentsFuture = availableLinesFuture.then((availableLines) async {
      // If we got no lines for the station, use all lines from the departures as a fallback
      availableLines ??= await departuresFuture.then((departures) => departures
          .map((departure) => TickerLine.fromDeparture(departure))
          .toList());
      if (availableLines == null) {
        // If we still have no lines, abort
        return [];
      }
      final incidentFilterLines = availableLines.toSet();
      var results = <Ticker>[];

      // We filter only by line name and network
      bool incidentShouldBeIncluded(Ticker incident) {
        return incident.lines.any((incidentLine) {
          return incidentFilterLines.any((filterLine) {
            return filterLine.name == incidentLine.name &&
                filterLine.network == incidentLine.network;
          });
        });
      }

      for (var incident in allIncidents) {
        if (incident.eventTypes.isNotEmpty) {
          if (incident.eventTypes.any((eventType) => incidentFilterLines
              .intersection(eventType.concernedTransportTypes)
              .isNotEmpty)) {
            // If we have a special incident with an event type, and that event type concerns any of the transport types of the lines departing from this station,
            // we include the incident without further filtering (because it likely concerns all lines of that transport type)
            results.add(incident);
          }
        }

        if (incidentShouldBeIncluded(incident)) {
          results.add(incident);
        }
      }

      return results;
    });
  }

  Future<List<Departure>> reloadDepartures() {
    departuresFuture = transitDataRepository.getDepartures(
        station.globalId ?? "",
        offsetInMinutes: offsetInMinutes,
        limit: 100);
    notifyListeners();
    return departuresFuture;
  }
}

class DeparturesSingleStationScreen extends StatefulWidget {
  final Station station;
  final int offsetInMinutes;

  const DeparturesSingleStationScreen(
      {super.key, required this.station, required this.offsetInMinutes});

  @override
  State<DeparturesSingleStationScreen> createState() =>
      _DeparturesSingleStationScreenState();
}

class _DeparturesSingleStationScreenState
    extends State<DeparturesSingleStationScreen> {
  List<TickerLine> filterLines = [];
  late TransitDataRepository transitDataRepository;
  late TickerProvider tickerProvider;
  late SingleStationDeparturesViewModel viewModel;

  @override
  void initState() {
    super.initState();
    transitDataRepository = context.read<TransitDataRepository>();
    tickerProvider = context.read<TickerProvider>();
    viewModel = SingleStationDeparturesViewModel(
        transitDataRepository: transitDataRepository,
        tickerProvider: tickerProvider,
        station: widget.station,
        offsetInMinutes: widget.offsetInMinutes);
  }

  @override
  Widget build(BuildContext context) {
    var rightArrowButton = IconButton(
        disabledColor: Theme.of(context).colorScheme.onSurface,
        onPressed: null,
        icon: const RightArrowIcon());
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, oldWidget) => Column(
        children: [
          Header(
            title: AppLocalizations.of(context)!.departures,
            showBackButton: true,
          ),
          Container(
            height: 45,
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomButtonLike(
                onTap: () {
                  Navigator.pushNamed(context, '/stationDetails', arguments: (
                    widget.station,
                    viewModel.availableLinesFuture
                  ));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Visibility(
                        visible: false,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: rightArrowButton),
                    Text(
                      widget.station.name ?? "",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    rightArrowButton,
                  ],
                ),
              ),
            ),
          ),
          if (filterLines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Row(
                children: [
                  FutureBuilder(
                    builder: (context, snapshot) => TextButton(
                        onPressed: snapshot.hasData
                            ? () {
                                openExtendedFilter(snapshot, context);
                              }
                            : null,
                        child: Text(AppLocalizations.of(context)!.filterBy)),
                    future: viewModel.availableLinesFuture,
                  ),
                  Expanded(
                    child: Wrap(
                      // scrollDirection: Axis.horizontal,
                      // shrinkWrap: true,
                      children: zipWithPaddingWidget(
                          filterLines
                              .map((line) => TickerLineOrEventTypeWidget.line(
                                    line,
                                    showSEVIfApplicable: true,
                                  ))
                              .toList(),
                          const SizedBox(
                            width: 4,
                          )),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel,
                        color: Theme.of(context).brightness == Brightness.light
                            ? darkGrey
                            : Colors.white),
                    onPressed: () {
                      setState(() {
                        filterLines = [];
                      });
                    },
                  )
                ],
              ),
            ),
          const Divider(height: 2, thickness: 1, color: Colors.grey),
          Expanded(
            child: RefreshIndicator.adaptive(
              onRefresh: () => viewModel.reloadDepartures(),
              child: DeparturesList(
                departuresFuture: viewModel.departuresFuture,
                incidentsFuture: viewModel.incidentsFuture,
                filterLines: filterLines,
                onLineTap: (TickerLine line) {
                  setState(() {
                    filterLines = [line];
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openExtendedFilter(
      AsyncSnapshot<List<TickerLine>?> snapshot, BuildContext context) {
    Map<TransportType, List<TickerLine>> linesByTransportType = {};
    for (var line in snapshot.data!) {
      if (linesByTransportType.containsKey(line.type)) {
        linesByTransportType[line.type]?.add(line);
      } else {
        linesByTransportType[line.type] = [line];
      }
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: linesByTransportType.entries
                .map((entry) => Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        mapTransportTypeToWidget(context, entry.key, false),
                        ...entry.value.map((line) {
                          var lineWidget = TickerLineOrEventTypeWidget.line(
                            line,
                            showSEVIfApplicable: true,
                          );
                          return TextButton(
                              onPressed: () {
                                filterLinePressed(
                                    line,
                                    (snapshot.data?.length ?? 0),
                                    setStateDialog);
                              },
                              child: (filterLines.isEmpty ||
                                      filterLines.contains(line))
                                  ? lineWidget
                                  : ColorFiltered(
                                      colorFilter: const ColorFilter.mode(
                                        Colors.grey,
                                        BlendMode.modulate,
                                      ),
                                      child: lineWidget,
                                    ));
                        })
                      ],
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  void filterLinePressed(
      TickerLine line, int numLines, StateSetter setStateDialog) {
    if (filterLines.isEmpty) {
      filterLines = [line];
    } else {
      filterLines.contains(line)
          ? filterLines.remove(line)
          : filterLines.add(line);
    }
    if (filterLines.length == numLines) {
      filterLines = [];
    }
    filterLines.sort((line1, line2) {
      var typeComparison = TransportType.values
          .indexOf(line1.type)
          .compareTo(TransportType.values.indexOf(line2.type));

      return typeComparison != 0
          ? typeComparison
          : line1.name.compareTo(line2.name);
    });
    setState(() {
      filterLines = filterLines;
    });
    setStateDialog(() {
      filterLines = filterLines;
    });
  }
}

class DeparturesList extends StatefulWidget {
  final List<TickerLine> filterLines;
  final void Function(TickerLine) onLineTap;
  final Future<List<Departure>> departuresFuture;
  final Future<List<Ticker>> incidentsFuture;

  const DeparturesList({
    super.key,
    required this.departuresFuture,
    required this.incidentsFuture,
    required this.onLineTap,
    required this.filterLines,
  });

  @override
  State<DeparturesList> createState() => _DeparturesListState();
}

class _DeparturesListState extends State<DeparturesList> {
  bool relativeTimes = false;
  // Timer to peridocally redraw the list (past departures are then shown in grey)
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: (widget.departuresFuture, widget.incidentsFuture).wait,
      builder: (context, snapshot) {
        var departures = snapshot.data?.$1;
        var incidents = snapshot.data?.$2;
        if (widget.filterLines.isNotEmpty) {
          departures = departures
              ?.where((departure) => widget.filterLines
                  .any((line) => TickerLine.fromDeparture(departure) == line))
              .toList();
        }
        bool anyDepartureHasStopPosition = departures
                ?.any((departure) => departure.stopPositionNumber != null) ??
            false;
        //TODO improve comparison for realtime indicator

        var firstDepartureIsAlreadyAfterNow = (departures
                    ?.firstOrNull?.expectedDepartureTime
                    .compareTo(DateTime.now()) ??
                1) >=
            0;
        int departuresRealtimeDividerIndex = firstDepartureIsAlreadyAfterNow
            ? -1
            : departures?.indexWhere((departure) {
                  var difference = departure.expectedDepartureTime
                      .difference(DateTime.now());
                  return const Duration(minutes: -1) < difference &&
                      difference <= const Duration(minutes: 1);
                }) ??
                -1;
        var showRealtimeDivider = departuresRealtimeDividerIndex >= 0;
        return (snapshot.hasData)
            ? ListView.separated(
                separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: lightGrey,
                    ),
                itemCount: departures!.length +
                    incidents!.length +
                    (showRealtimeDivider ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < incidents.length) {
                    return SingleTickerRow(
                        ticker: incidents[index],
                        tickersCount: 1,
                        isFavorite: null,
                        onFavorite: null,
                        onTap: () {
                          Navigator.pushNamed(context, '/tickerDetails',
                              arguments: [
                                incidents[index]
                              ]); //TODO open all tickers?!
                        });
                  } else {
                    var departureIndex = index - incidents.length;

                    if (showRealtimeDivider &&
                        departureIndex == departuresRealtimeDividerIndex) {
                      return const Divider(
                        height: 2,
                        thickness: 1.5,
                        color: darkGrey,
                      );
                    }
                    final e = departures![departureIndex -
                        (showRealtimeDivider &&
                                departureIndex > departuresRealtimeDividerIndex
                            ? 1
                            : 0)];
                    final cancellationDependentStyle = TextStyle(
                        decoration: e.isCancelled
                            ? TextDecoration.lineThrough
                            : TextDecoration.none);
                    var tickerLine = TickerLine.fromDeparture(e);
                    return Container(
                      color: showRealtimeDivider &&
                              departureIndex < departuresRealtimeDividerIndex
                          ? lightGrey
                          : Theme.of(context).colorScheme.background,
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    if (e.isCancelled)
                                      Text(e.displayLabel,
                                          style: cancellationDependentStyle)
                                    else
                                      CustomButtonLike(
                                        onTap: () =>
                                            widget.onLineTap(tickerLine),
                                        child: TickerLineOrEventTypeWidget.line(
                                          tickerLine,
                                          showSEVIfApplicable: true,
                                        ),
                                      ),
                                    Container(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          text: e.destination ?? "",
                                          style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onBackground,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600)
                                              .merge(
                                                  cancellationDependentStyle),
                                        ),
                                      ),
                                    ),
                                    if (e.occupancy != null &&
                                        !e.isCancelled &&
                                        context
                                            .watch<SettingsProvider>()
                                            .showOccupancyIndicators)
                                      OccupancyIndicator(
                                          occupancy: e.occupancy!),
                                    Container(
                                      width: 10,
                                    ),
                                    if (e.transportType !=
                                            TransportType.UBAHN &&
                                        e.platform != null &&
                                        e.platform!.isNotEmpty)
                                      Text(
                                        "${AppLocalizations.of(context)!.platform} ${e.platform}  ",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: e.isPlatformChanged == true
                                                ? Colors.red
                                                : null),
                                      ),
                                    if (anyDepartureHasStopPosition)
                                      (e.stopPositionNumber != null &&
                                              e.cancelled != null &&
                                              !e.cancelled!)
                                          ? StopPositionNumber(
                                              stopPositionNumber:
                                                  e.stopPositionNumber)
                                          : Container(width: 22),
                                    DelayText(e.delayInMinutes, context),
                                    Container(
                                      width: 5,
                                    ),
                                    CustomButtonLike(
                                      onTap: () {
                                        setState(() {
                                          relativeTimes = !relativeTimes;
                                        });
                                      },
                                        child: Text(
                                        relativeTimes
                                          ? formatDurationLocalized(
                                            e.expectedDepartureTime
                                              .difference(DateTime.now()),
                                            context)
                                          : formatDateTimeAuto(
                                            e.expectedDepartureTime),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: !e.realtime ||
                                                  e.delayInMinutes == null
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onBackground
                                              : getDelayColor(
                                                  e.delayInMinutes!),
                                        ).merge(cancellationDependentStyle),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (e.infoMessages != null &&
                                        e.infoMessages!.isNotEmpty)
                                      Column(
                                        children: e.infoMessages!
                                            .map((info) => Row(
                                                  children: [
                                                    Icon(
                                                      info.type ==
                                                              InfoType.incident
                                                          ? Icons
                                                              .warning_amber_outlined
                                                          : Icons.info_outline,
                                                      size: 14,
                                                    ),
                                                    Container(
                                                      width: 10,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        info.message,
                                                        style: const TextStyle(
                                                                fontSize: 12)
                                                            .merge(
                                                                cancellationDependentStyle),
                                                      ),
                                                    ),
                                                  ],
                                                ))
                                            .toList(),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          )),
                    );
                  }
                })
            : Text(AppLocalizations.of(context)!.loading);
      },
    );
  }
}

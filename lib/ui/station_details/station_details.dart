import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:transport/api/user_agent.dart';
import 'package:transport/data/munich_transit_data_repository.dart';
import 'package:transport/datamodel/station_postings.dart';
import 'package:transport/datamodel/tickers.dart';
import 'package:transport/datamodel/transport_type.dart';
import 'package:transport/ui/util/colors.dart';
import 'package:transport/datamodel/station.dart';
import 'package:transport/ui/components/header.dart';
import 'package:transport/ui/components/right_arrow_icon.dart';
import 'package:transport/ui/components/ticker_line_or_event_type_widget.dart';
import 'package:transport/ui/departures/departures_details.dart';
import 'package:transport/l10n/app_localizations.dart';
import 'package:transport/ui/util/map_transport_type_to_widget.dart';
import 'package:transport/ui/util/zip.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';


class StationDetailsViewModel extends ChangeNotifier {
  final Station station;
  final TransitDataRepository repository;

  late Future<List<ScheduleOrMap>?> schedulesMaps;
  late Future<List<TickerLine>?> linesFuture;

  StationDetailsViewModel({required this.station, required this.repository}) {
    schedulesMaps = repository.getScheduleAndMaps(station);
    if (station.globalId != null) {
      linesFuture = repository.getLines(station.globalId!);
    }else{
      linesFuture = Future.value(null);
    }
  }
}

class StationDetailsScreen extends StatelessWidget {
  final StationDetailsViewModel viewModel;

  const StationDetailsScreen(
      {super.key,
      required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceBright,
      child: Column(
        children: [
          Header(
            title: viewModel.station.name ?? "",
            showBackButton: true,
            backButtonOnlyIcon: true,
          ),
          Expanded(
            child: StationDetailsWidget(
              viewModel: viewModel,
            ),
          ),
        ],
      ),
    );
  }
}

class StationDetailsWidget extends StatefulWidget {
  final StationDetailsViewModel viewModel;

  const StationDetailsWidget({super.key, required this.viewModel});

  @override
  State<StationDetailsWidget> createState() => _StationDetailsWidgetState();
}

class _StationDetailsWidgetState extends State<StationDetailsWidget> {
  File? downloadedMap;
  final supportsWebview =
      (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
  WebViewController? webviewController;

  @override
  void initState() {
    super.initState();
    if (supportsWebview) {
      webviewController = WebViewController();
    }
  }

  @override
  Widget build(BuildContext context) {
    const divider = Divider(
      height: 1,
      color: darkGrey,
      thickness: 0.5,
    );
    var transportTypeWidgets = widget.viewModel.station.transportTypes
        ?.where((type) => type != TransportType.OTHER)
        .map((transportType) =>
          mapTransportTypeToWidget(context, transportType, false))
        .toList() ??
      [];
    var shouldShowWebview = supportsWebview && downloadedMap != null;
    return ListView(
      shrinkWrap: true,
      children: [
        if (!(shouldShowWebview))
          FutureBuilder(
            future: widget.viewModel.schedulesMaps,
            builder: (context, snapshot) {
              StationOrOverviewMap? map;
              if (snapshot.hasData) {
                map = snapshot.data!.whereType<OverviewMap>().firstOrNull ??
                    snapshot.data!.whereType<StationMap>().firstOrNull;
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.background),
                      onPressed:
                          map == null ? null : () => _downloadAndShowMap(map!),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(map == null
                          ? AppLocalizations.of(context)!.noMapAvailable
                          : AppLocalizations.of(context)!
                            .loadMap(map.direction ?? AppLocalizations.of(context)!.overviewMap)),
                      )),
                ),
              );
            },
          ),
        if (shouldShowWebview)
          SizedBox(
              height: 300,
              child: WebViewWidget(
                controller: webviewController!,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => VerticalDragGestureRecognizer(),
                  ),
                },
              )),
        divider,
        StationDetailsOptionTile(
            title: AppLocalizations.of(context)!.departuresFromHere,
            icon: Icons.departure_board_outlined,
            onTap: () {
              Navigator.pushNamed(context, '/singleDepartures',
                  arguments: SingleStationDeparturesArguments(
                      widget.viewModel.station, 0));
            }),
        divider,
        StationDetailsOptionTile(
            title: AppLocalizations.of(context)!.map,
            icon: Icons.place_outlined,
            onTap: () {
              Navigator.pushNamed(context, '/map',
                  arguments: widget.viewModel.station);
            }),
        divider,
        StationDetailsOptionTile(
          title: AppLocalizations.of(context)!.escalatorsElevators,
          icon: Icons.elevator_outlined,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/stationZoom',
              arguments: widget.viewModel.station,
            );
          },
          trailing: [
            Icon(Icons.elevator_sharp,
                color: switch (widget.viewModel.station.elevatorOutOfOrder) {
                  null => Colors.grey,
                  true => Colors.red,
                  false => Colors.green
                }),
            Icon(Icons.escalator_sharp,
                color: switch (widget.viewModel.station.escalatorOutOfOrder) {
                  null => Colors.grey,
                  true => Colors.red,
                  false => Colors.green
                }),
          ],
        ),
        divider,
        FutureBuilder(
          future: widget.viewModel.schedulesMaps,
          builder: (BuildContext context,
              AsyncSnapshot<List<ScheduleOrMap>?> snapshot) {
            List<Widget>? mapTitleWidgets;
            if (snapshot.data != null) {
              List<ScheduleOrMap> mapTitles = List.of(snapshot.data!)
                ..sort((a, b) {
                  if (a is Schedule && b is Schedule) {
                    if (a.name != b.name) {
                      return a.name?.compareTo(b.name ?? "") ?? -1;
                    } else {
                      return a.direction?.compareTo(b.direction ?? "") ?? -1;
                    }
                  } else if (a is! Schedule) {
                    return -1;
                  } else {
                    return 1;
                  }
                });
              mapTitleWidgets = (mapTitles.map(
                (scheduleOrMap) {
                  String title;
                  if (scheduleOrMap is Schedule) {
                    title = "→${scheduleOrMap.direction ?? AppLocalizations.of(context)!.unknownDirection}";
                  } else {
                    title = scheduleOrMap.direction ?? AppLocalizations.of(context)!.otherPlan;
                  }
                  return ListTile(
                    title: Row(
                      children: [
                        if (scheduleOrMap is Schedule)
                          TickerLineOrEventTypeWidget.line(TickerLine(
                              name: scheduleOrMap.name ?? "",
                              type: scheduleOrMap.type)),
                        Expanded(
                            child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                        )),
                      ],
                    ),
                    onTap: () => launchUrl(scheduleOrMap.uri),
                    trailing: const RightArrowIcon(),
                  );
                },
              )).toList();
            }
            return Container(
              color: Theme.of(context).colorScheme.background,
              child: ExpansionTile(
                leading: const Icon(
                  Icons.map_outlined,
                ),
                enabled: snapshot.hasData,
                title: Text(AppLocalizations.of(context)!.timetablesAndMap),
                children: snapshot.hasData
                    ? zipWithPaddingWidget(
                        mapTitleWidgets!, const SizedBox(width: 8))
                    : [],
              ),
            );
          },
        ),
        divider,
        FutureBuilder(
          future: widget.viewModel.linesFuture,
          builder: (context, snapshot) {
            Map<TransportType, List<TickerLine>> linesByTransportType = {};
            if (snapshot.hasData) {
              for (var line in snapshot.data!) {
                if (linesByTransportType.containsKey(line.type)) {
                  linesByTransportType[line.type]?.add(line);
                } else {
                  linesByTransportType[line.type] = [line];
                }
              }
            }
            return Container(
              color: Theme.of(context).colorScheme.background,
              child: ExpansionTile(
                  enabled: snapshot.hasData,
                  leading: const Icon(
                    Icons.directions_bus_outlined,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      divider,
                      Text(
                        AppLocalizations.of(context)!.lines,
                        style: ListTileTheme.of(context).titleTextStyle,
                      ),
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: zipWithPaddingWidget(
                              transportTypeWidgets,
                              const SizedBox(
                                width: 8,
                              )),
                        ),
                      )
                    ],
                  ),
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: linesByTransportType.entries.map((entry) {
                        const horizontalSpacer = SizedBox(
                          width: 4,
                        );
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Wrap(
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              mapTransportTypeToWidget(context, entry.key, false),
                              horizontalSpacer,
                              ...zipWithPaddingWidget(
                                  entry.value.map((line) {
                                    return TickerLineOrEventTypeWidget.line(
                                      line,
                                      showSEVIfApplicable: true,
                                    );
                                  }).toList(),
                                  horizontalSpacer)
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ]),
            );
          },
        )
      ],
    );
  }

  Future<File> _downloadFile(Uri uri, String filename) async {
    final dir = (await getApplicationSupportDirectory());
    var targetFile = File('${dir.path}${Platform.pathSeparator}$filename');
    if (!targetFile.existsSync()) {
      Platform.pathSeparator;
      var response = await UserAgentClient.standard().get(uri);
      var bytes = response.bodyBytes;
      await targetFile.writeAsBytes(bytes);
    }
    return targetFile;
  }

  Future<void> _downloadAndShowMap(StationOrOverviewMap map) async {
    File file = await _downloadFile(
        map.uri, map.uri.pathSegments.lastOrNull ?? "debug.pdf");
    setState(() {
      downloadedMap = file;
    });
    if (supportsWebview) {
      webviewController?.loadFile(file.absolute.path);
    } else {
      launchUrl(Uri(scheme: "file", path: file.absolute.path));
    }
  }
}

class StationDetailsOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Icon>? trailing;
  final VoidCallback? onTap;

  const StationDetailsOptionTile(
      {super.key,
      required this.title,
      required this.icon,
      required this.onTap,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      color: Theme.of(context).colorScheme.background,
      child: ListTile(
        title: Text(title),
        leading: Icon(icon),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (trailing != null) ...trailing!,
          const RightArrowIcon()
        ]),
        onTap: onTap,
      ),
    );
  }
}

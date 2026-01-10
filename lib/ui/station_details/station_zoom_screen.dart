import 'package:flutter/material.dart';
import 'package:transport/datamodel/station.dart';
import 'package:transport/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:transport/data/munich_transit_data_repository.dart';
import 'package:transport/datamodel/station_devices.dart';
import 'package:transport/ui/components/header.dart';


class StationAccessibilityMapScreen extends StatelessWidget {
  final Station station;

  const StationAccessibilityMapScreen({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          title: station.name ?? "",
          showBackButton: true,
          backButtonOnlyIcon: true,
        ),
        StationAccessibilityMapWidget(
          station: station,
        ),
      ],
    );
  }
}

class StationAccessibilityMapWidget extends StatefulWidget {
  final Station station;

  const StationAccessibilityMapWidget({super.key, required this.station});

  @override
  State<StationAccessibilityMapWidget> createState() => _StationAccessibilityMapWidgetState();
}

class _StationAccessibilityMapWidgetState extends State<StationAccessibilityMapWidget> {
  StationAccessibilityData? zoomData;

  @override
  void initState() {
    context
        .read<TransitDataRepository>()
        .getStationAccessibilityData(widget.station)
        .then((value) {
      if (value != null) {
        setState(() {
          zoomData = value;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      //in case of issues with InteractiveViewer, maybe reference e.g. https://github.com/justinmc/flutter-go?tab=readme-ov-file
      child: InteractiveViewer(
          minScale: 0.5,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          child: SizedBox(
            width: 1100,
            height: 778,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  //width: 1100,
                  //height: 778,
                  child: Image.network(
                    context
                        .read<TransitDataRepository>()
                        .getStationAccessibilityMapUrl(widget.station),
                    //width: 1100,
                    //height: 778,
                  ),
                ),
                ...zoomData?.devices
                        .map<Widget>((e) => Positioned(
                              left: (e.xCoordinate ?? 0) * 1.0 - 20,
                              top: (e.yCoordinate ?? 0) * 1.0 - 20,
                              child: Tooltip(
                                triggerMode: TooltipTriggerMode.tap,
                                message: "${e.id}\n${switch (e.status) {
                                  DeviceStatus.ok => AppLocalizations.of(context)!.deviceInService,
                                  DeviceStatus.unknown => AppLocalizations.of(context)!.deviceUnknown,
                                  DeviceStatus.broken => AppLocalizations.of(context)!.deviceBroken
                                }}\n${e.description}",
                                child: Icon(
                                  e.type == DeviceType.elevator
                                      ? Icons.elevator
                                      : Icons.escalator,
                                  color: switch (e.status) {
                                    DeviceStatus.ok => Colors.green,
                                    DeviceStatus.unknown => Colors.grey,
                                    DeviceStatus.broken => Colors.red
                                  },
                                ),
                              ),
                            ))
                        .toList() ??
                    []
              ],
            ),
          )),
    );
  }
}


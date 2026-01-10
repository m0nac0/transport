import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:transport/data/settings_model.dart';
import 'package:transport/ui/components/header.dart';
import 'package:transport/ui/favorites/favorite_buttons.dart';
import 'package:transport/ui/map/map_util.dart';
import 'package:transport/ui/routes/route_details.dart';

import '../../datamodel/station.dart';

import 'package:transport/l10n/app_localizations.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, this.station});

  final Station? station;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String? localStyleString;
  MaplibreMapController? controller;
  String? lastTilePath;
  bool myLocationEnabled = false;
  var listener;
  String styleStringLog = "StyleString: ";

  @override
  void initState() {
    super.initState();
    listener = () {
      if (context.mounted) {
        var currentTilePath = context.read<SettingsProvider>().mapTilePath;
        if (currentTilePath != lastTilePath) {
          initMapAssets();
        }
      }
    };
    context.read<SettingsProvider>().initialize().then((_) {
      if (mounted && context.mounted) {
        if (context.read<SettingsProvider>().useLocalStyle) {
          initMapAssets();
        }
        context.read<SettingsProvider>().addListener(listener);
      }
    });

    if (widget.station != null) {
      showModalBottomSheet(
          context: context,
          builder: (context) => StationTappedSheet(
              stationName: widget.station!.name,
              globalId: widget.station!.globalId));
    }
  }

  @override
  void dispose() {
    if (listener != null) {
      context.read<SettingsProvider>().removeListener(listener);
    }
    super.dispose();
  }

  void initMapAssets() async {
    if (context.read<SettingsProvider>().useLocalStyle) {
      var styleFilePath = await loadAssets(context);
      if (mounted) {
        setState(() {
          localStyleString = null;
        });
        setState(() {
          localStyleString = styleFilePath;
          lastTilePath = context.read<SettingsProvider>().mapTilePath;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var useLocalStyleWatched = context.watch<SettingsProvider>().useLocalStyle;
    var styleString =
        useLocalStyleWatched ? localStyleString : themedKeyedAPIStyle(context);
    return Column(
      children: [
        Header(
          title: AppLocalizations.of(context)?.map ?? "",
        ),
        if (styleString == null)
          Text(AppLocalizations.of(context)!.waitingForLocalMapStyle)
        else
          Expanded(
              child: Stack(children: [
            MaplibreMap(
                compassEnabled: true,
                compassViewPosition: CompassViewPosition.TopLeft,
                onMapClick: (point, latlng) {
                  if (controller == null) {
                    return;
                  }
                  controller!
                      .queryRenderedFeatures(point, ["stops-layer"], null)
                      .then((features) {
                    if (features.isNotEmpty && context.mounted) {
                      showModalBottomSheet(
                          context: context,
                          builder: (context) => StationTappedSheet(
                              stationName: features[0].properties?["name"],
                              globalId: features[0].properties?["id"]));
                    }
                  });
                },
                styleString: styleString,
                initialCameraPosition: widget.station == null
                    ? const CameraPosition(
                        target: LatLng(48.13743, 11.57549), zoom: 12)
                    : CameraPosition(
                        target: LatLng(widget.station!.latitude!,
                            widget.station!.longitude!),
                        zoom: 16),
                onMapCreated: (controller) => this.controller = controller,
                // TODO enable only after user hit a button?
                myLocationEnabled: myLocationEnabled,
                myLocationRenderMode: myLocationEnabled
                    ? MyLocationRenderMode.COMPASS
                    : MyLocationRenderMode.NORMAL,
                onStyleLoadedCallback: () {
                  // controller.onCircleTapped.add(
                  //   (symbol) {
                  //     showModalBottomSheet(
                  //         context: context,
                  //         builder: (context) => StationTappedSheet(
                  //             stationName: symbol.data?["name"],
                  //             globalId: symbol.data?["id"]));
                  //   },
                  // );
                  // Load the stops.geojson file from assets and parse it as json
                  //return;
                  // TODO The following fails sometimes/often when a local map style is used
                  if (context.mounted) {
                    try {
                      DefaultAssetBundle.of(context)
                          .loadString('assets/stops.geojson')
                          .then((geoJsonData) {
                        final stopsGeoJson = jsonDecode(geoJsonData);
                        if (controller == null && context.mounted) {
                          showSnackbar(context, AppLocalizations.of(context)!.controllerNullError);
                          return;
                        } else {
                          // Maybe it actually fails here which would explain why it depends on the style
                          Future.delayed(const Duration(milliseconds: 500), () {
                            controller?.addGeoJsonSource(
                                "stops2", stopsGeoJson);
                            controller?.addLayer(
                                "stops2",
                                "stops-layer",
                                const CircleLayerProperties(
                                  circleRadius: 5.0,
                                  circleColor: "#000000",
                                ));
                          });
                        }
                      });
                    } catch (e) {
                      showSnackbar(context, AppLocalizations.of(context)!.errorLoadingStops(e.toString()));
                    }
                  }
                }),
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
                  tooltip:
                      "${myLocationEnabled ? AppLocalizations.of(context)!.dontShowMyLocation : AppLocalizations.of(context)!.showMyLocation}. ${myLocationEnabled ? AppLocalizations.of(context)!.currentlyEnabled : AppLocalizations.of(context)!.currentlyDisabled}",
                ))
          ]))
      ],
    );
  }
}

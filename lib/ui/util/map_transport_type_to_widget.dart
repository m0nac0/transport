// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:transport/datamodel/transport_type.dart';
import 'package:transport/l10n/app_localizations.dart';

Widget mapTransportTypeToWidget(BuildContext context, TransportType? type, bool? sev) {
  final loc = AppLocalizations.of(context)!;
  if (sev != null && sev) {
    return Semantics(
        label: loc.replacementService,
        child: Image(image: AssetImage("assets/sev.png"), width: 20));
  } else if (type == TransportType.UBAHN) {
    return Semantics(
        label: loc.uBahn,
        child: Image(image: AssetImage("assets/ubahn.png"), width: 20));
  } else if (type == TransportType.TRAM) {
    return Semantics(
        label: loc.tram,
        child: Image(image: AssetImage("assets/tram.png"), width: 20));
  } else if (type == TransportType.SBAHN) {
    return Semantics(
        label: loc.sBahn,
        child: Image(image: AssetImage("assets/sbahn.png"), width: 20));
  } else if (type == TransportType.REGIONAL_BUS || type == TransportType.BUS) {
    return Semantics(
        label: loc.bus,
        child: Image(image: AssetImage("assets/bus.png"), width: 20));
  } else if (type == TransportType.BAHN) {
    return Semantics(
        label: loc.train,
        child: Image(image: AssetImage("assets/zug.png"), width: 20));
  } else if (type == TransportType.SCHIFF) {
    return Semantics(
        label: type!.name,
        child: Image(image: AssetImage("assets/schiff.png"), width: 20));
  } else {
    return Text(type?.name ?? "?");
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:transport/data/settings_model.dart';
import 'package:universal_io/io.dart';

var platformSupportsMap = (Platform.isAndroid || Platform.isIOS || kIsWeb);

const String protomapsApiKey =
  String.fromEnvironment('PROTOMAPS_API_KEY', defaultValue: '');

String _protomapsStyleUrl(String style) {
  final base = 'https://api.protomaps.com/styles/v2/$style.json';
  return protomapsApiKey.isNotEmpty ? '$base?key=$protomapsApiKey' : base;
}

String themedKeyedAPIStyle(BuildContext context) =>
    _protomapsStyleUrl(
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark');

Future<void> writeAssetToFile(ByteData data, String path) {
  final buffer = data.buffer;
  return File(path)
      .writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
}

/// Returns the path to the style file
Future<String> loadAssets(BuildContext context) async {
  var dir = (await getApplicationSupportDirectory()).path;

  String? mapTilePath =
      context.mounted ? context.read<SettingsProvider>().mapTilePath : null;

  var spriteJson = "sprite.json";
  var spritePng = "sprite.png";
  for (String fileName in [
    spriteJson,
    spritePng,
    "sprite@2x.json",
    "sprite@2x.png"
  ]) {
    if (!await File("$dir/$fileName").exists()) {
      var bytes = await rootBundle.load("assets/$fileName");
      writeAssetToFile(bytes, "$dir/$fileName");
    }
  }
  // var geoJsonStops = "stops.geojson";
  // if (!await File("$dir/$geoJsonStops").exists()) {
  //   var bytes = await rootBundle.load("assets/$geoJsonStops");
  //   writeAssetToFile(bytes, "$dir/$geoJsonStops");
  // }

  // var style_file = "style_bright.json";
  var styleFile = "style_pm_light.json";
  var stylePath = "assets/$styleFile";

  if (mapTilePath == null) {
    debugPrint("Error: no tiles path found, using small asset tiles");
    //TODO change tiles maxzoom to overzoom instead of hide
    styleFile = "style_pm_light.json";
    stylePath = "assets/$styleFile";
    const assetTilesFilename = 'tiles.mbtiles';
    mapTilePath = "$dir/$assetTilesFilename";
    if (!await File(mapTilePath).exists()) {
      var bytes = await rootBundle.load("assets/$assetTilesFilename");
      writeAssetToFile(bytes, mapTilePath);
    }
  }
  String loadedStyleString = await rootBundle.loadString(stylePath);
  loadedStyleString = loadedStyleString.replaceAll(
      "___MBTILES_URI___", "mbtiles:///$mapTilePath");
  loadedStyleString = loadedStyleString.replaceAll("___SPRITE___",
      "file://$dir/sprite"); //https://openmaptiles.github.io/osm-bright-gl-style/sprite
  // loadedStyleString = loadedStyleString.replaceAll(
  //     "___STOPS_GEOJSON___", "file://$dir/$geoJsonStops");
  File('$dir/$styleFile').writeAsBytes(utf8.encode(loadedStyleString));

  return '$dir/$styleFile';
}

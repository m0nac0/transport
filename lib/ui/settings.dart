
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transport/data/settings_model.dart';
import 'package:transport/ui/components/header.dart';

import 'util/colors.dart';
import 'package:transport/l10n/app_localizations.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () {},
          onLongPress: () {
            context.read<SettingsProvider>().developerMode =
                !context.read<SettingsProvider>().developerMode;
          },
          child: Header(
            title: AppLocalizations.of(context)?.settings ?? "",
            showBackButton: true,
          ),
        ),
        Expanded(
          child: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              const divider = Divider(
                height: 1,
                thickness: 0.5,
                color: darkGrey,
              );
              return Container(
                color: Theme.of(context).colorScheme.surfaceBright,
                child: ListView(
                  //crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 0, 8),
                      child: Text(
                        AppLocalizations.of(context)!.transportModes,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    TransportTypeEnabledSetting(AppLocalizations.of(context)!.uBahn, settings.ubahnEnabled,
                        (newValue) => settings.ubahnEnabled = newValue),
                    divider,
                    TransportTypeEnabledSetting(AppLocalizations.of(context)!.bus, settings.busEnabled,
                        (newValue) => settings.busEnabled = newValue),
                    divider,
                    TransportTypeEnabledSetting(AppLocalizations.of(context)!.tram, settings.tramEnabled,
                        (newValue) => settings.tramEnabled = newValue),
                    divider,
                    TransportTypeEnabledSetting(AppLocalizations.of(context)!.sBahn, settings.sbahnEnabled,
                        (newValue) => settings.sbahnEnabled = newValue),
                    divider,
                    TransportTypeEnabledSetting(AppLocalizations.of(context)!.train, settings.zugEnabled,
                        (newValue) => settings.zugEnabled = newValue),
                    divider,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 0, 8),
                      child: Text(
                        AppLocalizations.of(context)!.userInterface,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    TransportTypeEnabledSetting(
                      AppLocalizations.of(context)!.occupancyIndicator,
                      settings.showOccupancyIndicators,
                      (newValue) => settings.showOccupancyIndicators = newValue,
                      icon: false,
                    ),
                    TransportTypeEnabledSetting(
                      AppLocalizations.of(context)!.animatedDelayInRoutesList,
                      settings.showAnimatedDelay,
                      (newValue) => settings.showAnimatedDelay = newValue,
                      icon: false,
                    ),
                    divider,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 0, 8),
                      child: Text(
                        AppLocalizations.of(context)!.maps,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    TransportTypeEnabledSetting(
                      AppLocalizations.of(context)!.localMaps,
                      settings.useLocalStyle,
                      (newValue) => settings.useLocalStyle = newValue,
                      icon: false,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FilledButton(
                        onPressed: settings.useLocalStyle
                            ? () async {
                                // File selector is not showing on iOS with this
                                const XTypeGroup typeGroup = XTypeGroup(
                                  label: 'mbtiles',
                                  extensions: <String>['mbtiles'],
                                );
                                final XFile? file = await openFile(
                                    // acceptedTypeGroups: <XTypeGroup>[
                                    //   typeGroup
                                    // ]
                                    );
                                settings.mapTilePath = file?.path;
                              }
                            : null,
                        child: Text(
                            AppLocalizations.of(context)!.chooseMapFile(settings.mapTilePath ?? AppLocalizations.of(context)!.noneChosen)),
                      ),
                    ),
                    if (settings.developerMode) ...[
                      divider,
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 0, 8),
                        child: Text(
                          AppLocalizations.of(context)!.developerSettings,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TransportTypeEnabledSetting(
                        AppLocalizations.of(context)!.jsonLogs,
                        settings.jsonLogsEnabled,
                        (newValue) => settings.jsonLogsEnabled = newValue,
                        icon: false,
                      ),
                    ]
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }
}

class TransportTypeEnabledSetting extends StatelessWidget {
  final String title;
  final bool value;
  final bool icon;
  final void Function(bool) onChange;

  const TransportTypeEnabledSetting(this.title, this.value, this.onChange,
      {super.key, this.icon = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.brightness == Brightness.light
          ? white
          : Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (icon)
              Image(
                  image: AssetImage(
                      "assets/${title.toLowerCase().replaceAll("-", "")}.png"),
                  width: 40),
            const SizedBox(
              width: 8,
            ),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const Spacer(),
            CupertinoSwitch(value: value, onChanged: onChange)
          ],
        ),
      ),
    );
  }
}

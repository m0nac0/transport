// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:transport/l10n/app_localizations.dart';

class Header extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final bool backButtonOnlyIcon;
  final bool italic;
  final bool bold;
  final List<(IconData, VoidCallback)>? actions;

  const Header({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.backButtonOnlyIcon = false,
    this.italic = false,
    this.bold = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    var accent = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).colorScheme.background
        : Theme.of(context).colorScheme.primary;
    var backButton = TextButton(
        style: TextButton.styleFrom(
          foregroundColor: accent,
        ),
        onPressed: () => Navigator.of(context).pop(),
        child: Row(
          children: [
            Icon(
              Icons.keyboard_arrow_left_sharp,
              color: accent,
            ),
            if (!backButtonOnlyIcon)
              Text(
                AppLocalizations.of(context)!.back,
                style: TextStyle(fontSize: 18),
              )
          ],
        ));
    return Container(
      height: 50,
      color: Theme.of(context).brightness == Brightness.light
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.background,
      child: Row(mainAxisSize: MainAxisSize.max, children: [
        Expanded(
          child: showBackButton ? backButton : Container(),
        ),
        Text(
          textAlign: TextAlign.center,
          title,
          style: TextStyle(
              color: accent,
              fontWeight: bold ? FontWeight.bold : null,
              fontStyle: italic ? FontStyle.italic : null,
              fontSize: 20),
        ),
        Expanded(
            child: actions == null
                ? Container()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ...actions!.map<Widget>((tuple) {
                        var (icon, onTap) = tuple;
                        return IconButton(
                          onPressed: onTap,
                          icon: Icon(
                            icon,
                            color: accent,
                          ),
                        );
                      }).toList(),
                      SizedBox(
                        width: 8,
                      )
                    ],
                  )),
      ]),
    );
  }
}

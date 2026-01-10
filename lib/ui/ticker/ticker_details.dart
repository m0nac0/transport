// ignore_for_file: unnecessary_string_interpolations

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:transport/datamodel/tickers.dart';
import 'package:transport/ui/util/colors.dart';
import 'package:transport/l10n/app_localizations.dart';
import 'package:transport/ui/components/header.dart';
import 'package:transport/ui/ticker/ticker_main.dart';
import 'package:transport/ui/util/format_time.dart';

import 'package:url_launcher/url_launcher.dart';

class TickerDetailsPage extends StatelessWidget {
  final List<Ticker> tickers;

  const TickerDetailsPage({super.key, required this.tickers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Header(title: "", showBackButton: true),
        Expanded(
          child: ListView(
            shrinkWrap: true,
            children: [
              //TODO recreate exactly (bigger)

              //First we collect all line and event type logos
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: getTickerWidgetsForLinesAndEventTypes(
                      tickers.fold(
                          [], (list, ticker) => list..addAll(ticker.lines)),
                      tickers.fold({},
                          (list, ticker) => list..addAll(ticker.eventTypes)),
                      isXl:
                          true), //.map((e) => ConstrainedBox(constraints: BoxConstraints(minHeight: 40, minWidth: 60), child: e,),).toList(),
                ),
              ),
              // Now add the TickerDetails for each ticker and dividers
              ...tickers
                  .map((ticker) => TickerDetailsWidget(
                        ticker: ticker,
                      ))
                  // the following just adds Dividers (could also use ListView.separated)
                  .expand((widget) => [
                        widget,
                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: darkGrey,
                        )
                      ])
                  .fold([], (list, w) => list..add(w)).toList()
            ],
          ),
        )
      ],
    );
  }
}

class TickerDetailsWidget extends StatelessWidget {
  final Ticker ticker;

  const TickerDetailsWidget({super.key, required this.ticker});

  @override
  Widget build(BuildContext context) {
    var incidentIsSingleDay = ticker.incidentStart != null &&
        ticker.incidentEnd != null &&
        ticker.incidentStart!.toLocal().day ==
            ticker.incidentEnd!.toLocal().day &&
        ticker.incidentStart!.toLocal().month ==
            ticker.incidentEnd!.toLocal().month &&
        ticker.incidentStart!.toLocal().year ==
            ticker.incidentEnd!.toLocal().year;

    var textStyle = TextStyle(
      color: getTickerTextColor(ticker, context),
      fontSize: 13,
    );

    return Container(
        color: getTickerColor(ticker, context),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      transformHtmlToTextSpan(ticker.title ?? ""),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: getTickerTextColor(ticker, context)),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  //TODO nicer date formatting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today,
                                color: getTickerTextColor(ticker, context)),
                            Container(
                              width: 5,
                            ),
                            if (incidentIsSingleDay)
                              Expanded(
                                child: Text(
                                    ticker.incidentStart == null
                                      ? AppLocalizations.of(context)!.notAvailable
                                      : formatOnlyDate(ticker.incidentStart!.toLocal()),
                                  style: textStyle,
                                ),
                              )
                            else
                              Expanded(
                                child: Text(
                                    "${ticker.incidentStart == null
                                        ? AppLocalizations.of(context)!.notAvailable
                                        : formatOnlyDate(ticker.incidentStart!.toLocal())} -\n${ticker.incidentEnd == null
                                        ? AppLocalizations.of(context)!.notAvailable
                                        : formatOnlyDate(ticker.incidentEnd!.toLocal())}",
                                  style: textStyle,
                                ),
                              ),
                          ],
                        ),
                        if (incidentIsSingleDay)
                          Row(
                            children: [
                              Icon(
                                Icons.timelapse_sharp,
                                color: getTickerTextColor(ticker, context),
                              ),
                              Container(
                                width: 5,
                              ),
                              Text(
                                "${ticker.incidentStart == null
                                    ? AppLocalizations.of(context)!.notAvailable
                                    : formatOnlyTime(ticker.incidentStart!.toLocal())} - ${ticker.incidentEnd == null
                                    ? AppLocalizations.of(context)!.notAvailable
                                    : formatOnlyTime(ticker.incidentEnd!.toLocal())}",
                                style: textStyle,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                height: 10,
              ),
              Text.rich(TextSpan(children: [
                transformHtmlToTextSpan(
                  ticker.text ?? "",
                  style: textStyle,
                ),
                const TextSpan(text: "\n\n"),
                ...List<TextSpan>.from(ticker.links.map((link) {
                  final recognizer = TapGestureRecognizer();
                  recognizer.onTap = () {
                    // if on iOS, launch the links with images in external browser, since the in app view cannot handle them
                    if (Theme.of(context).platform == TargetPlatform.iOS &&
                        link.uri.host == "ticker.mvg.de") {
                      launchUrl(link.uri, mode: LaunchMode.externalApplication);
                      return;
                    } else {
                      launchUrl(link.uri);
                    }
                  };
                  return TextSpan(
                      text: "${link.title}\n\n",
                      style: textStyle.merge(linkStyle),
                      recognizer: recognizer);
                }))
              ])),
            ],
          ),
        ));
  }
}

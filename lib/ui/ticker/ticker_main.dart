// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport/data/favorite_lines_provider.dart';
import 'package:transport/data/ticker_provider.dart';
import 'package:transport/datamodel/transport_type.dart';
import 'package:transport/ui/components/animated_clear_button.dart';
import 'package:transport/ui/components/custom_button_like.dart';
import 'package:transport/ui/components/header.dart';
import 'package:transport/ui/components/ticker_line_or_event_type_widget.dart';
import 'package:universal_io/io.dart';

import 'package:flutter/material.dart' hide TickerProvider;
import 'package:intl/intl.dart';
import 'package:transport/ui/util/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';

import '../../datamodel/tickers.dart';
import 'package:transport/l10n/app_localizations.dart';

class TickerPageViewModel extends ChangeNotifier {
  final TickerProvider _tickerProvider;
  final FavoriteLinesProvider _favoriteLinesProvider = FavoriteLinesProvider();


  TickerPageViewModel({required TickerProvider tickerProvider})
      : _tickerProvider = tickerProvider {
    _tickerProvider.addListener(notifyListeners);
    _favoriteLinesProvider.addListener(notifyListeners);
  }

  List<Ticker> get tickers => _tickerProvider.tickers;
  DateTime? get lastUpdate => _tickerProvider.lastUpdate;
  Future<void> refreshTickers() => _tickerProvider.loadAllTickers();
  Set<String> get favoriteLines => _favoriteLinesProvider.favoriteLines;

  Future<void> toggleFavoriteLine(String lineName) async{
    await _favoriteLinesProvider.toggleFavoriteLine(lineName);
  }


  @override
  void dispose() {
    _tickerProvider.removeListener(notifyListeners);
    _favoriteLinesProvider.removeListener(notifyListeners);
    super.dispose();
  }

  Map<String?, List<Ticker>> getSingleLineTickersGroupedByLine(String filterText) {
    final List<MapEntry<String?, List<Ticker>>> singleLineTickersByLine =
        Ticker.groupByLines(_tickerProvider.tickers
                .expand((element) => element.splitByLines())
                .where((element) =>
                    element.lines.isEmpty ||
                    element.lines.any((element) => element.name
                        .toLowerCase()
                        .contains(filterText)))
                .toList())
            .entries
            .toList();
    singleLineTickersByLine
      ..forEach(
        //sort the ticker entries within a line
        (entry) {
          entry.value.sort((a, b) {
            var aIsFavLine = favoriteLines.contains(a.lines.firstOrNull?.name);
            var bIsFavLine = favoriteLines.contains(b.lines.firstOrNull?.name);
            if (aIsFavLine && !bIsFavLine) {
              return -1;
            } else if (bIsFavLine && !aIsFavLine) {
              return 1;
            }
            // Sort disruptions before planned
            if (a.type == TickerType.disruption &&
                b.type == TickerType.planned) {
              return -1;
            }
            if (a.type == TickerType.planned &&
                b.type == TickerType.disruption) {
              return 1;
            }

            if (a.eventTypes.length != b.eventTypes.length) {
              // If one has more events, sort it first (typically there will only be 1 or 0 event types)
              return -1 * a.eventTypes.length.compareTo(b.eventTypes.length);
            }
            if (a.lines.isEmpty) {
              return 1;
            } else {
              if (b.lines.isEmpty) {
                return -1;
              }
              // Sort S and U lines first
              if (a.lines.any(
                      (element) => element.name.startsWith(RegExp(r'[S]'))) &&
                  !b.lines.any(
                      (element) => element.name.startsWith(RegExp(r'[S]')))) {
                return -1;
              } else if (!a.lines.any(
                      (element) => element.name.startsWith(RegExp(r'[S]'))) &&
                  b.lines.any(
                      (element) => element.name.startsWith(RegExp(r'[S]')))) {
                return 1;
              }
              if (a.lines.any(
                      (element) => element.name.startsWith(RegExp(r'[U]'))) &&
                  !b.lines.any(
                      (element) => element.name.startsWith(RegExp(r'[U]')))) {
                return -1;
              } else if (!a.lines.any(
                      (element) => element.name.startsWith(RegExp(r'[U]'))) &&
                  b.lines.any(
                      (element) => element.name.startsWith(RegExp(r'[U]')))) {
                return 1;
              }
              var lineNumberA = int.tryParse(a.lines.first.name) ??
                  int.tryParse(a.lines.first.name.substring(1));
              var lineNumberB = int.tryParse(b.lines.firstOrNull?.name ?? "") ??
                  int.tryParse(b.lines.firstOrNull?.name.substring(1) ?? "");
              if (lineNumberA != null && lineNumberB != null) {
                // Compare numerical bus lines (excluding first char if it is a X / N line)
                return lineNumberA.compareTo(lineNumberB);
              }
              return a.lines.first.name
                  .compareTo(b.lines.firstOrNull?.name ?? "");
            }
          });
        },
      )
      ..sort((var xa, var xb) {
        //sort the lines, mostly by favorite, incidents within the line and alphabet
        var a = xa.value.firstOrNull;
        var b = xb.value.firstOrNull;

        if (favoriteLines.contains(xa.key) && !favoriteLines.contains(xb.key)) {
          return -1;
        } else if (favoriteLines.contains(xb.key) &&
            !favoriteLines.contains(xa.key)) {
          return 1;
        }
        if (a == null) {
          if (b == null) {
            if (xa.key == null) {
              return -1;
            }
            if (xb.key == null) {
              return 1;
            }
            return xa.key!.compareTo(xb.key!);
          } else {
            return 1;
          }
        }
        if (b == null) {
          return -1;
        }
        // Sort disruptions before planned
        if (a.type == TickerType.disruption && b.type == TickerType.planned) {
          return -1;
        }
        if (a.type == TickerType.planned && b.type == TickerType.disruption) {
          return 1;
        }

        if (a.eventTypes.length != b.eventTypes.length) {
          // If one has more events, sort it first (typically there will only be 1 or 0 event types)
          return -1 * a.eventTypes.length.compareTo(b.eventTypes.length);
        }
        if (a.lines.isEmpty) {
          return 1;
        } else {
          if (b.lines.isEmpty) {
            return -1;
          }

          final aMinTransportTypeOrder = a.lines
              .map((e) => TransportType.transportTypeOrder(e.type))
              .reduce((value, element) => min(value, element));
          final bMinTransportTypeOrder = b.lines
              .map((e) => TransportType.transportTypeOrder(e.type))
              .reduce((value, element) => min(value, element));
          if (aMinTransportTypeOrder != bMinTransportTypeOrder) {
            return aMinTransportTypeOrder.compareTo(bMinTransportTypeOrder);
          }
          final intRegex = RegExp(r'[^\d]*(\d+)[^\d]*');
          var lineNumberA = int.tryParse(a.lines.first.name) ??
              int.tryParse(intRegex.firstMatch(a.lines.first.name)?.group(1) ??
                  a.lines.first.name);
          var lineNumberB = int.tryParse(b.lines.firstOrNull?.name ?? "") ??
              int.tryParse(intRegex.firstMatch(b.lines.first.name)?.group(1) ??
                  b.lines.first.name);
          if (lineNumberA != null && lineNumberB != null) {
            // Compare numerical bus lines (excluding first char if it is a X / N line)
            return lineNumberA.compareTo(lineNumberB);
          }
          return a.lines.first.name.compareTo(b.lines.firstOrNull?.name ?? "");
        }
      });
    return Map.fromEntries(singleLineTickersByLine);
  }
}

class TickerPage extends StatefulWidget {
  late final TickerPageViewModel viewModel;

  TickerPage({super.key, required TickerProvider tickerProvider}) {
    viewModel = TickerPageViewModel(tickerProvider: tickerProvider);
  }

  @override
  State<TickerPage> createState() => _TickerPageState();
}

class _TickerPageState extends State<TickerPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.refreshTickers();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, child) {
          var refreshButton = IconButton(
              onPressed: widget.viewModel.refreshTickers,
              icon: const Icon(Icons.refresh));
          var lastUpdateText = Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
            child: Text(
              widget.viewModel.lastUpdate == null
                  ? ""
                  : "${AppLocalizations.of(context)!.lastUpdate}${DateFormat.yMd(Platform.localeName).format(widget.viewModel.lastUpdate!)}, ${DateFormat.Hm(Platform.localeName).format(widget.viewModel.lastUpdate!)}",
              textAlign: TextAlign.end,
            ),
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Header(title: AppLocalizations.of(context)!.incidents),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.numberAbbrev,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: AppLocalizations.of(context)!.search,
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: darkGrey))),
                    ),
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (_, __) => AnimatedClearButton(
                        controller: _controller,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
              ),
              if (widget.viewModel.lastUpdate != null)
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: !(kReleaseMode &&
                          (Platform.isLinux ||
                              Platform.isMacOS ||
                              Platform.isWindows))
                      ? Column(
                          children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  lastUpdateText,
                                ]),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Visibility(
                                    visible: false,
                                    maintainSize: true,
                                    maintainAnimation: true,
                                    maintainState: true,
                                    child: lastUpdateText,
                                  ),
                                  Spacer(),
                                  refreshButton,
                                  Spacer(),
                                  lastUpdateText,
                                ]),
                          ],
                        ),
                ),
              Expanded(
                child: RefreshIndicator.adaptive(
                  onRefresh: widget.viewModel.refreshTickers,
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      var singleLineTickersGroupedByLine =
                          widget.viewModel.getSingleLineTickersGroupedByLine(_controller.text.toLowerCase());
                      var singleLineTickerWidgets =
                          singleLineTickersGroupedByLine.values.map((tickersForLine) {
                        final firstTickerForLine = tickersForLine.first;
                        return SingleTickerRow(
                            ticker: firstTickerForLine,
                            tickersCount: tickersForLine.length,
                            isFavorite: widget.viewModel.favoriteLines.contains(
                                firstTickerForLine.lines.firstOrNull?.name),
                            onTap: () => Navigator.of(context).pushNamed(
                                "/tickerDetails",
                                arguments: tickersForLine),
                            onFavorite: firstTickerForLine.lines.isEmpty
                                ? null
                                : () {
                                    widget.viewModel.toggleFavoriteLine(
                                        firstTickerForLine.lines.first.name);
                                  });
                      }).toList();
                      return Scrollbar(
                        thumbVisibility: true,
                        child: ListView.separated(
                          primary: true,
                          shrinkWrap: true,
                          itemBuilder: (context, index) =>
                              singleLineTickerWidgets[index],
                          separatorBuilder: (context, index) => Container(
                            color: getTickerColor(
                                singleLineTickerWidgets[index].ticker, context),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              indent: 30,
                              color: darkGrey,
                            ),
                          ),
                          itemCount: singleLineTickerWidgets.length,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        });
  }
}

class SingleTickerRow extends StatefulWidget {
  final Ticker ticker;
  final int tickersCount;
  final bool? isFavorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onTap;

  const SingleTickerRow(
      {super.key,
      required this.ticker,
      required this.tickersCount,
      required this.isFavorite,
      this.onFavorite,
      this.onTap});

  @override
  State<SingleTickerRow> createState() => _SingleTickerRowState();
}

class _SingleTickerRowState extends State<SingleTickerRow> {
  @override
  Widget build(BuildContext context) {
    var ticker = widget.ticker;

    return Container(
      color: getTickerColor(ticker, context),
      child: CustomButtonLike(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ...getTickerWidgetsForLinesAndEventTypes(
                      ticker.lines, ticker.eventTypes.toSet())
                  .map((e) => Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                        child: e,
                      )),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      transformHtmlToTextSpan(ticker.title ?? AppLocalizations.of(context)!.noTitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: getTickerTextColor(ticker, context)),
                    ),
                    if (widget.tickersCount > 1)
                      Row(children: [
                        //TODO: date/time
                        Icon(Icons.email_outlined,
                            size: 13,
                            color: getTickerTextColor(ticker, context)),
                        Text(
                          " + ${widget.tickersCount - 1} ${AppLocalizations.of(context)!.incidents}",
                          style: TextStyle(
                              fontSize: 13,
                              color: getTickerTextColor(ticker, context)),
                        )
                      ])
                  ],
                ),
              ),
              if (ticker.lines.isNotEmpty && widget.isFavorite != null)
                IconButton(
                    onPressed: widget.onFavorite,
                    icon: Icon(
                        widget.isFavorite! ? Icons.star : Icons.star_border,
                        size: 32,
                        color: getTickerTextColor(ticker, context))),
            ],
          ),
        ),
      ),
    );
  }
}

class TagIndex {
  final String tag;
  final int index;

  TagIndex(this.tag, this.index);
}

TextSpan transformHtmlToTextSpan(String htmlString, {TextStyle? style}) {
  htmlString = htmlString
      .replaceAll(RegExp(r'\s*<br>\s*'), "\n")
      .replaceAll("&lt;", "<")
      .replaceAll("&gt;", ">")
      .replaceAll(RegExp(r'\s*<div>\s*'), "")
      .replaceAll(RegExp(r'\s*</div>\s*'), "")
      .replaceAll("&nbsp;", " ")
      .replaceAll("<li>", "\n - ")
      .replaceAll("</li>", "")
      .replaceAll("<ul>", "")
      .replaceAll("</ul>", "\n")
      .replaceAll("<p>", "")
      .replaceAll("</p>", "\n")
      .replaceAll(r"&amp;", "&")
      .replaceAll(r"<span>", "")
      .replaceAll(r"<b>", "<strong>")
      .replaceAll(r"</b>", "</strong>")
      .replaceAll(r"</span>", "");

  final tags = ["strong", "u", "i"];
  final List<TagIndex> startIndices = [];
  for (String tag in tags) {
    int index = htmlString.indexOf("<$tag>");
    while (index >= 0) {
      startIndices.add(TagIndex(tag, index));
      index = htmlString.indexOf("<$tag>", index + tag.length + 2);
    }
  }
  final List<TagIndex> endIndices = [];
  for (String tag in tags) {
    int index = htmlString.indexOf("</$tag>");
    while (index >= 0) {
      endIndices.add(TagIndex(tag, index));
      index = htmlString.indexOf("</$tag>", index + tag.length + 3);
    }
  }
  startIndices.sort((a, b) => a.index.compareTo(b.index));
  endIndices.sort((a, b) => a.index.compareTo(b.index));

  var taggedStrings = [];
  Map<String, int> tagLevels = Map.fromIterable(tags, value: (_) => 0);
  int lastAddedIndex =
      0; //last index up to which the text has been added to taggedStrings
  for (int i = 0; i < htmlString.length;) {
    TagIndex? nextStartIndex =
        startIndices.firstWhereOrNull((element) => element.index >= i);
    TagIndex? nextEndIndex =
        endIndices.firstWhereOrNull((element) => element.index >= i);
    TagIndex? nextIndex;
    var activeTags = tagLevels.entries
        .where((element) => element.value > 0)
        .map((e) => e.key)
        .toList();
    if (nextStartIndex != null &&
        (nextEndIndex == null || nextStartIndex.index < nextEndIndex.index)) {
      nextIndex = nextStartIndex;
      i = nextIndex.index + nextIndex.tag.length + 2;
      taggedStrings.add((
        htmlString.substring(lastAddedIndex, nextStartIndex.index),
        activeTags
      ));
      lastAddedIndex = i;

      tagLevels[nextStartIndex.tag] = (tagLevels[nextStartIndex.tag] ?? 0) + 1;
    } else if (nextEndIndex != null &&
        (nextStartIndex == null ||
            nextStartIndex.index >= nextEndIndex.index)) {
      nextIndex = nextEndIndex;
      tagLevels[nextEndIndex.tag] =
          max(0, (tagLevels[nextEndIndex.tag] ?? 0) - 1);
      i = nextIndex.index + nextIndex.tag.length + 3;
      taggedStrings.add((
        htmlString.substring(lastAddedIndex, nextEndIndex.index),
        activeTags
      ));
      lastAddedIndex = i;
    }

    if (nextIndex == null) {
      // No more tags
      taggedStrings
          .add((htmlString.substring(i, htmlString.length), activeTags));
      break;
    }
  }
  List<TextSpan> spans = [];
  for (var (text, activeTags) in taggedStrings) {
    TextStyle combinedStyle = style ?? TextStyle();
    for (String tag in activeTags) {
      final TextStyle newStyle = switch (tag) {
        "strong" => TextStyle(fontWeight: FontWeight.bold),
        "u" => TextStyle(decoration: TextDecoration.underline),
        "i" => TextStyle(fontStyle: FontStyle.italic),
        _ => TextStyle()
      };
      combinedStyle = combinedStyle.merge(newStyle);
    }

    RegExp linkRegex = RegExp(
        r"""<a\s+(?:[^>]*?\s+)?href=(["'])(.*?)\1.*?>(..*)<\/a>""",
        caseSensitive: false);
    final linkMatch = linkRegex.firstMatch(text); //TODO: allMatches

    RegExp urlRegex = RegExp(
        r'(https?://)?(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&/=]*)',
        caseSensitive: false);

    final urlMatch = urlRegex.firstMatch(text); //TODO: allMatches

    if (linkMatch != null) {
      // We handle links specially, since they are the only complex tags we handle with attributes inside the tag (which requires regex matching)
      var link = linkMatch.group(2);
      var title = linkMatch.group(3);
      var uri = Uri.tryParse(link ?? "");
      TapGestureRecognizer? newRecognizer;
      if (link != null && title != null && uri != null) {
        newRecognizer = TapGestureRecognizer();
        newRecognizer.onTap = () {
          launchUrl(uri);
        };
        // The part before the link
        spans.add(TextSpan(
            text: text.substring(0, linkMatch.start), style: combinedStyle));
        // The link
        spans.add(TextSpan(
            text: title,
            style: linkStyle.merge(combinedStyle),
            recognizer: newRecognizer));

        // The part after the link
        spans.add(TextSpan(
            text: text.substring(linkMatch.end), style: combinedStyle));
      }
    } else if (urlMatch != null &&
        urlMatch.group(0) != null &&
        urlMatch.group(0)!.isNotEmpty &&
        (urlMatch.group(0)!.contains("http") ||
            urlMatch.group(0)!.contains("www.") ||
            urlMatch.group(0)!.contains("/"))) {
      // We also handle plain URLs, but use some heuristics to avoid false positives
      final url = urlMatch.group(0);
      var uri = Uri.tryParse(url ?? "");
      TapGestureRecognizer? newRecognizer;
      if (url != null && uri != null) {
        newRecognizer = TapGestureRecognizer();
        newRecognizer.onTap = () {
          launchUrl(uri);
        };
        // The part before the link
        spans.add(TextSpan(
            text: text.substring(0, urlMatch.start), style: combinedStyle));
        // The link
        spans.add(TextSpan(
            text: url,
            style: linkStyle.merge(combinedStyle),
            recognizer: newRecognizer));

        // The part after the link
        spans.add(
            TextSpan(text: text.substring(urlMatch.end), style: combinedStyle));
      }
    } else {
      //No link
      spans.add(TextSpan(text: text, style: combinedStyle));
    }
  }
  return TextSpan(children: spans, style: style);
}

/// Useful, because e.g. some tickers may contain the same line twice, only with a different network
List<TickerLineOrEventTypeWidget> getTickerWidgetsForLinesAndEventTypes(
    List<TickerLine> lines, Set<EventType> categories,
    {bool isXl = false}) {
  var widgets = <TickerLineOrEventTypeWidget>[];
  var previousLines = <TickerLine>[];
  for (EventType eventType in categories) {
    widgets.add(TickerLineOrEventTypeWidget.event(eventType, isXl: isXl));
  }
  for (var line in lines) {
    if (previousLines.any((previousLine) =>
        previousLine.type == line.type &&
        previousLine.name == line.name &&
        previousLine.sev == line.sev)) {
      continue;
    }
    previousLines.add(line);
    widgets.add(TickerLineOrEventTypeWidget.line(line,
        showSEVIfApplicable: true, isXl: isXl));
  }

  return widgets;
}

class DividedBackgroundPainter extends CustomPainter {
  final Color colorTop;
  final Color colorBottom;

  DividedBackgroundPainter(
    this.colorTop,
    this.colorBottom,
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawVertices(
        Vertices(VertexMode.triangles, [
          Offset(0, size.height),
          Offset(0, 0),
          Offset(size.width, 0),
          Offset(0, size.height),
          Offset(size.width, size.height),
          Offset(size.width, 0)
        ], colors: [
          colorTop,
          colorTop,
          colorTop,
          colorBottom,
          colorBottom,
          colorBottom
        ]),
        BlendMode.dst,
        Paint());
  }

  @override
  bool shouldRepaint(DividedBackgroundPainter oldDelegate) =>
      colorTop != oldDelegate.colorTop ||
      colorBottom != oldDelegate.colorBottom;

  @override
  bool shouldRebuildSemantics(DividedBackgroundPainter oldDelegate) =>
      colorTop != oldDelegate.colorTop ||
      colorBottom != oldDelegate.colorBottom;
}

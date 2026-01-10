// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart' hide TickerProvider;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide TickerProvider;
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:transport/data/favorites_provider.dart';
import 'package:transport/data/munich_transit_data_repository.dart';
import 'package:transport/data/settings_model.dart';
import 'package:transport/data/ticker_provider.dart';
import 'package:transport/datamodel/favorite_button_item.dart';
import 'package:transport/ui/components/bottom_navigation_bar.dart';
import 'package:transport/ui/favorites/add_favorite.dart';
import 'package:transport/datamodel/tickers.dart';
import 'package:transport/ui/routes/recents_ui.dart';
import 'package:transport/ui/util/colors.dart';
import 'package:transport/ui/departures/departures_details.dart';
import 'package:transport/ui/departures/departures_main.dart';
import 'package:transport/packages/polyline/polyline.dart';
import 'package:transport/ui/map/map.dart';
import 'package:transport/data/recents.dart';
import 'package:transport/ui/routes/route_details.dart';
import 'package:transport/ui/routes/routes_list.dart';
import 'package:transport/datamodel/station.dart';
import 'package:transport/ui/settings.dart';
import 'package:transport/ui/station_details/station_details.dart';
import 'package:transport/ui/station_details/station_zoom_screen.dart';
import 'package:transport/ui/ticker/ticker_details.dart';
import 'package:transport/ui/ticker/ticker_main.dart';

import 'ui/routes/route_main_page.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:transport/l10n/app_localizations.dart';
import 'package:device_preview/device_preview.dart';

void main() {
  //runApp(MainApp());
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: blueBg,
      systemNavigationBarColor: lightGrey,
      statusBarBrightness: Brightness.dark, // iOS: dark = white text
      statusBarIconBrightness:
          Brightness.light)); // Android: light = white icons
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MainApp(), // Wrap your app
    ),
  );
}

/// Used to allow mouse dragging on desktop
class MyScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int tabIndex = 0;
  late Widget connectionPage;
  late Widget departuresPage;
  late Widget tickerPage;
  late Widget mapPage;
  late List<GlobalKey> keys;
  final TickerProvider tickerProvider = TickerProvider();
  final FavoritesProvider favoritesProvider = FavoritesProvider();
  final TransitDataRepository transitDataRepository = TransitDataRepository();
  //TODO expose all providers the same way, probably in the high-level MultiProvider
  late RecentsListProvider<Station> recentStations;
  late RecentsListProvider<PreviousConnection> recentConnections;
  final SettingsProvider settingsModel = SettingsProvider();
  bool mapPageInitialized = false;

  @override
  void initState() {
    super.initState();
    recentStations = RecentsListProvider<Station>(
        (Station e) => e.toJson(), Station.fromJson, "previousStations");
    recentConnections = RecentsListProvider<PreviousConnection>(
        (PreviousConnection connection) => connection.toJson(),
        PreviousConnection.fromJson,
        "previousConnections");
    keys = [GlobalKey(), GlobalKey(), GlobalKey(), GlobalKey()];
    connectionPage = Navigator(
      key: keys[0],
      initialRoute: "/",
      onGenerateRoute: (settings) {
        late Widget page;
        if (settings.name == "/") {
          page = const ConnectionPage();
        } else if (settings.name == "/routes") {
          page = RoutesListScreen(
              arguments: settings.arguments as RoutesListScreenArguments);
        } else if (settings.name!.startsWith("/routeDetails")) {
          final args = settings.arguments as RouteDetailsScreenArguments;
          page = RouteDetailsScreen(
            viewModel: args.viewModel,
            startIndex: args.startIndex,
          );
        } else if (settings.name!.startsWith("/singleDepartures")) {
          final args = settings.arguments as SingleStationDeparturesArguments;
          page = DeparturesSingleStationScreen(
            station: args.station,
            offsetInMinutes: args.offsetInMinutes,
          );
        } else if (settings.name == "/stationDetails") {
          page = StationDetailsScreen(
              viewModel: StationDetailsViewModel(
                  station: settings.arguments as Station,
                  repository: transitDataRepository));
        } else if (settings.name == "/stationZoom") {
          page = StationAccessibilityMapScreen(
              station: settings.arguments as Station);
        } else if (settings.name == "/addFavorite") {
          page = AddFavoritePage(
            itemToEdit: settings.arguments as FavoriteButtonItem?,
          );
        } else if (settings.name == "/settings") {
          page = SettingsPage();
        } else if (settings.name!.startsWith("/tickerDetails")) {
          final args = settings.arguments as List<Ticker>;
          page = TickerDetailsPage(tickers: args);
        } else if (settings.name!.startsWith("/map")) {
          final args = settings.arguments as Station;
          page = MapPage(station: args);
        } else {
          throw Exception('Unknown route: ${settings.name}');
        }

        return MaterialPageRoute<dynamic>(
          builder: (context) {
            return MultiProvider(providers: [
              ChangeNotifierProvider.value(
                value: settingsModel,
              ),
              ChangeNotifierProvider.value(value: recentStations),
              ChangeNotifierProvider.value(value: recentConnections),
            ], child: page);
          },
          settings: settings,
        );
      },
    );
    // Nested navigator with two routes: the initial route is a Departures widget,
    // the second route is a DeparturesSingleStationScreen widget taking the station globalId
    departuresPage = Navigator(
      key: keys[1],
      initialRoute: "/",
      onGenerateRoute: (settings) {
        late Widget page;
        if (settings.name == "/") {
          page = const Departures();
        } else if (settings.name!.startsWith("/singleDepartures")) {
          final args = settings.arguments as SingleStationDeparturesArguments;
          page = DeparturesSingleStationScreen(
            station: args.station,
            offsetInMinutes: args.offsetInMinutes,
          );
        } else if (settings.name == "/stationDetails") {
          var arguments =
              (settings.arguments as (Station, Future<List<TickerLine>?>));
          page = StationDetailsScreen(
              viewModel: StationDetailsViewModel(
                  station: arguments.$1,
                  repository: transitDataRepository));
        } else if (settings.name == "/stationZoom") {
          page = StationAccessibilityMapScreen(
              station: settings.arguments as Station);
        } else if (settings.name!.startsWith("/tickerDetails")) {
          final args = settings.arguments as List<Ticker>;
          page = TickerDetailsPage(tickers: args);
        } else if (settings.name!.startsWith("/map")) {
          final args = settings.arguments as Station;
          page = MapPage(station: args);
        } else {
          throw Exception('Unknown route: ${settings.name}');
        }

        return MaterialPageRoute<dynamic>(
          builder: (context) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: recentStations),
                ChangeNotifierProvider.value(value: settingsModel),
              ],
              child: page,
            );
          },
          settings: settings,
        );
      },
    );
    tickerPage = Navigator(
      key: keys[2],
      initialRoute: "/",
      onGenerateRoute: (settings) {
        late Widget page;
        if (settings.name == "/") {
          page = TickerPage(
            tickerProvider: tickerProvider,
          );
        } else if (settings.name!.startsWith("/tickerDetails")) {
          final args = settings.arguments as List<Ticker>;
          page = TickerDetailsPage(tickers: args);
        } else {
          throw Exception('Unknown route: ${settings.name}');
        }

        return MaterialPageRoute<dynamic>(
          builder: (context) {
            return page;
          },
          settings: settings,
        );
      },
    );
    mapPage = Navigator(
      //key: keys[3],
      initialRoute: "/",
      onGenerateRoute: (settings) {
        late Widget page;
        page = Placeholder();

        return MaterialPageRoute<dynamic>(
          builder: (context) {
            return ChangeNotifierProvider.value(
                value: settingsModel, child: page);
          },
          settings: settings,
        );
      },
    );

    initializeDateFormatting();
    addPolylineLicense();
  }

  void ensureMapPageInitialized() {
    if (!mapPageInitialized) {
      mapPageInitialized = true;
      setState(() {
        mapPage = Navigator(
          key: keys[3],
          initialRoute: "/",
          onGenerateRoute: (settings) {
            late Widget page;
            if (settings.name == "/") {
              page = MapPage();
            } else if (settings.name == "/stationDetails") {
              page = StationDetailsScreen(
                  viewModel: StationDetailsViewModel(
                      station: settings.arguments as Station,
                      repository: transitDataRepository));
            } else {
              throw Exception('Unknown route: ${settings.name}');
            }

            return MaterialPageRoute<dynamic>(
              builder: (context) {
                return ChangeNotifierProvider.value(
                    value: settingsModel, child: page);
              },
              settings: settings,
            );
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var tabs = [
      connectionPage,
      departuresPage,
      tickerPage,
      mapPage,
      LicensePage(),
    ];
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
      ],
      scrollBehavior: MyScrollBehavior(),
      theme: ThemeData(
        fontFamily: 'NotoSansCondensed',
        splashFactory: NoSplash.splashFactory,
        colorScheme: ColorScheme.light(
          background: Colors.white,
          surface: greyBg,
          surfaceBright: lightGrey,
          onSurface: Colors.black,
          primary: blueBg,
        ),
      ),
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          splashFactory: NoSplash.splashFactory,
          colorScheme: ColorScheme.dark(
            background: Colors.black,
            surface: const Color.fromARGB(255, 53, 53, 53),
            surfaceBright: const Color.fromARGB(255, 28, 28, 29),
            onSurface: Colors.white,
            primary: blueBg,
          )),
      // standard dark theme
      themeMode: ThemeMode.system,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: tickerProvider),
          ChangeNotifierProvider.value(value: favoritesProvider),
          Provider<TransitDataRepository>.value(
            value: transitDataRepository,
          ),
        ],
        child: Builder(builder: (context) {
          return DefaultTextStyle(
            style: TextStyle(fontWeight: FontWeight.w400),
            child: TextButtonTheme(
              data: TextButtonThemeData(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(0),
                  foregroundColor: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Theme.of(context).brightness,
                ),
                child: IconTheme(
                  data: IconThemeData(
                      color: Theme.of(context).colorScheme.onBackground),
                  child: AnnotatedRegion<SystemUiOverlayStyle>(
                    value: SystemUiOverlayStyle(
                      statusBarColor: blueBg,
                      statusBarBrightness: Brightness.dark, // iOS: white text
                      statusBarIconBrightness:
                          Brightness.light, // Android: white icons
                      systemNavigationBarColor: lightGrey,
                    ),
                    child: Container(
                      color: Theme.of(context).brightness == Brightness.light
                          ? blueBg
                          : Colors.black,
                      child: Scaffold(
                          //Prevent the InputSheet from covering the entire screen when the virtual keyboard is shown
                          resizeToAvoidBottomInset: false,
                          body: Container(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? blueBg
                                  : Colors.black,
                              child: SafeArea(
                                  child: Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .background,
                                      child: IndexedStack(
                                          index: tabIndex, children: tabs)))),
                          //),
                          bottomNavigationBar: CustomBottomNavigationBar(
                              tabIndex: tabIndex,
                              onTap: (value) {
                                if (tabIndex == value && tabIndex <= 2) {
                                  if (tabs[tabIndex] is Navigator) {
                                    //maybePop prevents popping too far to a black page
                                    (keys[tabIndex].currentState
                                            as NavigatorState?)
                                        ?.maybePop();
                                  }
                                }
                                if (value == 2) {
                                  // Load all ticker (including non-incidents) when navigating to the ticker page, unless all tickers have been loaded less than a minute ago
                                  if (DateTime.now().difference(tickerProvider
                                              .lastUpdate ??
                                          DateTime.fromMillisecondsSinceEpoch(
                                              0)) >=
                                      Duration(minutes: 1)) {
                                    tickerProvider.loadAllTickers();
                                  }
                                }
                                if (value == 3) {
                                  ensureMapPageInitialized();
                                }
                                setState(() {
                                  tabIndex = value;
                                });
                              })),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

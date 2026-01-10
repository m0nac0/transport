import 'package:flutter/material.dart' hide TickerProvider;
import 'package:provider/provider.dart';
import 'package:transport/data/ticker_provider.dart';
import 'package:transport/l10n/app_localizations.dart';
import 'package:transport/ui/util/colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar(
      {super.key, required this.onTap, required this.tabIndex});

  final Function(int index) onTap;
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: darkGrey, width: 0.5))),
      child: Consumer<TickerProvider>(
        builder: (context, TickerProvider tickerProvider, child) =>
            BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? const Color.fromARGB(255, 246, 246, 246)
              : const Color.fromARGB(255, 18, 18, 18),
          // Theme.of(context).colorScheme.surfaceBright,
          unselectedItemColor: const Color.fromARGB(255, 148, 149, 149),
          showUnselectedLabels: true,
          onTap: onTap,
          currentIndex: tabIndex,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.directions),
              label: AppLocalizations.of(context)!.route,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.departure_board),
              label: AppLocalizations.of(context)!.departures,
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text("${tickerProvider.tickerCount}"),
                isLabelVisible: tickerProvider.tickerCount != null &&
                    tickerProvider.tickerCount! > 0,
                child: const Icon(Icons.list),
              ),
              label: AppLocalizations.of(context)!.incidents,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map),
              label: AppLocalizations.of(context)!.map,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz),
              label: AppLocalizations.of(context)!.more,
            ),
          ],
        ),
      ),
    );
  }
}

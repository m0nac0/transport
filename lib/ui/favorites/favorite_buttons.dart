// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transport/data/favorites_provider.dart';
import 'package:transport/ui/components/custom_button_like.dart';

import '../util/colors.dart';
import '../../datamodel/location_input_model.dart';

import '../geolocation.dart';

/// The row of favorite station buttons
class FavoritesButtonsRow extends StatefulWidget {
  final void Function(LocationInput) onTap;
  final bool currentLocation;

  FavoritesButtonsRow(
      {super.key, required this.onTap, required this.currentLocation}) {}

  @override
  State<FavoritesButtonsRow> createState() => _FavoritesButtonsRowState();
}

class _FavoritesButtonsRowState extends State<FavoritesButtonsRow> {
  late final FavoritesProvider favoritesProvider;

  @override
  void initState() {
    super.initState();
    favoritesProvider = context.read<FavoritesProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: favoritesProvider,
      builder: (context, child) => Row(
        children: [
          ...favoritesProvider.favoriteButtons
              .map((e) => FavoriteButton(
                    icon: e.icon,
                    color: e.bgColor,
                    onTap: () => widget.onTap(e.station),
                    onLongPress: () {
                      Navigator.of(context)
                          .pushNamed("/addFavorite", arguments: e)
                          .then((_) => () {
                                favoritesProvider.loadFavoriteButtons();
                              }());
                    },
                  ))
              .expand((element) => [
                    element,
                    SizedBox(
                      width: 10,
                    )
                  ])
              .toList(),
          if (widget.currentLocation) ...[
            FavoriteButton(
                icon: Icons.location_on,
                color: Colors.white,
                borderColor: Colors.black,
                onTap: () async {
                  widget.onTap(LocationInputCurrentLocationLoading(
                      determinePositionOrShowSnackbar(context)));
                }),
            SizedBox(
              width: 10,
            ),
          ],
          FavoriteButton(
              icon: Icons.add,
              color: Colors.white,
              borderColor: blueBg,
              onTap: () {
                Navigator.of(context).pushNamed("/addFavorite").then((_) => () {
                      favoritesProvider.loadFavoriteButtons();
                    }());
              }),
        ],
      ),
    );
  }
}

void showSnackbar(context, String text) {
  var snackBar = SnackBar(
    content: Text(text),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

Future<(double lat, double lng)?> determinePositionOrShowSnackbar(
    BuildContext context) {
  return determinePosition(context).then((position) {
    return (position.latitude, position.longitude);
  }, onError: (error) {
    if (context.mounted) {
      showSnackbar(context, error.toString());
    }
    if (!kReleaseMode) {
      return Future.delayed(Duration(seconds: 5), () => (48.137079, 11.576006));
    } else {
      return null;
    }
  });
}

/// A single favorite station button
class FavoriteButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FavoriteButton(
      {super.key,
      required this.icon,
      required this.color,
      this.onTap,
      this.borderColor,
      this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return CustomButtonLike(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor ?? color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            icon,
            color: borderColor ?? (color == white ? blueBg : white),
            size: 20,
          ),
        ),
      ),
    );
  }
}

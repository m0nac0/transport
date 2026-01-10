import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transport/data/favorites_provider.dart';
import 'package:transport/datamodel/favorite_button_item.dart';
import 'package:transport/ui/util/colors.dart';
import 'package:transport/ui/components/animated_clear_button.dart';
import 'package:transport/ui/components/header.dart';

import '../../datamodel/location_input_model.dart';
import '../components/location_input_ui.dart';
import 'favorite_buttons.dart';

import 'package:transport/l10n/app_localizations.dart';

class AddFavoritePage extends StatefulWidget {
  final FavoriteButtonItem? itemToEdit;

  const AddFavoritePage({super.key, this.itemToEdit});


  @override
  State<AddFavoritePage> createState() => _AddFavoritePageState();
}

class IconPickerDialog extends StatefulWidget {
  final Color initialColor;

  const IconPickerDialog({super.key, required this.initialColor});

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  late Color selectedColor;

  Future<Color?> _openColorPicker() async {
    return await showDialog<Color>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
              title: Text(AppLocalizations.of(context)!.chooseColor),
              children: Colors.primaries
                  .map(
                    (color) => SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context, color);
                      },
                      child: Center(
                          child: CircleAvatar(
                        child: Container(
                          color: color,
                        ),
                      )),
                    ),
                  )
                  .toList());
        });
  }

  @override
  void initState() {
    selectedColor = widget.initialColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
        title: Text(AppLocalizations.of(context)!.chooseIcon),
        children: [
          Icons.favorite,
          Icons.home,
          Icons.school,
          Icons.work,
          Icons.child_care,
          Icons.train,
          Icons.subway,
          Icons.directions_bus,
          Icons.tram
        ]
            .map(
              (icon) => SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, (icon, selectedColor));
                },
                child: Center(
                    child: FavoriteButton(icon: icon, color: selectedColor)),
              ),
            )
            .toList()
          ..add(SimpleDialogOption(
            onPressed: openColorPicker,
            child: FilledButton(
              onPressed: openColorPicker,
              child: Text(AppLocalizations.of(context)!.changeColor),
            ),
          )));
  }

  void openColorPicker() async {
    _openColorPicker().then((color) {
      setState(() {
        selectedColor = color ?? Colors.white;
      });
    });
  }
}

class _AddFavoritePageState extends State<AddFavoritePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController stationController = TextEditingController();
  final TextEditingController stationController2 = TextEditingController();
  late final FavoritesProvider favoritesProvider;
  SpecificLocationInput? currentStation;
  IconData selectedIcon = Icons.favorite;
  Color selectedColor = Colors.white;

  Future<void> _openIconPicker() async {
    var result = await showDialog<(IconData, Color)>(
        context: context,
        builder: (BuildContext context) {
          return IconPickerDialog(
            initialColor: selectedColor,
          );
        });
    if (result != null) {
      var (IconData icon, Color color) = result;
      setState(() {
        selectedIcon = icon;
        selectedColor = color;
      });
    }
  }

  @override
  void initState() {
    super.initState();
      var favoritesProvider = context.read<FavoritesProvider>();

    if (widget.itemToEdit != null) {
      setState(() {
        nameController.text = widget.itemToEdit!.name;
        selectedIcon = widget.itemToEdit!.icon;
        selectedColor = widget.itemToEdit!.bgColor;
        updateSelectedLocationInput(widget.itemToEdit!.station);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    var divider = Divider(
      color: Theme.of(context).colorScheme.surface,
      height: 20,
      thickness: 1,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Header(
          title: AppLocalizations.of(context)?.addFavorite ?? "",
          showBackButton: true,
        ),
        ListenableBuilder(
          listenable: favoritesProvider,
          builder: (context, child) => Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(AppLocalizations.of(context)!.symbol),
                    const Spacer(),
                    FavoriteButton(
                        icon: selectedIcon,
                        color: selectedColor,
                        borderColor:
                            selectedColor == Colors.white ? blueBg : null,
                        onTap: () {
                          _openIconPicker();
                        }),
                  ]),
                  divider,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(AppLocalizations.of(context)!.name),
                      ),
                      Expanded(
                        child: AddFavoriteTextfield(
                          controller: nameController,
                          hint: AppLocalizations.of(context)!.enterYourName,
                        ),
                      ),
                    ],
                  ),
                  divider,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(AppLocalizations.of(context)!.address),
                      ),
                      Expanded(
                        child: AddFavoriteTextfield(
                          controller: stationController2,
                          hint: AppLocalizations.of(context)!.enterAddressHint,
                          enabled: false,
                          onTap: () async {
                            final LocationInput? newStation =
                                await InputSheet.openInputSheetForController(
                                    context, stationController, false, false);
                            updateSelectedLocationInput(
                                newStation as SpecificLocationInput?);
                          },
                        ),
                      ),
                    ],
                  ),
                  divider,
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (currentStation != null) {
                              if (widget.itemToEdit == null) {
                                favoritesProvider.addFavorite(
                                    FavoriteButtonItem(
                                        nameController.text,
                                        selectedIcon,
                                        selectedColor,
                                        currentStation!,
                                        DateTime.now()));
                              } else {
                                favoritesProvider.updateFavorite(
                                    widget.itemToEdit!.created,
                                    FavoriteButtonItem(
                                        nameController.text,
                                        selectedIcon,
                                        selectedColor,
                                        currentStation!,
                                        widget.itemToEdit!.created));
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          style: ButtonStyle(
                              shape: WidgetStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(6.0))),
                              foregroundColor: WidgetStateColor.resolveWith(
                                  (states) =>
                                      Theme.of(context).colorScheme.onSurface),
                              backgroundColor: WidgetStateColor.resolveWith(
                                  (states) =>
                                      Theme.of(context).colorScheme.surface)),
                          child: Text(AppLocalizations.of(context)!.save),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  if (widget.itemToEdit != null)
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              if (widget.itemToEdit == null) {
                                return;
                              }
                              favoritesProvider
                                  .removeFavorite(widget.itemToEdit!.created);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            style: ButtonStyle(
                                shape: WidgetStateProperty.all<
                                        RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.0))),
                                foregroundColor: WidgetStateColor.resolveWith(
                                    (states) => Colors.white),
                                backgroundColor: WidgetStateColor.resolveWith(
                                    (states) => Colors.red)),
                            child: Text(AppLocalizations.of(context)!.delete),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(AppLocalizations.of(context)!.favoritesNote,
                      style: TextStyle(
                        color: Colors.grey[700],
                      )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void updateSelectedLocationInput(SpecificLocationInput? newStation) {
    setState(() {
      currentStation = newStation;
      stationController2.text = newStation?.toLocationString() ?? "";
    });
  }
}

class AddFavoriteTextfield extends StatelessWidget {
  const AddFavoriteTextfield(
      {super.key,
      required this.controller,
      required this.hint,
      this.enabled = true,
      this.onTap});

  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    var border = OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.surface));
    return TextField(
      //enabled: enabled,
      textAlign: TextAlign.end,
      controller: controller,
      style: const TextStyle(fontSize: 15),
      readOnly: !enabled,
      onTap: onTap,
      decoration: InputDecoration(
        isDense: true,
        suffixIcon: AnimatedClearButton(controller: controller),
        hintText: hint,
        hintStyle: const TextStyle(color: darkGrey),
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border,
        fillColor: Theme.of(context).colorScheme.surfaceBright,
        filled: true,
      ),
    );
  }
}

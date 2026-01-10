// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:transport/datamodel/routes.dart';

class OccupancyIndicator extends StatelessWidget {
  const OccupancyIndicator({
    super.key,
    required this.occupancy,
  });

  final Occupancy occupancy;

  @override
  Widget build(BuildContext context) {
    const person_full = Image(
      image: AssetImage("assets/man_full.png"),
      height: 24,
    );
    const person_light = Image(
      image: AssetImage("assets/man_full.png"),
      height: 24,
      color: Colors.grey,
    );
    if (occupancy == Occupancy.UNKNOWN) return const SizedBox();
    return Row(
      children: [
        person_full,
        occupancy == Occupancy.MEDIUM || occupancy == Occupancy.HIGH
            ? person_full
            : person_light,
        occupancy == Occupancy.HIGH ? person_full : person_light
      ],
    );
  }
}

// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transport/l10n/app_localizations.dart';
import 'package:universal_io/io.dart';

String formatOnlyTime(DateTime dateTime) =>
    DateFormat.Hm(Platform.localeName).format(dateTime.toLocal());

String formatOnlyDate(DateTime dateTime) =>
    DateFormat.yMd(Platform.localeName).format(dateTime.toLocal());

String formatDateTime(DateTime dateTime) =>
    "${DateFormat.yMd(Platform.localeName).format(dateTime.toLocal())} ${DateFormat.Hm(Platform.localeName).format(dateTime.toLocal())}";

String formatDateTimeAuto(DateTime dateTime) {
  DateTime now = DateTime.now();
  if (now.day == dateTime.day &&
      now.month == dateTime.month &&
      now.year == dateTime.year) {
    return formatOnlyTime(dateTime);
  } else {
    return formatDateTime(dateTime);
  }
}

String formatDurationLocalized(Duration duration, BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final absMinutes = duration.inMinutes.abs();
  if (absMinutes < 1) return loc.now;
  if (absMinutes < 60) {
    final minutes = absMinutes.toString();
    return duration.isNegative ? loc.minutesAgo(minutes) : loc.inMinutes(minutes);
  }
  final hours = duration.abs().inHours.toString();
  final minutes = (duration.abs().inMinutes % 60).toString().padLeft(2, '0');
  return duration.isNegative
      ? loc.hoursAndMinutesAgo(hours, minutes)
      : loc.hoursAndMinutes(hours, minutes);
}

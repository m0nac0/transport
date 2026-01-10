// LICENSE: The decodePolyline function is taken from https://github.com/marchdev-tk/google_polyline_algorithm/blob/master/lib/src/google_polyline_algorithm.dart
// The license is also included in the LICENSE file in this folder
import 'dart:math' as math show pow;

import 'package:flutter/foundation.dart';

void addPolylineLicense() {
  LicenseRegistry.addLicense(() => Stream<LicenseEntry>.value(
      const LicenseEntryWithLineBreaks(["google_polyline_algorithm"], """
    BSD 3-Clause License

Copyright (c) 2021, MarchDev Toolkit
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.""")));
}

/// Decodes [polyline] `String` via inverted
/// [Encoded Polyline Algorithm](https://developers.google.com/maps/documentation/utilities/polylinealgorithm?hl=en)
List<List<num>>? decodePolyline(String? polyline, {int accuracyExponent = 5}) {
  if(polyline == null){
    return null;
  }
  final accuracyMultiplier = math.pow(10, accuracyExponent);
  final List<List<num>> coordinates = [];

  int index = 0;
  int lat = 0;
  int lng = 0;

  while (index < polyline.length) {
    int char;
    int shift = 0;
    int result = 0;

    /// Method for getting **only** `1` coorditane `latitude` or `longitude` at a time
    int getCoordinate() {
      /// Iterating while value is grater or equal of `32-bits` size
      do {
        /// Substract `63` from `codeUnit`.
        char = polyline.codeUnitAt(index++) - 63;

        /// `AND` each `char` with `0x1f` to get 5-bit chunks.
        /// Then `OR` each `char` with `result`.
        /// Then left-shift for `shift` bits
        result |= (char & 0x1f) << shift;
        shift += 5;
      } while (char >= 0x20);

      /// Inversion of both:
      ///
      ///  * Left-shift the `value` for one bit
      ///  * Inversion `value` if it is negative
      final value = result >> 1;
      final coordinateChange =
          (result & 1) != 0 ? (~BigInt.from(value)).toInt() : value;

      /// It is needed to clear `shift` and `result` for next coordinate.
      shift = result = 0;

      return coordinateChange;
    }

    lat += getCoordinate();
    lng += getCoordinate();

    coordinates.add([lat / accuracyMultiplier, lng / accuracyMultiplier]);
  }

  return coordinates;
}

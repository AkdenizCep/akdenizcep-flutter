import 'package:flutter/material.dart';

import 'ring_format.dart';

/// Hat rengi: ilk hat `primary`, ikinci hat `onSurface`. Yalnizca iki hat
/// desteklenir; ucuncusu icin palet tanimli degil, `onSurface`'e duser.
({Color fill, Color text}) lineColors(
  ColorScheme colorScheme,
  List<String> lines,
  String lineCode,
) {
  return lines.indexOf(lineCode) == 0
      ? (fill: colorScheme.primary, text: colorScheme.onPrimary)
      : (fill: colorScheme.onSurface, text: colorScheme.surface);
}

/// Dolu hat rozeti ("AÜ102").
class LineBadge extends StatelessWidget {
  final String lineCode;
  final List<String> lines;
  final double height;
  final double? width;
  final double radius;
  final double horizontalPadding;
  final double fontSize;

  const LineBadge({
    super.key,
    required this.lineCode,
    required this.lines,
    this.height = 22,
    this.width,
    this.radius = 7,
    this.horizontalPadding = 7,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final colors = lineColors(Theme.of(context).colorScheme, lines, lineCode);

    return Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        lineLabel(lineCode),
        maxLines: 1,
        style: TextStyle(
          color: colors.text,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

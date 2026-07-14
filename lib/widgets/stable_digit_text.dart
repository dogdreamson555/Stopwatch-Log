import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Renders every digit in a cell sized for the widest digit in [style].
///
/// Some imported fonts do not support tabular figures. Giving each digit the
/// same measured cell width keeps a surrounding [FittedBox] from choosing a
/// different scale whenever the displayed value changes.
class StableDigitText extends StatefulWidget {
  final String value;
  final TextStyle style;

  const StableDigitText({super.key, required this.value, required this.style});

  @override
  State<StableDigitText> createState() => _StableDigitTextState();
}

class _StableDigitTextState extends State<StableDigitText> {
  TextStyle? _measuredStyle;
  TextDirection? _measuredDirection;
  TextScaler? _measuredScaler;
  Locale? _measuredLocale;
  Size? _digitCellSize;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.maybeLocaleOf(context);
    final cellSize = _cellSizeFor(
      style: widget.style,
      direction: direction,
      scaler: scaler,
      locale: locale,
    );
    final digits = widget.value.runes
        .map(String.fromCharCode)
        .toList(growable: false);

    return Semantics(
      label: widget.value,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            for (final digit in digits)
              SizedBox(
                width: cellSize.width,
                height: cellSize.height,
                child: Center(
                  child: Text(
                    digit,
                    maxLines: 1,
                    softWrap: false,
                    textDirection: TextDirection.ltr,
                    textScaler: scaler,
                    locale: locale,
                    style: widget.style,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Size _cellSizeFor({
    required TextStyle style,
    required TextDirection direction,
    required TextScaler scaler,
    required Locale? locale,
  }) {
    if (_digitCellSize != null &&
        _measuredStyle == style &&
        _measuredDirection == direction &&
        _measuredScaler == scaler &&
        _measuredLocale == locale) {
      return _digitCellSize!;
    }

    var maxWidth = 0.0;
    var maxHeight = 0.0;
    for (var digit = 0; digit <= 9; digit++) {
      final painter = TextPainter(
        text: TextSpan(text: '$digit', style: style),
        maxLines: 1,
        textDirection: direction,
        textScaler: scaler,
        locale: locale,
      )..layout();
      maxWidth = math.max(maxWidth, painter.width);
      maxHeight = math.max(maxHeight, painter.height);
    }

    _measuredStyle = style;
    _measuredDirection = direction;
    _measuredScaler = scaler;
    _measuredLocale = locale;
    _digitCellSize = Size(maxWidth.ceilToDouble(), maxHeight.ceilToDouble());
    return _digitCellSize!;
  }
}

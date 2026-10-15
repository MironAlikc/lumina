import 'package:flutter/material.dart';

abstract final class LuminaDimensions {
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 28.0;

  // const: не создаются заново и годятся для const-виджетов.
  static const BorderRadius borderRadiusSmall =
      BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusMedium =
      BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusLarge =
      BorderRadius.all(Radius.circular(radiusLarge));

  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 20.0;
  static const double paddingXL = 24.0;

  static const double buttonHeight = 52.0;
  static const double inputHeight = 52.0;
}

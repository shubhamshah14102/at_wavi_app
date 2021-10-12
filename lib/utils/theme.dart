import 'package:at_wavi_app/utils/colors.dart';
import 'package:flutter/material.dart';

class Themes {
  static ThemeData lightTheme({
    Color highlightColor = ColorConstants.green,
    String? fontFamily,
  }) {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: ColorConstants.black,
      canvasColor: Colors.white,
      highlightColor: highlightColor,
      scaffoldBackgroundColor: ColorConstants.white,
      fontFamily: fontFamily ?? 'HelveticaNeu',
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData darkTheme({
    Color highlightColor = ColorConstants.green,
    String? fontFamily,
  }) {
    return ThemeData(
      brightness: Brightness.dark,
      canvasColor: Colors.white,
      primaryColor: ColorConstants.white,
      highlightColor: highlightColor,
      scaffoldBackgroundColor: ColorConstants.black,
      fontFamily: fontFamily ?? 'HelveticaNeu',
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

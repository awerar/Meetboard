import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color green = Color(0xffa6cb00);
const Color red = Color(0xfff53601);

ThemeData getTheme() {
  ColorScheme colorScheme = ColorScheme(
      primary: Color(0xfff5b001),
      primaryVariant: Color(0xffbd8100),
      onPrimary: Colors.black,

      secondary: Color(0xff0146f5),
      secondaryVariant: Color(0xff001ec1),
      onSecondary: Colors.white,

      background: Colors.white,
      onBackground: Colors.grey,

      surface: Colors.white,
      onSurface: Colors.black,

      error: red,
      onError: Colors.white,

      brightness: Brightness.light
  );

  return ThemeData(
    colorScheme: colorScheme,
    primaryColor: colorScheme.primary,
    primaryColorLight: Color(0xffffe24b),
    primaryColorDark: colorScheme.secondaryVariant,
    accentColor: colorScheme.secondary,

    brightness: Brightness.light,
    fontFamily: GoogleFonts.openSans().fontFamily
  );
}
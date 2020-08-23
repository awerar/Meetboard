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
      onBackground: Colors.black,

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

    //Arvo & Source Sans Pro
    textTheme: TextTheme(
      headline1: GoogleFonts.arvo(
          fontSize: 101,
          fontWeight: FontWeight.w300,
          letterSpacing: -1.5
      ),
      headline2: GoogleFonts.arvo(
          fontSize: 63,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5
      ),
      headline3: GoogleFonts.arvo(
          fontSize: 50,
          fontWeight: FontWeight.w400
      ),
      headline4: GoogleFonts.arvo(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25
      ),
      headline5: GoogleFonts.arvo(
          fontSize: 25,
          fontWeight: FontWeight.w400
      ),
      headline6: GoogleFonts.arvo(
          fontSize: 21,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15
      ),
      subtitle1: GoogleFonts.arvo(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15
      ),
      subtitle2: GoogleFonts.arvo(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1
      ),
      bodyText1: GoogleFonts.sourceSansPro(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5
      ),
      bodyText2: GoogleFonts.sourceSansPro(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25
      ),
      button: GoogleFonts.sourceSansPro(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25
      ),
      caption: GoogleFonts.sourceSansPro(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4
      ),
      overline: GoogleFonts.sourceSansPro(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.5
      ),
    )
  );
}
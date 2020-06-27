import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final _colors = <Color>[
  Color(0xff264653),
  Color(0xff2a9d8f),
  Color(0xffe9c46a),
  Color(0xfff4a261),
  Color(0xffe76f51)
];

ColorScheme _normalColorScheme = ColorScheme(
  brightness: Brightness.dark,

  error: _colors[0],
  onError: _colors[0],

  background: _colors[0],
  onBackground: _colors[0],

  primary: _colors[0],
  onPrimary: _colors[0],
  primaryVariant: _colors[0],

  secondary: _colors[0],
  onSecondary: _colors[0],
  secondaryVariant: _colors[0],

  surface: _colors[0],
  onSurface: _colors[0],
);

ThemeData getTheme() {
  return ThemeData(
    textTheme: TextTheme(
      headline1: GoogleFonts.aBeeZee(textStyle: TextStyle(inherit: false), fontSize: 25),
      button: GoogleFonts.aBeeZee(textStyle: TextStyle(inherit: false), fontSize: 18),
    ),
    primarySwatch: Colors.teal
  );
}
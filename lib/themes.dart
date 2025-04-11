import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  textTheme: GoogleFonts.interTextTheme(),
  colorScheme: lightColorScheme,
);

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  textTheme: GoogleFonts.interTextTheme(),
  colorScheme: darkColorScheme,
);

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xff570b90),
  surfaceTint: Color(0xff4c662b),
  onPrimary: Color(0xffffffff),
  primaryContainer: Color(0xfff3fff0),
  onPrimaryContainer: Color(0xff211b69),
  secondary: Color(0xff586249),
  onSecondary: Color(0xffffffff),
  secondaryContainer: Color(0xffF5F6FF),
  onSecondaryContainer: Color(0xff151e0b),
  tertiary: Color(0xffebdaff),
  onTertiary: Color(0xfffff0f0),
  tertiaryContainer: Color(0xffF5F6FF),
  onTertiaryContainer: Color(0xff00201e),
  error: Color(0xffba1a1a),
  onError: Color(0xffffffff),
  errorContainer: Color(0xffffdad6),
  onErrorContainer: Color(0xff410002),
  surface: Color(0xfff9f9f9),
  onSurface: Color(0xff1a1c16),
  onSurfaceVariant: Color(0xff44483d),
  outline: Color(0xff75796c),
  outlineVariant: Color(0xffc5c8ba),
  shadow: Color(0x668C8B8B),
  scrim: Color(0xff000000),
  inverseSurface: Color(0xfffff3ca),
  inversePrimary: Color(0xff230ba1),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xffb1d18a),
  surfaceTint: Color(0xffb1d18a),
  onPrimary: Color(0xff1f3701),
  primaryContainer: Color(0xff354e16),
  onPrimaryContainer: Color(0xffcdeda3),
  secondary: Color(0xffbfcbad),
  onSecondary: Color(0xff2a331e),
  secondaryContainer: Color(0xff404a33),
  onSecondaryContainer: Color(0xffdce7c8),
  tertiary: Color(0xffa0d0cb),
  onTertiary: Color(0xff003735),
  tertiaryContainer: Color(0xff1f4e4b),
  onTertiaryContainer: Color(0xffbcece7),
  error: Color(0xffffb4ab),
  onError: Color(0xff690005),
  errorContainer: Color(0xff93000a),
  onErrorContainer: Color(0xffffdad6),
  surface: Color(0xff12140e),
  onSurface: Color(0xffe2e3d8),
  onSurfaceVariant: Color(0xffc5c8ba),
  outline: Color(0xff8f9285),
  outlineVariant: Color(0xff44483d),
  shadow: Color(0xff000000),
  scrim: Color(0xff000000),
  inverseSurface: Color(0xffe2e3d8),
  inversePrimary: Color(0xff4c662b),
);

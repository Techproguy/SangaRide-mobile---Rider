import 'package:flutter/material.dart';
import 'package:sanga_ride/core/colors.dart';
import 'package:sanga_ride/core/constants.dart';

const double kGlobalLetterSpacing = -0.2;
const double kGlobalLineHeight = 1.2;

class SangaTheme {
  SangaTheme._();

  static const _textStyle = TextStyle(letterSpacing: kGlobalLetterSpacing, height: kGlobalLineHeight);

  static final ThemeData appTheme = ThemeData(
    fontFamily: SangaConstants.fontFamily,
    scaffoldBackgroundColor: SangaColors.white,
    appBarTheme: AppBarTheme(backgroundColor: SangaColors.white, surfaceTintColor: SangaColors.white.shade700),
    tabBarTheme: TabBarThemeData(
      tabAlignment: TabAlignment.start,
      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
      labelColor: SangaColors.black,
      unselectedLabelColor: SangaColors.gray,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
      indicatorColor: SangaColors.accent,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: SangaColors.lineLight,
    ),
    textTheme: const TextTheme(
      displayLarge: _textStyle,
      displayMedium: _textStyle,
      displaySmall: _textStyle,
      headlineLarge: _textStyle,
      headlineMedium: _textStyle,
      headlineSmall: _textStyle,
      titleLarge: _textStyle,
      titleMedium: _textStyle,
      titleSmall: _textStyle,
      bodyLarge: _textStyle,
      bodyMedium: _textStyle,
      bodySmall: _textStyle,
      labelLarge: _textStyle,
      labelMedium: _textStyle,
      labelSmall: _textStyle,
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: SangaColors.accent),
    inputDecorationTheme: InputDecorationThemeData(border: OutlineInputBorder(borderRadius: BorderRadius.circular(0))),
    dividerTheme: DividerThemeData(color: SangaColors.lightGray.withValues(alpha: 0.4), thickness: 3),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        textStyle: const TextStyle(fontFamily: SangaConstants.fontFamily, fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontFamily: SangaConstants.fontFamily, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

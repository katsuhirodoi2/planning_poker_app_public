import 'package:flutter/material.dart';

final ThemeData defaultTheme = ThemeData(
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 40,
      fontWeight: FontWeight.w600,
      color: Color(0xFF14181B),
    ),
    displayMedium: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: Color(0xFF14181B),
    ),
    displaySmall: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Color(0xFF14181B),
    ),
    headlineLarge: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 36,
      fontWeight: FontWeight.w400,
      color: Color(0xFF14181B),
    ),
    headlineMedium: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 24,
      fontWeight: FontWeight.w400,
      color: Color(0xFF14181B),
    ),
    headlineSmall: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Color(0xFF14181B),
    ),
    titleLarge: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 22,
      fontWeight: FontWeight.w400,
      color: Color(0xFF14181B),
    ),
    titleMedium: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 20,
      fontWeight: FontWeight.w400,
      color: Color(0xFF14181B),
    ),
    titleSmall: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFF14181B),
    ),
    labelLarge: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 20,
      fontWeight: FontWeight.w400,
      color: Color(0xFF57636C),
    ),
    labelMedium: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFF57636C),
    ),
    labelSmall: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Color(0xFF57636C),
    ),
    bodyLarge: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Color(0xFF14181B),
    ),
    bodyMedium: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFF14181B),
    ),
    bodySmall: TextStyle(
      fontFamily: 'M PLUS 1',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Color(0xFF14181B),
    ),
  ),
);

final ThemeData smartPhoneTheme = defaultTheme.copyWith(
  textTheme: defaultTheme.textTheme.copyWith(
    displayLarge: defaultTheme.textTheme.displayLarge?.copyWith(fontSize: 38),
    displayMedium: defaultTheme.textTheme.displayMedium?.copyWith(fontSize: 30),
    displaySmall: defaultTheme.textTheme.displaySmall?.copyWith(fontSize: 22),
    headlineLarge: defaultTheme.textTheme.headlineLarge?.copyWith(fontSize: 34),
    headlineMedium:
        defaultTheme.textTheme.headlineMedium?.copyWith(fontSize: 18),
    headlineSmall: defaultTheme.textTheme.headlineSmall?.copyWith(fontSize: 14),
    titleLarge: defaultTheme.textTheme.titleLarge?.copyWith(fontSize: 18),
    titleMedium: defaultTheme.textTheme.titleMedium?.copyWith(fontSize: 18),
    titleSmall: defaultTheme.textTheme.titleSmall?.copyWith(fontSize: 12),
    labelLarge: defaultTheme.textTheme.labelLarge?.copyWith(fontSize: 18),
    labelMedium: defaultTheme.textTheme.labelMedium?.copyWith(fontSize: 12),
    labelSmall: defaultTheme.textTheme.labelSmall?.copyWith(fontSize: 10),
    bodyLarge: defaultTheme.textTheme.bodyLarge?.copyWith(fontSize: 14),
    bodyMedium: defaultTheme.textTheme.bodyMedium?.copyWith(fontSize: 12),
    bodySmall: defaultTheme.textTheme.bodySmall?.copyWith(fontSize: 10),
  ),
);

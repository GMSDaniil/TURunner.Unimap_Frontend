import 'package:flutter/material.dart';

class AppTheme {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF833AB4), Color(0xFFFF5E3A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static final appTheme = ThemeData(
    primaryColor: const Color(0xff3461FD),
    scaffoldBackgroundColor: Colors.white,
    brightness: Brightness.light,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.black87,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xffF5F9FE),

      hintStyle: const TextStyle(
        // color: Color.fromARGB(255, 160, 126, 124), //Color(0xff7C8BA0)
        color: Colors.grey,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[500],
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    colorScheme: ColorScheme.fromSwatch(brightness: Brightness.light).copyWith(
      primary: const Color(0xFF833AB4),
      secondary: Color(0xFFFF5E3A),
      surface: const Color(0xff1E1E2C),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.black,
    ),
  );
}

extension CustomTheme on ThemeData {
  LinearGradient get primaryGradient => AppTheme.primaryGradient;
}

import 'package:flutter/material.dart';

class AppTheme {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF833AB4), Color(0xFFFF5E3A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ✅ Dark theme gradient
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [Color(0xFF9C4DCF), Color(0xFFFF7043)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Color lightPrimary = Color(0xFF833AB4);
  static const Color lightSecondary = Color(0xFFFF5E3A);
  static const Color darkPrimary = Color(0xFF9C4DCF);
  static const Color darkSecondary = Color(0xFFFF7043);

  // ✅ Light Theme
  static final ThemeData lightTheme = ThemeData(
    fontFamily: 'Nunito',
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
      secondary: const Color(0xFFFF5E3A),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
    ),
  );

  // ✅ Dark Theme
  static final ThemeData darkTheme = ThemeData(
    fontFamily: 'Nunito',
    primaryColor: const Color(0xFF9C4DCF),
    scaffoldBackgroundColor: const Color(0xFF121212),
    brightness: Brightness.dark,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF2C2C2C),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      hintStyle: const TextStyle(
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
        backgroundColor: const Color(0xFF833AB4),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
      primary: const Color(0xFF9C4DCF),
      secondary: const Color(0xFFFF7043),
      surface: const Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),
  );

  // ✅ Keep backward compatibility
  static ThemeData get appTheme => lightTheme;
}

extension CustomTheme on ThemeData {
  LinearGradient get primaryGradient => 
      brightness == Brightness.dark 
          ? AppTheme.darkPrimaryGradient 
          : AppTheme.primaryGradient;
          
  List<Color> get gradientColors => [
    colorScheme.primary,
    colorScheme.secondary,
  ];
}
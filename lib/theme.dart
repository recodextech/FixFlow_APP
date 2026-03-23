import 'package:flutter/material.dart';

class AppColors {
  static const blue = Color(0xFF1565C0);
  static const blueLight = Color(0xFF1E88E5);
  static const bluePale = Color(0xFFE3F2FD);
  static const blueMid = Color(0xFF42A5F5);

  static const green = Color(0xFF2E7D32);
  static const greenLight = Color(0xFF43A047);
  static const greenPale = Color(0xFFE8F5E9);

  static const orange = Color(0xFFE65100);
  static const orangePale = Color(0xFFFFF3E0);

  static const red = Color(0xFFC62828);
  static const redPale = Color(0xFFFFEBEE);

  static const gray0 = Color(0xFFF8F9FA);
  static const gray1 = Color(0xFFF1F3F5);
  static const gray2 = Color(0xFFE9ECEF);
  static const gray3 = Color(0xFFDEE2E6);
  static const gray4 = Color(0xFFCED4DA);
  static const gray5 = Color(0xFFADB5BD);
  static const gray6 = Color(0xFF6C757D);
  static const gray7 = Color(0xFF495057);

  static const text = Color(0xFF1C2833);
  static const text2 = Color(0xFF5D6D7E);
  static const text3 = Color(0xFF99A3A4);

  static const workerGradient = [
    Color(0xFF1B5E20),
    Color(0xFF2E7D32),
    Color(0xFF43A047),
  ];

  static const contractorGradient = [
    Color(0xFF0D47A1),
    Color(0xFF1565C0),
    Color(0xFF1E88E5),
  ];

  static const loginGradient = [
    Color(0xFF0D47A1),
    Color(0xFF1565C0),
    Color(0xFF1E88E5),
    Color(0xFF42A5F5),
  ];

  static const contractorOrangeGradient = [
    Color(0xFFE8881C),
    Color(0xFFF59E2D),
    Color(0xFFFBB03B),
  ];
}

ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.gray0,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.gray2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.gray1,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.gray3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.gray3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

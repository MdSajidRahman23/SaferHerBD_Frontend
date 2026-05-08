import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.green,
          secondary: AppColors.red,
          surface: AppColors.card,
          onPrimary: Colors.white,
          onSurface: AppColors.ink,
        ),
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        dividerColor: AppColors.line,
      );
}

class AppText {
  static TextStyle en({double size = 14, FontWeight w = FontWeight.w500,
      Color? color, double? letterSpacing, double? height}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: w,
          color: color ?? AppColors.ink, letterSpacing: letterSpacing, height: height);

  static TextStyle bn({double size = 14, FontWeight w = FontWeight.w500,
      Color? color, double? height}) =>
      GoogleFonts.hindSiliguri(fontSize: size, fontWeight: w,
          color: color ?? AppColors.ink, height: height);

  static TextStyle mono({double size = 12, Color? color}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, color: color ?? AppColors.ink);
}

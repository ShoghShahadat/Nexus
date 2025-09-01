import 'package:flutter/material.dart';

/// کلاس متمرکز برای تعریف تم‌های برنامه.
class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.deepPurple,
    scaffoldBackgroundColor: const Color(0xFFF4F7FC),
    fontFamily: 'Inter',
    // FIX: Changed CardTheme to CardThemeData to match the required type.
    // اصلاح: نوع CardTheme به CardThemeData برای تطابق با نوع مورد نیاز، تغییر کرد.
    cardTheme: CardThemeData(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: const EdgeInsets.all(8.0),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
      headlineSmall: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87),
      titleLarge: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
      bodySmall: TextStyle(fontSize: 14, color: Colors.black54),
      labelSmall: TextStyle(
          fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500),
    ),
    iconTheme: const IconThemeData(
      color: Colors.deepPurple,
      size: 28,
    ),
  );
}

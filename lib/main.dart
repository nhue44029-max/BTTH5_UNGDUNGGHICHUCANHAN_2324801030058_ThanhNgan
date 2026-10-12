import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MayNoteApp());
}

class MayNoteApp extends StatelessWidget {
  const MayNoteApp({super.key});

  static const Color primaryBlue = Color(0xFF477CE0);
  static const Color primaryText = Color(0xFF34436C);
  static const Color secondaryText = Color(0xFF7280A0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MâyNote',
      color: const Color(0xFFCDEBFF),
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.light,
        ).copyWith(surface: Colors.white, onSurface: primaryText),
        canvasColor: const Color(0xFFCDEBFF),
        scaffoldBackgroundColor: const Color(0xFFCDEBFF),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: primaryText,
          displayColor: primaryText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: primaryText,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.82),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: primaryBlue, width: 1.6),
          ),
          labelStyle: const TextStyle(color: secondaryText),
          prefixIconColor: secondaryText,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

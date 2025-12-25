import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum for the overall app theme
enum AppTheme { system, light, dark }

// Enum for the map's visual type
enum MapDisplayType { normal, satellite }

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  // Notifier for the app theme (Light, Dark, or System)
  final ValueNotifier<AppTheme> appThemeNotifier = ValueNotifier(AppTheme.system);

  // Notifier for the map type (Normal or Satellite)
  final ValueNotifier<MapDisplayType> mapTypeNotifier = ValueNotifier(MapDisplayType.normal);

  // --- App Theme Methods ---
  Future<void> loadAppTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('app_theme') ?? AppTheme.system.name;
    appThemeNotifier.value = AppTheme.values.firstWhere(
          (e) => e.name == themeName,
      orElse: () => AppTheme.system,
    );
  }

  Future<void> setAppTheme(AppTheme choice) async {
    appThemeNotifier.value = choice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', choice.name);
  }

  // --- Map Type Methods ---
  Future<void> loadMapType() async {
    final prefs = await SharedPreferences.getInstance();
    final mapTypeName = prefs.getString('map_type') ?? MapDisplayType.normal.name;
    mapTypeNotifier.value = MapDisplayType.values.firstWhere(
          (e) => e.name == mapTypeName,
      orElse: () => MapDisplayType.normal,
    );
  }

  Future<void> setMapType(MapDisplayType choice) async {
    mapTypeNotifier.value = choice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('map_type', choice.name);
  }
}
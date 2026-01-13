import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme modes
enum ThemeModeType { system, light, dark }

// Theme colors
enum ThemeColor {
  blue(Colors.blue, 'Blue'),
  purple(Colors.purple, 'Purple'),
  teal(Colors.teal, 'Teal'),
  orange(Colors.orange, 'Orange'),
  pink(Colors.pink, 'Pink'),
  indigo(Colors.indigo, 'Indigo');

  final Color color;
  final String displayName;
  const ThemeColor(this.color, this.displayName);
}

// Font sizes
enum FontSize {
  small(14.0, 'Small'),
  medium(16.0, 'Medium'),
  large(18.0, 'Large'),
  extraLarge(20.0, 'Extra Large');

  final double value;
  final String displayName;
  const FontSize(this.value, this.displayName);
}

// Theme settings model
class ThemeSettings {
  final ThemeModeType themeMode;
  final ThemeColor themeColor;
  final FontSize fontSize;
  final bool syncWithProfile;

  ThemeSettings({
    required this.themeMode,
    required this.themeColor,
    required this.fontSize,
    required this.syncWithProfile,
  });

  ThemeSettings copyWith({
    ThemeModeType? themeMode,
    ThemeColor? themeColor,
    FontSize? fontSize,
    bool? syncWithProfile,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      themeColor: themeColor ?? this.themeColor,
      fontSize: fontSize ?? this.fontSize,
      syncWithProfile: syncWithProfile ?? this.syncWithProfile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'themeColor': themeColor.index,
      'fontSize': fontSize.index,
      'syncWithProfile': syncWithProfile,
    };
  }

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      themeMode: ThemeModeType.values[json['themeMode'] as int],
      themeColor: ThemeColor.values[json['themeColor'] as int],
      fontSize: FontSize.values[json['fontSize'] as int],
      syncWithProfile: json['syncWithProfile'] as bool,
    );
  }
}

// Default settings
ThemeSettings defaultThemeSettings = ThemeSettings(
  themeMode: ThemeModeType.system,
  themeColor: ThemeColor.blue,
  fontSize: FontSize.medium,
  syncWithProfile: true,
);

// Provider for theme settings
final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
      (ref) => ThemeSettingsNotifier(),
    );

class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  ThemeSettingsNotifier() : super(defaultThemeSettings) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('theme_settings');

      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        state = ThemeSettings.fromJson(settingsMap);
      }
    } catch (e) {
      print('Error loading theme settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(state.toJson());
      await prefs.setString('theme_settings', settingsJson);
    } catch (e) {
      print('Error saving theme settings: $e');
    }
  }

  void setThemeMode(ThemeModeType mode) {
    state = state.copyWith(themeMode: mode);
    _saveSettings();
  }

  void setThemeColor(ThemeColor color) {
    state = state.copyWith(themeColor: color);
    _saveSettings();
  }

  void setFontSize(FontSize size) {
    state = state.copyWith(fontSize: size);
    _saveSettings();
  }

  void setSyncWithProfile(bool sync) {
    state = state.copyWith(syncWithProfile: sync);
    _saveSettings();
  }

  void resetToDefaults() {
    state = defaultThemeSettings;
    _saveSettings();
  }
}

// Provider for MaterialApp theme
final appThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  final isDark = _isDarkMode(settings.themeMode);

  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: settings.themeColor.color,
    brightness: isDark ? Brightness.dark : Brightness.light,
    textTheme: TextTheme(
      bodyLarge: TextStyle(fontSize: settings.fontSize.value),
      bodyMedium: TextStyle(fontSize: settings.fontSize.value),
      displayLarge: TextStyle(fontSize: settings.fontSize.value + 4),
      displayMedium: TextStyle(fontSize: settings.fontSize.value + 2),
      labelLarge: TextStyle(fontSize: settings.fontSize.value),
    ),
  );
});

bool _isDarkMode(ThemeModeType mode) {
  switch (mode) {
    case ThemeModeType.light:
      return false;
    case ThemeModeType.dark:
      return true;
    case ThemeModeType.system:
    default:
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
  }
}

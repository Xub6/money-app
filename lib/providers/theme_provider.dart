import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  int _accentIndex = 0;
  Locale _locale = const Locale('zh', 'TW');
  SharedPreferences? _prefs;

  bool get isDarkMode => _isDarkMode;
  int get accentIndex => _accentIndex;
  Locale get locale => _locale;

  static const List<Color> accentColors = [
    Color(0xFFC59B63), // 金（預設）
    Color(0xFF5C6BC0), // 靛藍
    Color(0xFF009688), // 青綠
    Color(0xFFE91E63), // 玫瑰
    Color(0xFF43A047), // 森林綠
  ];

  Color get accentColor => accentColors[_accentIndex];

  ThemeProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs?.getBool('isDarkMode') ?? false;
    _accentIndex = (_prefs?.getInt('accentIndex') ?? 0).clamp(0, accentColors.length - 1);
    final langCode = _prefs?.getString('languageCode') ?? 'zh';
    final countryCode = _prefs?.getString('countryCode') ?? 'TW';
    _locale = Locale(langCode, countryCode);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs?.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setAccent(int index) async {
    _accentIndex = index.clamp(0, accentColors.length - 1);
    await _prefs?.setInt('accentIndex', _accentIndex);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs?.setString('languageCode', locale.languageCode);
    await _prefs?.setString('countryCode', locale.countryCode ?? 'TW');
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.light,
        ),
      );

  ThemeData get darkTheme {
    if (_accentIndex == 0) return _darkGoldTheme;
    return _buildDarkAccentTheme(accentColor);
  }

  static ThemeData _buildDarkAccentTheme(Color accent) {
    final seed = ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        surface: const Color(0xFF111111),
        surfaceContainerLowest: const Color(0xFF0A0A0A),
        surfaceContainerLow: const Color(0xFF1C1C1E),
        surfaceContainer: const Color(0xFF242426),
        surfaceContainerHigh: const Color(0xFF2C2C2E),
        surfaceContainerHighest: const Color(0xFF3A3A3C),
        primary: seed.primary,
        onPrimary: seed.onPrimary,
        primaryContainer: seed.primaryContainer,
        onPrimaryContainer: seed.onPrimaryContainer,
        secondary: seed.secondary,
        onSecondary: seed.onSecondary,
        secondaryContainer: seed.secondaryContainer,
        onSecondaryContainer: seed.onSecondaryContainer,
        tertiary: const Color(0xFF30D158),
        onTertiary: const Color(0xFF001A08),
        tertiaryContainer: const Color(0xFF003811),
        onTertiaryContainer: const Color(0xFFB7F1C8),
        error: const Color(0xFFFF453A),
        onError: const Color(0xFF1A0000),
        errorContainer: const Color(0xFF4A0010),
        onErrorContainer: const Color(0xFFFFDAD6),
        onSurface: const Color(0xFFE5E5E7),
        onSurfaceVariant: const Color(0xFF8E8E93),
        outline: const Color(0xFF48484A),
        outlineVariant: const Color(0xFF2C2C2E),
        inverseSurface: const Color(0xFFE5E5E7),
        onInverseSurface: const Color(0xFF111111),
        inversePrimary: seed.inversePrimary,
        shadow: const Color(0xFF000000),
        scrim: const Color(0xFF000000),
        surfaceTint: accent,
      ),
    );
  }

  static final ThemeData _darkGoldTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      surface: Color(0xFF111111),
      surfaceContainerLowest: Color(0xFF0A0A0A),
      surfaceContainerLow: Color(0xFF1C1C1E),
      surfaceContainer: Color(0xFF242426),
      surfaceContainerHigh: Color(0xFF2C2C2E),
      surfaceContainerHighest: Color(0xFF3A3A3C),
      primary: Color(0xFFD4AA70),
      onPrimary: Color(0xFF1A1000),
      primaryContainer: Color(0xFF3D2C00),
      onPrimaryContainer: Color(0xFFFFDFA0),
      onSurface: Color(0xFFE5E5E7),
      onSurfaceVariant: Color(0xFF8E8E93),
      outline: Color(0xFF48484A),
      outlineVariant: Color(0xFF2C2C2E),
      error: Color(0xFFFF453A),
      onError: Color(0xFF1A0000),
      errorContainer: Color(0xFF4A0010),
      onErrorContainer: Color(0xFFFFDAD6),
      secondary: Color(0xFFAEAEB2),
      onSecondary: Color(0xFF1C1C1E),
      secondaryContainer: Color(0xFF2C2C2E),
      onSecondaryContainer: Color(0xFFE5E5E7),
      tertiary: Color(0xFF30D158),
      onTertiary: Color(0xFF001A08),
      tertiaryContainer: Color(0xFF003811),
      onTertiaryContainer: Color(0xFFB7F1C8),
      inverseSurface: Color(0xFFE5E5E7),
      onInverseSurface: Color(0xFF111111),
      inversePrimary: Color(0xFF7A5C2E),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      surfaceTint: Color(0xFFD4AA70),
    ),
  );
}

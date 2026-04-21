import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple theme provider
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  SharedPreferences? _prefs;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs?.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs?.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFC59B63),
      brightness: Brightness.light,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,

      // 背景層次（參考 iOS/Material3 標準：從深到淺）
      surface:                    Color(0xFF111111), // 主背景
      surfaceContainerLowest:     Color(0xFF0A0A0A),
      surfaceContainerLow:        Color(0xFF1C1C1E), // 卡片（iOS Dark）
      surfaceContainer:           Color(0xFF242426),
      surfaceContainerHigh:       Color(0xFF2C2C2E),
      surfaceContainerHighest:    Color(0xFF3A3A3C),

      // 主色（金）：深色模式下稍微亮一點保持對比
      primary:                    Color(0xFFD4AA70),
      onPrimary:                  Color(0xFF1A1000),
      primaryContainer:           Color(0xFF3D2C00),
      onPrimaryContainer:         Color(0xFFFFDFA0),

      // 文字
      onSurface:                  Color(0xFFE5E5E7), // 主文字（接近白，不刺眼）
      onSurfaceVariant:           Color(0xFF8E8E93), // 次要文字（iOS Grey）

      // 輪廓
      outline:                    Color(0xFF48484A),
      outlineVariant:             Color(0xFF2C2C2E),

      // 語意色
      error:                      Color(0xFFFF453A), // iOS Red dark
      onError:                    Color(0xFF1A0000),
      errorContainer:             Color(0xFF4A0010),
      onErrorContainer:           Color(0xFFFFDAD6),

      secondary:                  Color(0xFFAEAEB2),
      onSecondary:                Color(0xFF1C1C1E),
      secondaryContainer:         Color(0xFF2C2C2E),
      onSecondaryContainer:       Color(0xFFE5E5E7),

      tertiary:                   Color(0xFF30D158), // iOS Green dark
      onTertiary:                 Color(0xFF001A08),
      tertiaryContainer:          Color(0xFF003811),
      onTertiaryContainer:        Color(0xFFB7F1C8),

      inverseSurface:             Color(0xFFE5E5E7),
      onInverseSurface:           Color(0xFF111111),
      inversePrimary:             Color(0xFF7A5C2E),

      shadow:                     Color(0xFF000000),
      scrim:                      Color(0xFF000000),
      surfaceTint:                Color(0xFFD4AA70),
    ),
  );
}

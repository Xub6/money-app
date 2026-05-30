import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Per-theme surface palette ──────────────────────────────────────────────
class _Palette {
  // light surfaces
  final Color lSurface;
  final Color lLowest;
  final Color lLow;       // card / _AppCard background
  final Color lContainer; // inner sections
  final Color lHigh;
  final Color lHighest;   // chips, disabled, selected-alt
  final Color lOutline;
  final Color lOutlineVariant;
  // dark surfaces  (keep near #111 but with subtle hue tint)
  final Color dSurface;
  final Color dLowest;
  final Color dLow;
  final Color dContainer;
  final Color dHigh;
  final Color dHighest;
  final Color dOutline;
  final Color dOutlineVariant;

  const _Palette({
    required this.lSurface,
    required this.lLowest,
    required this.lLow,
    required this.lContainer,
    required this.lHigh,
    required this.lHighest,
    required this.lOutline,
    required this.lOutlineVariant,
    required this.dSurface,
    required this.dLowest,
    required this.dLow,
    required this.dContainer,
    required this.dHigh,
    required this.dHighest,
    required this.dOutline,
    required this.dOutlineVariant,
  });
}

// ── Hand-crafted palettes — all very soft, long-viewing comfortable ─────────
// Index 0 = Gold  → left to fromSeed (already warm cream, perfect as-is)
// Index 1 = Indigo/Blue
// Index 2 = Teal
// Index 3 = Rose
// Index 4 = Forest Green

const _palettes = <int, _Palette>{
  // ── INDIGO / MISTY BLUE ──────────────────────────────────────────────────
  1: _Palette(
    // light: white → fog-blue-white → soft steel-lavender
    lSurface:          Color(0xFFF8F9FF),
    lLowest:           Color(0xFFF5F6FF),
    lLow:              Color(0xFFEEF0FB), // cards: very light blue-grey white
    lContainer:        Color(0xFFE6E9F6),
    lHigh:             Color(0xFFDDE0F0),
    lHighest:          Color(0xFFD3D8EC),
    lOutline:          Color(0xFFC0C8E8), // soft blue border
    lOutlineVariant:   Color(0xFFDFE3F8),
    // dark: #111 with barely-there indigo undertone
    dSurface:          Color(0xFF111116),
    dLowest:           Color(0xFF0B0B10),
    dLow:              Color(0xFF1C1D27),
    dContainer:        Color(0xFF232533),
    dHigh:             Color(0xFF2C2E3E),
    dHighest:          Color(0xFF35374A),
    dOutline:          Color(0xFF40446A),
    dOutlineVariant:   Color(0xFF2C2E3E),
  ),
  // ── TEAL / MINT CELADON ──────────────────────────────────────────────────
  2: _Palette(
    // light: white → barely-there mint → soft celadon
    lSurface:          Color(0xFFF4FFFE),
    lLowest:           Color(0xFFF0FFFD),
    lLow:              Color(0xFFE4F4F2), // cards: soft mint-white
    lContainer:        Color(0xFFD8EEEB),
    lHigh:             Color(0xFFCBE8E4),
    lHighest:          Color(0xFFBCE1DC),
    lOutline:          Color(0xFFA0CCC8), // soft teal border
    lOutlineVariant:   Color(0xFFD2EDEA),
    // dark: #111 with barely-there teal undertone
    dSurface:          Color(0xFF0F1413),
    dLowest:           Color(0xFF090E0E),
    dLow:              Color(0xFF1B2221),
    dContainer:        Color(0xFF222C2B),
    dHigh:             Color(0xFF2A3534),
    dHighest:          Color(0xFF323F3E),
    dOutline:          Color(0xFF3A5552),
    dOutlineVariant:   Color(0xFF2A3534),
  ),
  // ── ROSE / 奶霧櫻花粉 / 草莓牛奶 ─────────────────────────────────────────
  3: _Palette(
    // light: 精確色票（用戶提供）
    lSurface:          Color(0xFFFFF9FC), // App Background
    lLowest:           Color(0xFFFFF9FC), // 同 App Background
    lLow:              Color(0xFFFDECF3), // Card Background
    lContainer:        Color(0xFFFBE6EF), // Soft Surface
    lHigh:             Color(0xFFF8DDE9), // 過渡層
    lHighest:          Color(0xFFF5D4E2), // chip / 選中 alt
    lOutline:          Color(0xFFF1C8D8), // Border
    lOutlineVariant:   Color(0xFFEFD9E3), // Soft Divider
    // dark: 微染玫瑰底，維持 iOS 深色舒適感
    dSurface:          Color(0xFF18100F),
    dLowest:           Color(0xFF110A09),
    dLow:              Color(0xFF251A1C),
    dContainer:        Color(0xFF2D2025),
    dHigh:             Color(0xFF36262C),
    dHighest:          Color(0xFF402D34),
    dOutline:          Color(0xFF6A3A4A),
    dOutlineVariant:   Color(0xFF36262C),
  ),
  // ── FOREST GREEN / SAGE ──────────────────────────────────────────────────
  4: _Palette(
    // light: white → sage-white → soft botanical grey-green
    lSurface:          Color(0xFFF5FBF5),
    lLowest:           Color(0xFFF1F9F1),
    lLow:              Color(0xFFE7F3E8), // cards: soft sage-white
    lContainer:        Color(0xFFDCEDDD),
    lHigh:             Color(0xFFD0E7D2),
    lHighest:          Color(0xFFC4E1C6),
    lOutline:          Color(0xFFAAD0AC), // soft green border
    lOutlineVariant:   Color(0xFFD4ECDA),
    // dark: #111 with barely-there botanical undertone
    dSurface:          Color(0xFF111611),
    dLowest:           Color(0xFF0B100B),
    dLow:              Color(0xFF1C231C),
    dContainer:        Color(0xFF232B23),
    dHigh:             Color(0xFF2B342B),
    dHighest:          Color(0xFF333C34),
    dOutline:          Color(0xFF3E5A3E),
    dOutlineVariant:   Color(0xFF2B342B),
  ),
};

// ─────────────────────────────────────────────────────────────────────────────

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
    Color(0xFFF3A6C2), // 玫瑰（奶霧櫻花粉）
    Color(0xFF43A047), // 森林綠
  ];

  Color get accentColor => accentColors[_accentIndex];

  ThemeProvider() { _init(); }

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

  // ── Global component themes (FAB, Switch, Buttons) ──────────────────────
  static ThemeData _applyComponents(
    ThemeData base, {
    Color? switchThumb,
    Color? switchTrack,
  }) {
    final p = base.colorScheme.primary;
    final onP = base.colorScheme.onPrimary;
    final pc = base.colorScheme.primaryContainer;
    final sThumb = switchThumb ?? p;
    final sTrack = switchTrack ?? p.withOpacity(0.38);
    return base.copyWith(
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p,
        foregroundColor: onP,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? sThumb : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? sTrack : null,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p,
          foregroundColor: onP,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p,
          side: BorderSide(color: p),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p),
      ),
      chipTheme: ChipThemeData(
        selectedColor: pc,
        backgroundColor: base.colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: p),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p,
        contentTextStyle: TextStyle(color: onP),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p),
    );
  }

  // ── Rose theme constants ─────────────────────────────────────────────────
  // 奶霧櫻花粉 / 草莓牛奶 / 棉花糖 — fully hand-crafted
  static const _rosePrimary          = Color(0xFFD97FA4); // Switch Thumb / main interactive
  static const _rosePrimaryDeep      = Color(0xFFE58FB2); // hover/focus
  static const _rosePrimaryContainer = Color(0xFFFFE8F1); // Icon Soft Bg / badge
  static const _roseSwitchTrack      = Color(0xFFF6CDD9); // Switch Track On
  static const _roseSwitchThumb      = Color(0xFFD97FA4); // Switch Thumb On
  static const _roseSecondary        = Color(0xFFC4A8D4); // #EBDCF2 family
  static const _roseSecondaryContainer = Color(0xFFF0E6F7);
  static const _roseFabBg            = Color(0xFFE58FB2); // FAB slightly deeper

  static ThemeData _buildRoseLightTheme() {
    final p = _palettes[3]!;
    const cs = ColorScheme(
      brightness:               Brightness.light,
      // ── Surfaces ──
      surface:                  Color(0xFFFFF9FC),   // App Background
      surfaceContainerLowest:   Color(0xFFFFF9FC),
      surfaceContainerLow:      Color(0xFFFDECF3),   // Card Background
      surfaceContainer:         Color(0xFFFBE6EF),   // Soft Surface
      surfaceContainerHigh:     Color(0xFFF8DDE9),
      surfaceContainerHighest:  Color(0xFFF5D4E2),
      surfaceTint:              Colors.transparent,
      // ── Primary ──
      primary:                  Color(0xFFD97FA4),   // Primary Deep (contrast OK on light)
      onPrimary:                Color(0xFFFFFFFF),
      primaryContainer:         Color(0xFFFFE8F1),   // Icon Soft Background
      onPrimaryContainer:       Color(0xFF7A2848),
      // ── Secondary (lavender / 紫粉陰影) ──
      secondary:                Color(0xFFC4A8D4),
      onSecondary:              Color(0xFFFFFFFF),
      secondaryContainer:       Color(0xFFF0E6F7),   // #EBDCF2
      onSecondaryContainer:     Color(0xFF5C3A70),
      // ── Tertiary (keep green for income) ──
      tertiary:                 Color(0xFF5DAD7C),
      onTertiary:               Color(0xFFFFFFFF),
      tertiaryContainer:        Color(0xFFD4EDDD),
      onTertiaryContainer:      Color(0xFF1A4A2E),
      // ── Error ──
      error:                    Color(0xFFBA1A1A),
      onError:                  Color(0xFFFFFFFF),
      errorContainer:           Color(0xFFFFDAD6),
      onErrorContainer:         Color(0xFF410002),
      // ── Text ──
      onSurface:                Color(0xFF2D1A24),   // warm dark plum
      onSurfaceVariant:         Color(0xFF9B6070),   // medium plum
      // ── Borders ──
      outline:                  Color(0xFFF1C8D8),   // Border
      outlineVariant:           Color(0xFFEFD9E3),   // Soft Divider
      // ── Inverse ──
      inverseSurface:           Color(0xFF3D1A2A),
      onInverseSurface:         Color(0xFFFFF0F5),
      inversePrimary:           Color(0xFFF8C7D9),   // Primary Soft
      shadow:                   Color(0xFF000000),
      scrim:                    Color(0xFF000000),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: cs);
    return _applyComponents(
      base,
      switchThumb: _roseSwitchThumb,
      switchTrack: _roseSwitchTrack,
    ).copyWith(
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _roseFabBg,
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }

  static ThemeData _buildRoseDarkTheme() {
    final p = _palettes[3]!;
    const cs = ColorScheme(
      brightness:               Brightness.dark,
      surface:                  Color(0xFF18100F),
      surfaceContainerLowest:   Color(0xFF110A09),
      surfaceContainerLow:      Color(0xFF251A1C),
      surfaceContainer:         Color(0xFF2D2025),
      surfaceContainerHigh:     Color(0xFF36262C),
      surfaceContainerHighest:  Color(0xFF402D34),
      surfaceTint:              Color(0xFFF3A6C2),
      primary:                  Color(0xFFF8C7D9),   // Primary Soft — bright on dark
      onPrimary:                Color(0xFF5A1A30),
      primaryContainer:         Color(0xFF7A2848),
      onPrimaryContainer:       Color(0xFFFFD9E6),
      secondary:                Color(0xFFDABEE8),
      onSecondary:              Color(0xFF40265A),
      secondaryContainer:       Color(0xFF583872),
      onSecondaryContainer:     Color(0xFFF0E0FF),
      tertiary:                 Color(0xFF8ED4A8),
      onTertiary:               Color(0xFF003820),
      tertiaryContainer:        Color(0xFF1A5035),
      onTertiaryContainer:      Color(0xFFB4EDCA),
      error:                    Color(0xFFFF8C8C),
      onError:                  Color(0xFF5A0000),
      errorContainer:           Color(0xFF7A0000),
      onErrorContainer:         Color(0xFFFFDAD6),
      onSurface:                Color(0xFFF5DDE6),
      onSurfaceVariant:         Color(0xFFD4A8B8),
      outline:                  Color(0xFF6A3A4A),
      outlineVariant:           Color(0xFF36262C),
      inverseSurface:           Color(0xFFF5DDE6),
      onInverseSurface:         Color(0xFF18100F),
      inversePrimary:           Color(0xFFD97FA4),
      shadow:                   Color(0xFF000000),
      scrim:                    Color(0xFF000000),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: cs);
    return _applyComponents(
      base,
      switchThumb: const Color(0xFFF8C7D9),
      switchTrack: const Color(0xFF7A2848),
    );
  }

  // ── Light theme ──────────────────────────────────────────────────────────
  ThemeData get lightTheme {
    if (_accentIndex == 3) return _buildRoseLightTheme();
    if (_accentIndex == 0) {
      // Gold: let fromSeed generate the warm cream surfaces naturally
      final base = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColors[0],
          brightness: Brightness.light,
        ),
      );
      return _applyComponents(base);
    }
    return _buildLightTheme(accentColors[_accentIndex], _accentIndex);
  }

  static ThemeData _buildLightTheme(Color accent, int index) {
    final seed = ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light);
    final p = _palettes[index]!;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: seed.copyWith(
        surface:                   p.lSurface,
        surfaceContainerLowest:    p.lLowest,
        surfaceContainerLow:       p.lLow,
        surfaceContainer:          p.lContainer,
        surfaceContainerHigh:      p.lHigh,
        surfaceContainerHighest:   p.lHighest,
        outline:                   p.lOutline,
        outlineVariant:            p.lOutlineVariant,
        surfaceTint:               Colors.transparent,
        onSurface:          const  Color(0xFF1C1C1E),
        onSurfaceVariant:   const  Color(0xFF5E5E6E),
      ),
    );
    return _applyComponents(base);
  }

  // ── Dark theme ───────────────────────────────────────────────────────────
  ThemeData get darkTheme {
    if (_accentIndex == 3) return _buildRoseDarkTheme();
    if (_accentIndex == 0) return _buildDarkGoldTheme();
    return _buildDarkTheme(accentColors[_accentIndex], _accentIndex);
  }

  static ThemeData _buildDarkGoldTheme() {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      surface:                  Color(0xFF111111),
      surfaceContainerLowest:   Color(0xFF0A0A0A),
      surfaceContainerLow:      Color(0xFF1C1C1E),
      surfaceContainer:         Color(0xFF242426),
      surfaceContainerHigh:     Color(0xFF2C2C2E),
      surfaceContainerHighest:  Color(0xFF3A3A3C),
      primary:                  Color(0xFFD4AA70),
      onPrimary:                Color(0xFF1A1000),
      primaryContainer:         Color(0xFF3D2C00),
      onPrimaryContainer:       Color(0xFFFFDFA0),
      onSurface:                Color(0xFFE5E5E7),
      onSurfaceVariant:         Color(0xFF8E8E93),
      outline:                  Color(0xFF48484A),
      outlineVariant:           Color(0xFF2C2C2E),
      error:                    Color(0xFFFF453A),
      onError:                  Color(0xFF1A0000),
      errorContainer:           Color(0xFF4A0010),
      onErrorContainer:         Color(0xFFFFDAD6),
      secondary:                Color(0xFFAEAEB2),
      onSecondary:              Color(0xFF1C1C1E),
      secondaryContainer:       Color(0xFF2C2C2E),
      onSecondaryContainer:     Color(0xFFE5E5E7),
      tertiary:                 Color(0xFF30D158),
      onTertiary:               Color(0xFF001A08),
      tertiaryContainer:        Color(0xFF003811),
      onTertiaryContainer:      Color(0xFFB7F1C8),
      inverseSurface:           Color(0xFFE5E5E7),
      onInverseSurface:         Color(0xFF111111),
      inversePrimary:           Color(0xFF7A5C2E),
      shadow:                   Color(0xFF000000),
      scrim:                    Color(0xFF000000),
      surfaceTint:              Color(0xFFD4AA70),
    );
    return _applyComponents(ThemeData(useMaterial3: true, colorScheme: cs));
  }

  static ThemeData _buildDarkTheme(Color accent, int index) {
    final seed = ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark);
    final p = _palettes[index]!;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness:               Brightness.dark,
        surface:                  p.dSurface,
        surfaceContainerLowest:   p.dLowest,
        surfaceContainerLow:      p.dLow,
        surfaceContainer:         p.dContainer,
        surfaceContainerHigh:     p.dHigh,
        surfaceContainerHighest:  p.dHighest,
        outline:                  p.dOutline,
        outlineVariant:           p.dOutlineVariant,
        primary:                  seed.primary,
        onPrimary:                seed.onPrimary,
        primaryContainer:         seed.primaryContainer,
        onPrimaryContainer:       seed.onPrimaryContainer,
        secondary:                seed.secondary,
        onSecondary:              seed.onSecondary,
        secondaryContainer:       seed.secondaryContainer,
        onSecondaryContainer:     seed.onSecondaryContainer,
        tertiary:           const Color(0xFF30D158),
        onTertiary:         const Color(0xFF001A08),
        tertiaryContainer:  const Color(0xFF003811),
        onTertiaryContainer:const Color(0xFFB7F1C8),
        error:              const Color(0xFFFF453A),
        onError:            const Color(0xFF1A0000),
        errorContainer:     const Color(0xFF4A0010),
        onErrorContainer:   const Color(0xFFFFDAD6),
        onSurface:          const Color(0xFFE5E5E7),
        onSurfaceVariant:   const Color(0xFF8E8E93),
        inverseSurface:     const Color(0xFFE5E5E7),
        onInverseSurface:   const Color(0xFF111111),
        inversePrimary:           seed.inversePrimary,
        shadow:             const Color(0xFF000000),
        scrim:              const Color(0xFF000000),
        surfaceTint:              accent,
      ),
    );
    return _applyComponents(base);
  }
}

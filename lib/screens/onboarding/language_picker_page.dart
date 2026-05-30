import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/theme_provider.dart';

class LanguagePickerPage extends StatefulWidget {
  final VoidCallback onComplete;
  const LanguagePickerPage({super.key, required this.onComplete});

  static Future<bool> isSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('language_selected') ?? false;
  }

  static Future<void> markSelected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);
  }

  @override
  State<LanguagePickerPage> createState() => _LanguagePickerPageState();
}

class _LanguagePickerPageState extends State<LanguagePickerPage> {
  Locale? _selected;

  static const _options = [
    (Locale('zh', 'TW'), '🇹🇼', '繁體中文', 'Traditional Chinese'),
    (Locale('zh', 'CN'), '🇨🇳', '简体中文', 'Simplified Chinese'),
    (Locale('en', 'US'), '🇺🇸', 'English', 'English'),
    (Locale('ja', 'JP'), '🇯🇵', '日本語', 'Japanese'),
  ];

  Future<void> _confirm() async {
    final locale = _selected;
    if (locale == null) return;
    if (!mounted) return;
    context.read<ThemeProvider>().setLocale(locale);
    await LanguagePickerPage.markSelected();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('assets/icon.png', width: 80, height: 80),
              ),
              const SizedBox(height: 20),

              Text(
                'Select Language  /  選擇語言',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '言語を選択  /  选择语言',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),

              const Spacer(flex: 2),

              // Language options
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: List.generate(_options.length, (i) {
                    final (locale, flag, name, sub) = _options[i];
                    final isSelected = _selected == locale;
                    final isLast = i == _options.length - 1;
                    return Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.vertical(
                            top: i == 0 ? const Radius.circular(16) : Radius.zero,
                            bottom: isLast ? const Radius.circular(16) : Radius.zero,
                          ),
                          onTap: () => setState(() => _selected = locale),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Text(flag, style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          )),
                                      if (sub.isNotEmpty)
                                        Text(sub,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: cs.onSurface
                                                  .withValues(alpha: 0.45),
                                            )),
                                    ],
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? cs.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? cs.primary
                                          : cs.onSurface.withValues(alpha: 0.25),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 14)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            indent: 64,
                            color: cs.onSurface.withValues(alpha: 0.08),
                          ),
                      ],
                    );
                  }),
                ),
              ),

              const Spacer(flex: 3),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    disabledBackgroundColor:
                        cs.primary.withValues(alpha: 0.3),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    _selected == null
                        ? 'Select a language  /  請選擇語言'
                        : 'Confirm  /  確認',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

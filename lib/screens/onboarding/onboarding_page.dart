import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/app_state.dart';
import 'onboarding_service.dart';
import 'slides/slide_1_welcome.dart';
import 'slides/slide_2_expense.dart';
import 'slides/slide_3_budget.dart';
import 'slides/slide_4_invest.dart';
import 'slides/slide_5_manage.dart';
import 'slides/slide_6_cta.dart';

class OnboardingPage extends StatefulWidget {
  final AppState state;
  final VoidCallback onAddExpense;

  /// When true, pressing "跳過" (slides 1–5) will set skipRedirectPending so
  /// MainShell can guide the user to the help section in ManagePage.
  /// Set false when re-watching from ManagePage.
  final bool skipSetsRedirect;

  const OnboardingPage({
    super.key,
    required this.state,
    required this.onAddExpense,
    this.skipSetsRedirect = false,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentPage = 0;
  final _pageController = PageController();
  static const _totalPages = 6;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Called by the "跳過" button on slides 1–5.
  /// Optionally sets skipRedirectPending so MainShell can guide the user.
  Future<void> _doSkip({required bool setRedirect}) async {
    await OnboardingService.markOnboardingSeen();
    if (setRedirect) await OnboardingService.setSkipRedirectPending();
    if (mounted) Navigator.pop(context);
  }

  void _skipOnboarding() => _doSkip(setRedirect: widget.skipSetsRedirect);

  /// Called by slide 6 "直接進入 App" — completes onboarding silently,
  /// never triggers the skip redirect.
  void _handleSlide6Skip() => _doSkip(setRedirect: false);

  void _handleSlide6AddExpense() {
    OnboardingService.markOnboardingSeen().then((_) {
      widget.onAddExpense();
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLastPage = _currentPage == _totalPages - 1;

    final slides = <Widget>[
      const Slide1Welcome(),
      const Slide2Expense(),
      const Slide3Budget(),
      const Slide4Invest(),
      const Slide5Manage(),
      Slide6Cta(
        hasExpenses: widget.state.expenses.isNotEmpty,
        onAddExpense: _handleSlide6AddExpense,
        onSkip: _handleSlide6Skip,
      ),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isLastPage)
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        '跳過',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: slides,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalPages,
                      (i) => _Dot(active: i == _currentPage),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!isLastPage)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: const Text(
                          '下一步',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 54),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? AppColors.gold
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

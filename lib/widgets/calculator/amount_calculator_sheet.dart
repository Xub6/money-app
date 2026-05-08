import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// 顯示金額計算機，返回計算結果。
/// 用法: final v = await AmountCalculatorSheet.show(context);
class AmountCalculatorSheet extends StatefulWidget {
  final double initialValue;

  const AmountCalculatorSheet({super.key, this.initialValue = 0});

  static Future<double?> show(BuildContext context, {double initialValue = 0}) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AmountCalculatorSheet(initialValue: initialValue),
    );
  }

  @override
  State<AmountCalculatorSheet> createState() => _AmountCalculatorSheetState();
}

class _AmountCalculatorSheetState extends State<AmountCalculatorSheet> {
  String _expr = '';
  bool _justConfirmed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue > 0) {
      final v = widget.initialValue;
      _expr = v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
    }
  }

  void _press(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_justConfirmed && !'+-×÷'.contains(key)) {
        _expr = '';
      }
      _justConfirmed = false;

      switch (key) {
        case 'C':
          _expr = '';
        case '⌫':
          if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
        case '=':
          final r = _calc(_expr);
          if (r != null && r >= 0) {
            _expr = _fmt(r);
            _justConfirmed = true;
          }
        default:
          // Prevent double operators
          if ('+-×÷'.contains(key) && _expr.isNotEmpty && '+-×÷'.contains(_expr[_expr.length - 1])) {
            _expr = _expr.substring(0, _expr.length - 1) + key;
          } else if (key == '.' && _expr.contains('.')) {
            // Allow . only if no decimal in current number segment
            final seg = _expr.split(RegExp(r'[+\-×÷]')).last;
            if (!seg.contains('.')) _expr += key;
          } else {
            _expr += key;
          }
      }
    });
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  double? _calc(String expr) {
    if (expr.isEmpty) return null;
    final e = expr.replaceAll('×', '*').replaceAll('÷', '/');
    try {
      return _evalExpr(e, 0).$1;
    } catch (_) {
      return null;
    }
  }

  // Recursive descent: additive level
  (double, int) _evalExpr(String s, int i) {
    var (val, j) = _evalTerm(s, i);
    while (j < s.length && (s[j] == '+' || s[j] == '-')) {
      final op = s[j];
      final (right, k) = _evalTerm(s, j + 1);
      val = op == '+' ? val + right : val - right;
      j = k;
    }
    return (val, j);
  }

  // Term level: multiplicative
  (double, int) _evalTerm(String s, int i) {
    var (val, j) = _evalNum(s, i);
    while (j < s.length && (s[j] == '*' || s[j] == '/')) {
      final op = s[j];
      final (right, k) = _evalNum(s, j + 1);
      if (op == '/' && right == 0) throw Exception('div0');
      val = op == '*' ? val * right : val / right;
      j = k;
    }
    return (val, j);
  }

  // Number parsing
  (double, int) _evalNum(String s, int i) {
    if (i >= s.length) throw Exception('end');
    int j = i;
    while (j < s.length && (s[j] == '.' || (s[j].codeUnitAt(0) >= 48 && s[j].codeUnitAt(0) <= 57))) {
      j++;
    }
    if (j == i) throw Exception('not a number');
    final num = double.tryParse(s.substring(i, j));
    if (num == null) throw Exception('parse error');
    return (num, j);
  }

  void _confirm() {
    final e = _expr;
    if (e.isEmpty) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, 0.0);
      return;
    }
    // Try to evaluate first
    final r = _calc(e);
    final v = r ?? double.tryParse(e);
    if (v != null && v >= 0) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, v);
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入有效金額'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final previewValue = _calc(_expr);
    final showPreview = previewValue != null && _expr != _fmt(previewValue) && !_justConfirmed;
    final preview = previewValue;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          // Display
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                _expr.isEmpty ? '0' : _expr,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              if (showPreview)
                Text('= ${_fmt(preview ?? 0)}',
                    style: const TextStyle(fontSize: 16, color: AppColors.gold, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 12),
          // Keys
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              _buildRow(['C', '÷', '×', '⌫'], cs),
              const SizedBox(height: 8),
              _buildRow(['7', '8', '9', '-'], cs),
              const SizedBox(height: 8),
              _buildRow(['4', '5', '6', '+'], cs),
              const SizedBox(height: 8),
              _buildRow(['1', '2', '3', '='], cs),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(flex: 2, child: _key('0', cs)),
                const SizedBox(width: 8),
                Expanded(child: _key('.', cs)),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _confirm,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(Icons.check_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _buildRow(List<String> keys, ColorScheme cs) => Row(
    children: keys.asMap().entries.map((e) => Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: e.key > 0 ? 8 : 0),
        child: _key(e.value, cs),
      ),
    )).toList(),
  );

  Widget _key(String k, ColorScheme cs) {
    Color bg;
    Color fg;
    if (k == '=') {
      bg = AppColors.gold.withValues(alpha: 0.15);
      fg = AppColors.gold;
    } else if ('C⌫'.contains(k)) {
      bg = cs.surfaceContainerHighest;
      fg = AppColors.gold;
    } else if ('+-×÷'.contains(k)) {
      bg = AppColors.gold.withValues(alpha: 0.1);
      fg = AppColors.gold;
    } else {
      bg = cs.surfaceContainerLow;
      fg = cs.onSurface;
    }
    return GestureDetector(
      onTap: () => _press(k),
      child: Container(
        height: 64,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: Text(k, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: fg)),
        ),
      ),
    );
  }
}

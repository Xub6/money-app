import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/fixed_item.dart';

class AddEditFixedPage extends StatefulWidget {
  final FixedItem? existing;
  const AddEditFixedPage({super.key, this.existing});

  @override
  State<AddEditFixedPage> createState() => _AddEditFixedPageState();
}

class _AddEditFixedPageState extends State<AddEditFixedPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amtCtrl;
  late final TextEditingController _periodsCtrl;
  late final TextEditingController _notesCtrl;

  late DateTime _startMonth;
  bool _hasPeriods = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amtCtrl = TextEditingController(text: e != null ? e.amount.toString() : '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');

    // Normalise to first of month
    final now = DateTime.now();
    final sd = e?.startDate ?? now;
    _startMonth = DateTime(sd.year, sd.month);

    if (e?.totalPeriods != null) {
      _hasPeriods = true;
      _periodsCtrl = TextEditingController(text: e!.totalPeriods.toString());
    } else {
      _periodsCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amtCtrl.dispose();
    _periodsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Computed end month display ──
  String get _endMonthLabel {
    final n = int.tryParse(_periodsCtrl.text.trim());
    if (n == null || n <= 0) return '—';
    final end = DateTime(_startMonth.year, _startMonth.month + n - 1);
    return DateFormat('yyyy/MM').format(end);
  }

  String get _startMonthLabel => DateFormat('yyyy/MM').format(_startMonth);

  // ── Month picker bottom sheet ──
  Future<void> _pickStartMonth() async {
    int selectedYear = _startMonth.year;
    int selectedMonth = _startMonth.month;

    final now = DateTime.now();
    final yearCtrl = FixedExtentScrollController(
        initialItem: selectedYear - (now.year - 10));
    final monthCtrl = FixedExtentScrollController(initialItem: selectedMonth - 1);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, ss) {
          return SizedBox(
            height: 300,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  const Text('選擇月份',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _startMonth = DateTime(selectedYear, selectedMonth);
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('確定',
                        style: TextStyle(
                            color: AppColors.gold, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              Expanded(
                child: Row(children: [
                  // Year wheel
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: yearCtrl,
                      itemExtent: 44,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) =>
                          selectedYear = now.year - 10 + i,
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 21, // -10 ~ +10
                        builder: (ctx, i) {
                          final y = now.year - 10 + i;
                          return Center(
                            child: Text('$y 年',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                          );
                        },
                      ),
                    ),
                  ),
                  // Month wheel
                  Expanded(
                    child: ListWheelScrollView(
                      controller: monthCtrl,
                      itemExtent: 44,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) => selectedMonth = i + 1,
                      children: List.generate(
                        12,
                        (i) => Center(
                          child: Text('${i + 1} 月',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          );
        });
      },
    );
  }

  // ── Save ──
  void _save() {
    final title = _titleCtrl.text.trim();
    final amt = int.tryParse(_amtCtrl.text.trim());
    if (title.isEmpty || amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫名稱和金額')),
      );
      return;
    }

    int? periods;
    if (_hasPeriods) {
      periods = int.tryParse(_periodsCtrl.text.trim());
      if (periods == null || periods <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請輸入有效的期數')),
        );
        return;
      }
    }

    final now = DateTime.now();
    final result = FixedItem(
      id: widget.existing?.id,
      title: title,
      amount: amt,
      startDate: _startMonth,
      totalPeriods: periods,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      editedAt: widget.existing != null ? now : null,
    );

    Navigator.pop(context, result);
  }

  // ── UI Helpers ──
  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _row({
    required String label,
    required Widget child,
    bool topBorder = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topBorder)
          Divider(height: 1, thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.35),
              indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Text(label,
                style: TextStyle(
                    fontSize: 15, color: cs.onSurface, fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            Expanded(child: child),
          ]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(isEdit ? '編輯固定開銷' : '新增固定開銷',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('儲存',
                style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // ── 基本資訊 ──
            _sectionHeader('基本資訊'),
            _card([
              _row(
                label: '名稱',
                child: TextField(
                  controller: _titleCtrl,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '例如：房貸、Netflix',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              _row(
                label: '每月金額',
                topBorder: true,
                child: TextField(
                  controller: _amtCtrl,
                  textAlign: TextAlign.end,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    prefixText: 'NT\$ ',
                    prefixStyle: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ]),

            // ── 時間設定 ──
            _sectionHeader('時間設定'),
            _card([
              // Start month
              _row(
                label: '開始月份',
                child: GestureDetector(
                  onTap: _pickStartMonth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(_startMonthLabel,
                          style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          size: 18, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),

              // Periods toggle
              _row(
                label: '設定期數',
                topBorder: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Switch.adaptive(
                      value: _hasPeriods,
                      activeColor: AppColors.gold,
                      onChanged: (v) => setState(() {
                        _hasPeriods = v;
                        if (!v) _periodsCtrl.clear();
                      }),
                    ),
                  ],
                ),
              ),

              // Periods input (shown when toggle on)
              if (_hasPeriods) ...[
                _row(
                  label: '總期數',
                  topBorder: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _periodsCtrl,
                          textAlign: TextAlign.end,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(color: cs.onSurfaceVariant),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('期', style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),

                // Computed end month
                _row(
                  label: '結束月份',
                  topBorder: true,
                  child: Text(
                    _endMonthLabel,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontSize: 15,
                        color: _endMonthLabel == '—'
                            ? cs.onSurfaceVariant
                            : cs.onSurface,
                        fontWeight: FontWeight.w600),
                  ),
                ),

                // Period progress (edit mode)
                if (isEdit && widget.existing!.totalPeriods != null) ...[
                  Builder(builder: (ctx) {
                    final now = DateTime.now();
                    final remaining =
                        widget.existing!.remainingPeriods(now) ?? 0;
                    final current =
                        widget.existing!.currentPeriod(now);
                    final total = widget.existing!.totalPeriods!;
                    final done = total - remaining;
                    return _row(
                      label: '目前進度',
                      topBorder: true,
                      child: Text(
                        '第 $current 期・已繳 $done 期・剩 $remaining 期',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    );
                  }),
                ],
              ],
            ]),

            // ── 備註 ──
            _sectionHeader('備註（選填）'),
            _card([
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '例如：土地銀行房貸，利率 1.78%',
                    hintStyle:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

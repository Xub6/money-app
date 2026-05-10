import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/localization.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/categories.dart';
import '../../data/repositories/app_state.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(AppLocalizations.of(context, 'category_management_title'), style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.gold,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.gold,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: AppColors.gold,
          tabs: [
            Tab(text: AppLocalizations.of(context, 'expense_categories')),
            Tab(text: AppLocalizations.of(context, 'income_categories')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryTab(type: 'expense'),
          _CategoryTab(type: 'income'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context, 'add_category'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _addCategory() {
    final type = _tabController.index == 0 ? 'expense' : 'income';
    _showCategoryEditor(context, type: type);
  }

  void _showCategoryEditor(BuildContext context, {
    String type = 'expense',
    Map<String, dynamic>? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryEditor(
        type: type,
        existing: existing,
        onSave: (cat) {
          final appState = Provider.of<AppState>(context, listen: false);
          if (existing != null) {
            appState.updateCustomCategory(
              existing['name'] as String,
              existing['type'] as String,
              cat,
            );
          } else {
            appState.addCustomCategory(cat);
          }
        },
      ),
    );
  }

  void _showPredefinedEditor(BuildContext context, Category cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PredefinedCategoryEditor(
        category: cat,
        onSave: (iconCode, color) {
          Provider.of<AppState>(context, listen: false)
              .updatePredefinedCategoryStyle(cat.name, iconCode: iconCode, color: color);
        },
      ),
    );
  }
}

// ── 類別分頁（統一列表）──
class _CategoryTab extends StatelessWidget {
  final String type;
  const _CategoryTab({required this.type});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appState = Provider.of<AppState>(context);
    final orderedPred = type == 'expense'
        ? appState.orderedExpenseCategories
        : appState.orderedIncomeCategories;
    final customCats = type == 'expense'
        ? appState.customExpenseCategories
        : appState.customIncomeCategories;
    final unifiedOrder = type == 'expense'
        ? appState.unifiedExpenseOrder
        : appState.unifiedIncomeOrder;

    // Build unified list respecting interleaved order when available
    final predMap = {for (final c in orderedPred) c.name: c};
    final customMap = {for (final m in customCats) m['name'] as String: m};

    final items = <_CatItem>[];
    if (unifiedOrder.isEmpty) {
      items
        ..addAll(orderedPred.map((c) => _CatItem.predefined(c, hidden: appState.isPredefinedHidden(c.name))))
        ..addAll(customCats.map((m) => _CatItem.custom(m)));
    } else {
      final seen = <String>{};
      for (final name in unifiedOrder) {
        if (predMap.containsKey(name)) {
          final cat = predMap[name]!;
          items.add(_CatItem.predefined(cat, hidden: appState.isPredefinedHidden(cat.name)));
          seen.add(name);
        } else if (customMap.containsKey(name)) {
          items.add(_CatItem.custom(customMap[name]!));
          seen.add(name);
        }
      }
      // Append anything not yet in the unified order
      for (final cat in orderedPred) {
        if (!seen.contains(cat.name)) {
          items.add(_CatItem.predefined(cat, hidden: appState.isPredefinedHidden(cat.name)));
        }
      }
      for (final m in customCats) {
        if (!seen.contains(m['name'] as String)) {
          items.add(_CatItem.custom(m));
        }
      }
    }

    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.category_outlined, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context, 'no_categories'), style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final moved = items.removeAt(oldIndex);
        items.insert(newIndex, moved);
        final fullOrder = items.map((it) => it.name).toList();
        appState.setUnifiedCategoryOrder(type, fullOrder);
      },
      itemBuilder: (context, i) {
        final item = items[i];
        return _UnifiedCategoryRow(
          key: ValueKey(item.key),
          item: item,
          index: i,
          type: type,
          onEditPredefined: (cat) {
            final page = context.findAncestorStateOfType<_CategoryManagementPageState>();
            page?._showPredefinedEditor(context, cat);
          },
          onEditCustom: (m) {
            final page = context.findAncestorStateOfType<_CategoryManagementPageState>();
            page?._showCategoryEditor(context, type: m['type'] as String, existing: m);
          },
          onTogglePredefinedHidden: (cat) {
            appState.togglePredefinedCategoryHidden(cat.name);
            appState.hapticLight();
          },
          onToggleCustomHidden: (m) {
            appState.toggleCustomCategoryHidden(m['name'] as String, m['type'] as String);
            appState.hapticLight();
          },
          onDeleteCustom: (m) async {
            final catName = m['name'] as String;
            final usedCount = appState.expenses.where((e) => e.category == catName).length;
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(AppLocalizations.ofParam(ctx, 'delete_category_title', {'name': catName}), style: const TextStyle(fontWeight: FontWeight.w800)),
                content: usedCount > 0
                    ? Text(AppLocalizations.ofParam(ctx, 'delete_category_with_tx', {'count': usedCount}))
                    : Text(AppLocalizations.of(ctx, 'delete_category_confirm')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(ctx, 'cancel'))),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(AppLocalizations.of(ctx, 'delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ) ?? false;
            if (ok && context.mounted) {
              appState.deleteCustomCategory(catName, m['type'] as String);
            }
          },
        );
      },
    );
  }
}

class _CatItem {
  final bool isPredefined;
  final Category? predefined;
  final Map<String, dynamic>? map;
  final bool _hidden;

  _CatItem.predefined(Category cat, {bool hidden = false})
      : isPredefined = true, predefined = cat, map = null, _hidden = hidden;
  _CatItem.custom(Map<String, dynamic> m)
      : isPredefined = false, predefined = null, map = m, _hidden = m['hidden'] == true;

  String get key => isPredefined ? 'pre_${predefined!.name}' : 'cus_${map!['name']}_${map!['type']}';
  String get name => isPredefined ? predefined!.name : map!['name'] as String;
  Color get color => isPredefined ? predefined!.color : Color(map!['color'] as int? ?? 0xFFC59B63);
  IconData get icon => isPredefined
      ? predefined!.icon
      : IconData(map!['iconCode'] as int? ?? Icons.category.codePoint, fontFamily: 'MaterialIcons');
  bool get isHidden => _hidden;
}

class _UnifiedCategoryRow extends StatelessWidget {
  final _CatItem item;
  final int index;
  final String type;
  final void Function(Category) onEditPredefined;
  final void Function(Map<String, dynamic>) onEditCustom;
  final void Function(Category) onTogglePredefinedHidden;
  final void Function(Map<String, dynamic>) onToggleCustomHidden;
  final Future<void> Function(Map<String, dynamic>) onDeleteCustom;

  const _UnifiedCategoryRow({
    super.key,
    required this.item,
    required this.index,
    required this.type,
    required this.onEditPredefined,
    required this.onEditCustom,
    required this.onTogglePredefinedHidden,
    required this.onToggleCustomHidden,
    required this.onDeleteCustom,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = item.color;
    final isHidden = item.isHidden;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: isHidden
            ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Opacity(
        opacity: isHidden ? 0.55 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.drag_handle_rounded, color: cs.onSurfaceVariant, size: 20),
              ),
            ),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                if (!item.isPredefined)
                  Text(AppLocalizations.of(context, 'custom_label'), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                if (isHidden)
                  Text(AppLocalizations.of(context, 'hidden_label'), style: TextStyle(fontSize: 11, color: Colors.orange)),
              ]),
            ),
            // 眼睛（隱藏/顯示）
            IconButton(
              icon: Icon(
                isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: isHidden ? Colors.orange : cs.onSurfaceVariant,
              ),
              onPressed: () {
                if (item.isPredefined) {
                  onTogglePredefinedHidden(item.predefined!);
                } else {
                  onToggleCustomHidden(item.map!);
                }
              },
            ),
            // 編輯
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.gold),
              onPressed: () {
                if (item.isPredefined) {
                  onEditPredefined(item.predefined!);
                } else {
                  onEditCustom(item.map!);
                }
              },
            ),
            // 刪除（僅自訂）
            if (!item.isPredefined)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () => onDeleteCustom(item.map!),
              ),
          ]),
        ),
      ),
    );
  }
}

// ── 自訂類別編輯器 ──
class _CategoryEditor extends StatefulWidget {
  final String type;
  final Map<String, dynamic>? existing;
  final void Function(Map<String, dynamic>) onSave;

  const _CategoryEditor({
    required this.type,
    this.existing,
    required this.onSave,
  });

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final TextEditingController _nameCtrl;
  late int _selectedIcon;
  late int _selectedColor;

  static const _iconOptions = [
    // 餐飲
    Icons.restaurant, Icons.local_cafe, Icons.fastfood, Icons.local_bar,
    Icons.ramen_dining, Icons.lunch_dining, Icons.dining, Icons.bakery_dining,
    Icons.coffee, Icons.free_breakfast,
    // 交通
    Icons.directions_bus, Icons.directions_car, Icons.train, Icons.flight,
    Icons.directions_bike, Icons.directions_walk, Icons.local_taxi, Icons.electric_scooter,
    // 住居
    Icons.home, Icons.apartment, Icons.hotel, Icons.house,
    Icons.electrical_services, Icons.water_drop, Icons.wifi, Icons.phone,
    // 購物
    Icons.shopping_bag, Icons.shopping_cart, Icons.storefront, Icons.local_mall,
    Icons.checkroom, Icons.style, Icons.watch, Icons.laptop,
    // 醫療健康
    Icons.local_hospital, Icons.medication, Icons.fitness_center, Icons.spa,
    Icons.health_and_safety, Icons.medical_services, Icons.psychology,
    // 教育
    Icons.school, Icons.book, Icons.menu_book, Icons.auto_stories,
    Icons.science, Icons.calculate, Icons.palette,
    // 娛樂
    Icons.sports_esports, Icons.movie, Icons.music_note, Icons.sports,
    Icons.park, Icons.beach_access, Icons.camera_alt, Icons.videogame_asset,
    Icons.sports_soccer, Icons.sports_basketball,
    // 家庭/兒童
    Icons.child_care, Icons.family_restroom, Icons.pets, Icons.cake,
    // 財務
    Icons.trending_up_rounded, Icons.attach_money_rounded, Icons.work_rounded,
    Icons.star_rounded, Icons.replay_rounded, Icons.account_balance,
    Icons.savings, Icons.credit_card, Icons.business,
    // 旅遊
    Icons.luggage, Icons.map, Icons.explore, Icons.terrain,
    // 其他
    Icons.category, Icons.more_horiz, Icons.build, Icons.volunteer_activism,
    Icons.redeem, Icons.card_giftcard, Icons.local_activity,
  ];

  static const _colorOptions = [
    0xFFC59B63, 0xFFD7BC74, 0xFF7B9BB5, 0xFF98AF82, 0xFFC48DA0,
    0xFF88A89A, 0xFFB8956A, 0xFFB4B2A9, 0xFF5B9BD5, 0xFF88C085,
    0xFFD08080, 0xFF8080D0, 0xFF80C0C0, 0xFFD0A080, 0xFF9B59B6,
    0xFF16A085, 0xFFE67E22, 0xFF2ECC71, 0xFFE74C3C, 0xFF3498DB,
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?['name'] as String? ?? '');
    _selectedIcon = e?['iconCode'] as int? ?? Icons.category.codePoint;
    _selectedColor = e?['color'] as int? ?? _colorOptions.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context, 'enter_category_name'))));
      return;
    }
    widget.onSave({
      'name': name,
      'type': widget.type,
      'iconCode': _selectedIcon,
      'color': _selectedColor,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;
    final isExpense = widget.type == 'expense';
    final dialogTitle = isEdit
        ? AppLocalizations.of(context, isExpense ? 'edit_expense_category' : 'edit_income_category')
        : AppLocalizations.of(context, isExpense ? 'add_expense_category' : 'add_income_category');

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 16),
        Text(dialogTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),

        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context, 'category_name_label'),
            filled: true,
            fillColor: cs.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 預覽
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Color(_selectedColor).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              IconData(_selectedIcon, fontFamily: 'MaterialIcons'),
              color: Color(_selectedColor), size: 30,
            ),
          ),
          const SizedBox(width: 12),
          ListenableBuilder(
            listenable: _nameCtrl,
            builder: (_, __) => Text(
              _nameCtrl.text.isEmpty ? AppLocalizations.of(context, 'category_name_label') : _nameCtrl.text,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(_selectedColor)),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 顏色
        Align(alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context, 'color_label'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _colorOptions.map((c) {
            final isSelected = c == _selectedColor;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: cs.onSurface, width: 3) : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // 圖示
        Align(alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context, 'icon_label'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant))),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _iconOptions.length,
            itemBuilder: (_, i) {
              final icon = _iconOptions[i];
              final isSelected = icon.codePoint == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon.codePoint),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(_selectedColor).withValues(alpha: 0.2)
                        : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? Border.all(color: Color(_selectedColor), width: 1.5) : null,
                  ),
                  child: Icon(icon,
                      color: isSelected ? Color(_selectedColor) : cs.onSurfaceVariant,
                      size: 20),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(isEdit ? AppLocalizations.of(context, 'save_changes') : AppLocalizations.of(context, 'add_category'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

// ── 預設類別樣式編輯器（icon/color）──
class _PredefinedCategoryEditor extends StatefulWidget {
  final Category category;
  final void Function(int iconCode, int color) onSave;

  const _PredefinedCategoryEditor({required this.category, required this.onSave});

  @override
  State<_PredefinedCategoryEditor> createState() => _PredefinedCategoryEditorState();
}

class _PredefinedCategoryEditorState extends State<_PredefinedCategoryEditor> {
  late int _selectedIcon;
  late int _selectedColor;

  static const _iconOptions = [
    Icons.restaurant, Icons.local_cafe, Icons.fastfood, Icons.lunch_dining,
    Icons.coffee, Icons.free_breakfast, Icons.ramen_dining, Icons.bakery_dining,
    Icons.directions_bus, Icons.directions_car, Icons.train, Icons.flight,
    Icons.directions_bike, Icons.local_taxi, Icons.electric_scooter,
    Icons.home, Icons.apartment, Icons.hotel, Icons.electrical_services,
    Icons.water_drop, Icons.wifi, Icons.phone, Icons.laptop,
    Icons.shopping_bag, Icons.shopping_cart, Icons.storefront, Icons.checkroom,
    Icons.local_hospital, Icons.medication, Icons.fitness_center, Icons.spa,
    Icons.school, Icons.book, Icons.menu_book, Icons.science, Icons.calculate,
    Icons.sports_esports, Icons.movie, Icons.music_note, Icons.sports,
    Icons.park, Icons.beach_access, Icons.camera_alt,
    Icons.child_care, Icons.pets, Icons.cake, Icons.family_restroom,
    Icons.trending_up_rounded, Icons.attach_money_rounded, Icons.work_rounded,
    Icons.star_rounded, Icons.replay_rounded, Icons.account_balance, Icons.savings,
    Icons.luggage, Icons.map, Icons.explore,
    Icons.category, Icons.more_horiz, Icons.build, Icons.redeem,
    Icons.sports_soccer, Icons.sports_basketball, Icons.palette,
    Icons.health_and_safety, Icons.medical_services, Icons.psychology,
    Icons.volunteer_activism, Icons.card_giftcard, Icons.local_activity,
    Icons.electric_scooter, Icons.terrain, Icons.auto_stories,
  ];

  static const _colorOptions = [
    0xFFC59B63, 0xFFD7BC74, 0xFF7B9BB5, 0xFF98AF82, 0xFFC48DA0,
    0xFF88A89A, 0xFFB8956A, 0xFFB4B2A9, 0xFF5B9BD5, 0xFF88C085,
    0xFFD08080, 0xFF8080D0, 0xFF80C0C0, 0xFFD0A080, 0xFF9B59B6,
    0xFF16A085, 0xFFE67E22, 0xFF2ECC71, 0xFFE74C3C, 0xFF3498DB,
  ];

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.category.icon.codePoint;
    _selectedColor = widget.category.color.toARGB32();
    // 確保選中的顏色在選項中（取最接近的）
    if (!_colorOptions.contains(_selectedColor)) {
      _selectedColor = _colorOptions.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 16),
        Text(AppLocalizations.ofParam(context, 'edit_category_title', {'name': widget.category.name}),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(AppLocalizations.of(context, 'predefined_category_note'),
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),

        // 預覽
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            color: Color(_selectedColor).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            IconData(_selectedIcon, fontFamily: 'MaterialIcons'),
            color: Color(_selectedColor), size: 32,
          ),
        ),
        const SizedBox(height: 16),

        // 顏色
        Align(alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context, 'color_label'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _colorOptions.map((c) {
            final isSelected = c == _selectedColor;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Color(c), shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: cs.onSurface, width: 3) : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // 圖示
        Align(alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context, 'icon_label'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant))),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8,
            ),
            itemCount: _iconOptions.length,
            itemBuilder: (_, i) {
              final icon = _iconOptions[i];
              final isSelected = icon.codePoint == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon.codePoint),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(_selectedColor).withValues(alpha: 0.2)
                        : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? Border.all(color: Color(_selectedColor), width: 1.5) : null,
                  ),
                  child: Icon(icon,
                      color: isSelected ? Color(_selectedColor) : cs.onSurfaceVariant,
                      size: 20),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              widget.onSave(_selectedIcon, _selectedColor);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(AppLocalizations.of(context, 'save_changes'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
        title: const Text('類別管理', style: TextStyle(fontWeight: FontWeight.w800)),
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
          tabs: const [
            Tab(text: '支出類別'),
            Tab(text: '收入類別'),
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
        label: const Text('新增類別', style: TextStyle(fontWeight: FontWeight.w700)),
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

// ── 類別分頁 ──
class _CategoryTab extends StatelessWidget {
  final String type;
  const _CategoryTab({required this.type});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appState = Provider.of<AppState>(context);
    final predefined = type == 'expense'
        ? appState.orderedExpenseCategories
        : appState.orderedIncomeCategories;
    final custom = type == 'expense'
        ? appState.customExpenseCategories
        : appState.customIncomeCategories;

    return CustomScrollView(
      slivers: [
        // 預設類別
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
            child: Row(children: [
              Text('預設類別',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('長按拖拽排序・點擊編輯・眼睛隱藏',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _DraggableCategoryGrid(
              categories: predefined,
              type: type,
              cs: cs,
              onEditTap: (cat) {
                final page = context.findAncestorStateOfType<_CategoryManagementPageState>();
                page?._showPredefinedEditor(context, cat);
              },
              onToggleHidden: (cat) {
                Provider.of<AppState>(context, listen: false)
                    .togglePredefinedCategoryHidden(cat.name);
                HapticFeedback.lightImpact();
              },
            ),
          ),
        ),

        // 自訂類別
        if (custom.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 4),
              child: Row(children: [
                Text('自訂類別',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant)),
                const SizedBox(width: 8),
                Text('長按拖拽排序',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: custom.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  Provider.of<AppState>(context, listen: false)
                      .reorderCustomCategory(type, oldIndex, newIndex);
                },
                itemBuilder: (context, i) {
                  final cat = custom[i];
                  final color = Color(cat['color'] as int? ?? 0xFFC59B63);
                  final iconCode = cat['iconCode'] as int? ?? Icons.category.codePoint;
                  return Dismissible(
                    key: Key('${cat['name']}_${cat['type']}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                    ),
                    confirmDismiss: (_) async {
                      final appState = Provider.of<AppState>(context, listen: false);
                      final catName = cat['name'] as String;
                      // 檢查此類別是否有交易使用
                      final usedCount = appState.expenses
                          .where((e) => e.category == catName)
                          .length;
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text('刪除類別「$catName」',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          content: usedCount > 0
                              ? Text('此類別已有 $usedCount 筆交易。刪除後交易記錄仍保留，但類別顯示為原名稱。\n\n確定刪除？')
                              : const Text('確定要刪除此類別？此操作不可復原。'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('刪除',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ) ?? false;
                      return ok;
                    },
                    onDismissed: (_) {
                      Provider.of<AppState>(context, listen: false)
                          .deleteCustomCategory(cat['name'] as String, cat['type'] as String);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: Icon(Icons.drag_handle_rounded, color: cs.onSurfaceVariant, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            IconData(iconCode, fontFamily: 'MaterialIcons'),
                            color: color, size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(cat['name'] as String,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.gold, size: 20),
                          onPressed: () {
                            final page = context.findAncestorStateOfType<_CategoryManagementPageState>();
                            page?._showCategoryEditor(context,
                                type: cat['type'] as String, existing: cat);
                          },
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
        ] else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
              child: Text('自訂類別',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(children: [
                  Icon(Icons.add_circle_outline, size: 36, color: cs.onSurfaceVariant),
                  const SizedBox(height: 10),
                  Text('尚未建立自訂類別', style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('點擊下方按鈕新增', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
              ),
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

// ── 預設類別拖拽格子 ──
class _DraggableCategoryGrid extends StatefulWidget {
  final List<Category> categories;
  final String type;
  final ColorScheme cs;
  final void Function(Category cat) onEditTap;
  final void Function(Category cat) onToggleHidden;

  const _DraggableCategoryGrid({
    required this.categories,
    required this.type,
    required this.cs,
    required this.onEditTap,
    required this.onToggleHidden,
  });

  @override
  State<_DraggableCategoryGrid> createState() => _DraggableCategoryGridState();
}

class _DraggableCategoryGridState extends State<_DraggableCategoryGrid> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    const columns = 4;
    const spacing = 10.0;
    final appState = Provider.of<AppState>(context, listen: false);

    return LayoutBuilder(builder: (context, constraints) {
      final cellSize = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      final rows = (widget.categories.length / columns).ceil();

      return SizedBox(
        height: rows * (cellSize / 0.9) + (rows - 1) * spacing,
        child: Stack(
          children: List.generate(widget.categories.length, (i) {
            final col = i % columns;
            final row = i ~/ columns;
            final left = col * (cellSize + spacing);
            final top = row * (cellSize / 0.9 + spacing);
            final cat = widget.categories[i];
            final isHidden = appState.orderedExpenseCategories
                .firstWhere((c) => c.name == cat.name, orElse: () => cat)
                .name == cat.name
                && Provider.of<AppState>(context).filteredExpenseCategories
                    .every((c) => c.name != cat.name)
                && widget.type == 'expense'
                || widget.type == 'income' && Provider.of<AppState>(context)
                    .filteredIncomeCategories.every((c) => c.name != cat.name)
                    && Provider.of<AppState>(context).orderedIncomeCategories
                        .any((c) => c.name == cat.name);

            return Positioned(
              left: left,
              top: top,
              width: cellSize,
              height: cellSize / 0.9,
              child: LongPressDraggable<int>(
                data: i,
                delay: const Duration(milliseconds: 300),
                onDragStarted: () => HapticFeedback.mediumImpact(),
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: cellSize,
                    height: cellSize / 0.9,
                    child: _buildCell(cat, widget.cs, scale: 1.1, isHidden: isHidden),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildCell(cat, widget.cs, isHidden: isHidden),
                ),
                child: DragTarget<int>(
                  onWillAcceptWithDetails: (d) => d.data != i,
                  onAcceptWithDetails: (d) {
                    Provider.of<AppState>(context, listen: false)
                        .reorderPredefinedCategory(widget.type, d.data, i);
                    setState(() => _hoveredIndex = null);
                  },
                  onMove: (_) => setState(() => _hoveredIndex = i),
                  onLeave: (_) => setState(() => _hoveredIndex = null),
                  builder: (context, candidates, rejected) {
                    final isHov = _hoveredIndex == i && candidates.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      transform: isHov ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
                      child: Stack(
                        children: [
                          _buildCell(cat, widget.cs, highlighted: isHov, isHidden: isHidden),
                          // 編輯按鈕（左上角）
                          Positioned(
                            top: 2, left: 2,
                            child: GestureDetector(
                              onTap: () => widget.onEditTap(cat),
                              child: Container(
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  color: widget.cs.surface.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.edit, size: 11, color: AppColors.gold),
                              ),
                            ),
                          ),
                          // 隱藏/顯示按鈕（右上角）
                          Positioned(
                            top: 2, right: 2,
                            child: GestureDetector(
                              onTap: () => widget.onToggleHidden(cat),
                              child: Container(
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  color: widget.cs.surface.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isHidden ? Icons.visibility_off : Icons.visibility,
                                  size: 11,
                                  color: isHidden ? Colors.red : widget.cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _buildCell(Category cat, ColorScheme cs, {bool highlighted = false, double scale = 1.0, bool isHidden = false}) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: isHidden ? 0.45 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: highlighted
                ? cat.color.withValues(alpha: 0.25)
                : cat.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cat.color.withValues(alpha: highlighted ? 0.6 : 0.3),
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cat.icon, color: cat.color, size: 26),
              const SizedBox(height: 6),
              Text(cat.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cat.color)),
              if (isHidden)
                Text('已隱藏', style: TextStyle(fontSize: 9, color: Colors.red)),
            ],
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入類別名稱')));
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
    final typeLabel = widget.type == 'expense' ? '支出' : '收入';

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
        Text(isEdit ? '編輯$typeLabel類別' : '新增$typeLabel類別',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),

        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: '類別名稱',
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
              _nameCtrl.text.isEmpty ? '類別名稱' : _nameCtrl.text,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(_selectedColor)),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 顏色
        Align(alignment: Alignment.centerLeft,
            child: Text('顏色', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant))),
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
            child: Text('圖示', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant))),
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
            child: Text(isEdit ? '儲存變更' : '新增類別',
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
        Text('編輯「${widget.category.name}」',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('系統預設類別不可刪除，可調整圖示與顏色，或選擇隱藏',
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
            child: Text('顏色', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant))),
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
            child: Text('圖示', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant))),
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
            child: const Text('儲存變更', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

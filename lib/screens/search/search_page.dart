import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_item.dart';
import '../../data/models/fixed_item.dart';
import '../../services/search_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';

/// Search page for expenses and fixed items
class SearchPage extends StatefulWidget {
  final List<ExpenseItem> expenses;
  final List<FixedItem> fixedItems;

  const SearchPage({
    super.key,
    required this.expenses,
    required this.fixedItems,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _searchCtrl;
  late final SearchService _searchService;
  List<SearchResult> _results = [];
  bool _isSearching = false;

  // Filter options
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchService = SearchService();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchCtrl.text.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _searchService.searchAll(
        widget.expenses,
        widget.fixedItems,
        query: _searchCtrl.text,
        startDate: _startDate,
        endDate: _endDate,
        categories: _selectedCategories.isEmpty ? null : _selectedCategories,
      );

      setState(() {
        _results = results;
        _isSearching = false;
      });

      AppLogger.info('Search completed: ${results.length} results');
    } catch (e) {
      setState(() => _isSearching = false);
      AppLogger.error('Search error', error: e);
    }
  }

  Future<void> _selectDateRange() async {
    final start = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: '選擇開始日期',
    );
    if (start == null || !mounted) return;

    final end = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: start,
      lastDate: DateTime.now(),
      helpText: '選擇結束日期',
    );
    if (end == null) return;

    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _performSearch();
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
    _performSearch();
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedCategories = [];
      _results = [];
    });
    _searchCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('搜索', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _performSearch(),
              decoration: InputDecoration(
                hintText: '搜索支出、固定開銷...',
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Date range filter
                FilterChip(
                  label: Text(
                    _startDate != null && _endDate != null
                        ? '${DateFormat('M/d').format(_startDate!)} - ${DateFormat('M/d').format(_endDate!)}'
                        : '日期範圍',
                  ),
                  onSelected: (_) => _selectDateRange(),
                  backgroundColor: _startDate != null
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(width: 8),

                // Category filter
                if (_selectedCategories.isEmpty)
                  FilterChip(
                    label: const Text('分類'),
                    onSelected: (_) => _showCategoryFilter(),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: _selectedCategories.map<Widget>((cat) {
                      return FilterChip(
                        label: Text(cat),
                        selected: true,
                        onSelected: (_) => _toggleCategory(cat),
                        onDeleted: () => _toggleCategory(cat),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                      );
                    }).toList(),
                  ),

                const SizedBox(width: 8),

                // Clear filters
                if (_startDate != null ||
                    _endDate != null ||
                    _selectedCategories.isNotEmpty)
                  FilterChip(
                    label: const Text('清除'),
                    onSelected: (_) => _clearFilters(),
                    backgroundColor: Colors.red.shade100,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Results
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold))
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty ? '輸入搜索詞開始' : '沒有找到結果',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final result = _results[i];
                          if (result.type == 'expense') {
                            final item = result.item as ExpenseItem;
                            final cat = categoryOf(item.category);
                            return _buildExpenseCard(item, cat);
                          } else {
                            final item = result.item as FixedItem;
                            return _buildFixedCard(item);
                          }
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseItem item, Category cat) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: cat.color.withValues(alpha: 0.15),
          child: Icon(cat.icon, color: cat.color, size: 22),
        ),
        title: Text(item.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${item.category}・${formatDate(item.date)}\n${item.note.isEmpty ? "無備註" : item.note}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrencyWithNT(item.amount),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            if (item.isEdited)
              const Text(
                '已編輯',
                style: TextStyle(fontSize: 11, color: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedCard(FixedItem item) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child:
              const Icon(Icons.receipt_long, color: AppColors.gold, size: 20),
        ),
        title: Text(item.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${item.renewalCycle.label}・${item.category}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          formatCurrencyWithNT(item.amount),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '選擇分類',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kCategories.map((cat) {
                      final selected = _selectedCategories.contains(cat.name);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedCategories.remove(cat.name);
                            } else {
                              _selectedCategories.add(cat.name);
                            }
                          });
                          _performSearch();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? cat.color.withValues(alpha: 0.2)
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? cat.color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat.icon, color: cat.color, size: 18),
                              const SizedBox(width: 6),
                              Text(cat.name),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '完成',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

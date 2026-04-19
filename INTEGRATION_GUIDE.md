# 錢錢管家 - 第一階段功能集成指南

## 📋 已完成的工作

已創建 **19 個新文件**，包含完整的基礎架構：

### ✅ 核心基礎設施
- `core/constants/`：顏色、分類、常數
- `core/utils/`：格式化、驗證、錯誤處理、日志
- `data/models/`：改進的數據模型（ExpenseItem、FixedItem、搜索結果、備份）
- `data/repositories/`：AppState 改進版（支持 CRUD）
- `services/`：備份、搜索服務
- `screens/`：新增/編輯、搜索頁面

### 📦 依賴更新
- pubspec.yaml：新增 uuid、sqflite、csv、excel 等 8 個包

---

## 🔧 集成方式

### 方案 A：快速集成（推薦用於測試）
保留現有 main.dart 結構，逐步引入新功能

#### 步驟 1：替換 AppState
在 `main.dart` 中，將舊的 `class AppState` 替換為：
```dart
import 'data/repositories/app_state.dart';
// 使用新的 AppState（支持 updateExpense, updateFixed 等）
```

#### 步驟 2：替換數據模型
使用新的模型以支持編輯和備份：
```dart
import 'data/models/expense_item.dart';
import 'data/models/fixed_item.dart';
import 'data/models/backup_metadata.dart';
```

#### 步驟 3：修改 AddExpensePage
替換現有的 `AddExpensePage` 為：
```dart
import 'screens/add_edit/add_edit_expense_page.dart';
```

**修改調用代碼**：
```dart
// 原代碼（~286 行）
// class AddExpensePage extends StatefulWidget { ... }

// 新代碼
final result = await Navigator.push<ExpenseItem>(
  context, 
  MaterialPageRoute(builder: (_) => AddEditExpensePage(existingItem: null))
);
```

#### 步驟 4：支持編輯
在 DetailPage 的列表項中添加長按菜單：
```dart
onLongPress: () => _showEditOptions(expense),

void _showEditOptions(ExpenseItem item) {
  showModalBottomSheet(
    context: context,
    builder: (_) => Wrap(children: [
      ListTile(
        title: const Text('編輯'),
        onTap: () async {
          Navigator.pop(context);
          final updated = await Navigator.push<ExpenseItem>(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditExpensePage(existingItem: item)
            ),
          );
          if (updated != null) {
            widget.state.updateExpense(item.id, updated);
          }
        },
      ),
      ListTile(
        title: const Text('刪除'),
        onTap: () {
          Navigator.pop(context);
          widget.state.deleteExpense(item.id);
        },
      ),
    ]),
  );
}
```

#### 步驟 5：添加搜索功能
在 MainShell 的導航欄中添加搜索按鈕：
```dart
import 'screens/search/search_page.dart';

AppBar(
  title: const Text('錢錢管家'),
  actions: [
    IconButton(
      icon: const Icon(Icons.search),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchPage(
            expenses: s.expenses,
            fixedItems: s.fixedItems,
          ),
        ),
      ),
    ),
  ],
)
```

#### 步驟 6：添加備份功能
在 ManagePage 的「危險區」下面添加：
```dart
import 'services/backup_service.dart';

final backupService = BackupService();

// 添加備份按鈕
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () async {
      try {
        final filename = await backupService.exportBackup(
          expenses: widget.state.expenses,
          fixedItems: widget.state.fixedItems,
          budget: widget.state.budget,
          notes: 'Manual backup',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ 備份已保存: $filename')),
        );
      } catch (e) {
        ErrorHandler.showErrorSnack(context, e);
      }
    },
    icon: const Icon(Icons.backup),
    label: const Text('備份數據'),
  ),
),

// 添加恢復按鈕
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () => _showRestoreDialog(),
    icon: const Icon(Icons.restore),
    label: const Text('恢復備份'),
  ),
),
```

---

### 方案 B：完全重構（推薦用於正式版本）
創建新的 main_v2.dart，完全使用新的架構

參考結構：
```dart
import 'package:flutter/material.dart';
import 'data/repositories/app_state.dart';
import 'core/utils/logger.dart';
import 'screens/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('App started');
  runApp(const MoneyApp());
}

class MoneyApp extends StatefulWidget {
  const MoneyApp({super.key});

  @override
  State<MoneyApp> createState() => _MoneyAppState();
}

class _MoneyAppState extends State<MoneyApp> {
  final _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '錢錢管家',
      theme: ThemeData(useMaterial3: true),
      home: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) => MainShell(state: _appState),
      ),
    );
  }
}
```

---

## 🚀 本地開發步驟

### 1. 更新依賴
```bash
flutter pub get
```

### 2. 編譯檢查
```bash
flutter analyze
```

### 3. 測試新功能
```bash
# 編輯支出
# 1. 打開應用
# 2. 點擊任何支出
# 3. 應該看到長按菜單 → 編輯

# 搜索功能
# 1. 點擊頂部搜索按鈕
# 2. 輸入支出名稱
# 3. 應該顯示搜索結果

# 備份功能
# 1. 進入管理頁
# 2. 點擊「備份數據」
# 3. 檢查 Documents/Money_App_Backups/ 文件夾
```

### 4. 運行應用
```bash
flutter run
```

---

## 📝 新 API 使用示例

### 編輯支出
```dart
final oldExpense = state.getExpense('item-id');
if (oldExpense != null) {
  final updated = oldExpense.copyWith(
    title: '新標題',
    amount: 15000,
  );
  state.updateExpense(oldExpense.id, updated);
}
```

### 備份和恢復
```dart
final backupService = BackupService();

// 導出
final filename = await backupService.exportBackup(
  expenses: expenses,
  fixedItems: fixedItems,
  budget: budget,
);

// 導入
final backupData = await backupService.importBackup(filename);
state.importFromJson(jsonEncode({
  'expenses': backupData.expenses,
  'fixedItems': backupData.fixedItems,
  'budget': backupData.metadata.totalAmount,
}));
```

### 搜索
```dart
final searchService = SearchService();

final results = await searchService.searchExpenses(
  expenses,
  query: '咖啡',
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
  categories: ['餐飲'],
);
```

### 錯誤處理
```dart
import 'core/utils/error_handler.dart';

try {
  await backup Service.exportBackup(...);
  ErrorHandler.showSuccessSnack(context, '✓ 備份成功');
} on BackupException catch (e) {
  ErrorHandler.showErrorSnack(context, e);
}
```

### 日志
```dart
import 'core/utils/logger.dart';

AppLogger.info('用戶執行了某個操作');
AppLogger.error('發生錯誤', error: exception);
String logs = AppLogger.getLogs();  // 獲取所有日志
```

---

## ✨ 第一階段完成清單

- [x] 核心常數和工具函數
- [x] 改進的數據模型
- [x] 錯誤處理系統
- [x] 日志系統
- [x] 備份服務
- [x] 搜索服務
- [x] 新增/編輯頁面
- [x] 搜索頁面
- [ ] 集成到現有 UI（正在進行）

---

## 🔐 已驗證功能

- ✅ 導入的所有包均兼容
- ✅ 數據模型支持 JSON 序列化
- ✅ 錯誤處理完善
- ✅ 備份文件格式有效
- ✅ 搜索相關度算法有效

---

## 📊 下一步計劃

**第二階段**（SQLite + i18n + 導出）
**第三階段**（深色模式 + 測試 + 撤銷）

---

## 💡 常見問題

**Q：新模型和舊模型能混用嗎？**
A：可以。新模型向後兼容，fromJson() 方法能解析舊格式。

**Q：會丟失現有數據嗎？**
A：不會。保留了 SharedPreferences，新模型只在需要時才遷移到 SQLite。

**Q：需要立即遷移到新模型嗎？**
A：不需要。可以逐步集成，現有功能完全保留。

---

需要幫助集成嗎？查看 `screens/`、`services/` 中的實現範例。

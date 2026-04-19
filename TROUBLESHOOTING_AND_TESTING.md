# 錢錢管家 - 故障排除與測試指南

> 解決常見問題 | 完整測試步驟

---

## 🔧 常見問題與解決方案

### 依賴和編譯問題

#### 問題 1：`flutter pub get` 失敗

**症狀**：
```
Error: Connection timeout
Pub blocked on network request
```

**解決方案**：
```bash
# 清除 pub 快取
flutter pub cache clean

# 重新下載依賴
flutter pub get

# 如果仍然失敗，使用 git 源
flutter pub get --offline
```

#### 問題 2：版本衝突

**症狀**：
```
The current Dart SDK version is 3.4.0
The newest version of X requires Dart 3.5.0
```

**解決方案**：
```bash
# 更新 Flutter
flutter upgrade

# 或指定 Dart 版本
flutter config --enable-web
flutter doctor -v
```

#### 問題 3：編譯錯誤

**症狀**：
```
Type 'X' is not a subtype of type 'Y'
```

**解決方案**：
```bash
# 清除構建快取
flutter clean

# 清除 pub 快取
rm -rf pubspec.lock
flutter pub get

# 重新構建
flutter run
```

---

### 運行時問題

#### 問題 4：SQLite 初始化失敗

**症狀**：
```
MissingPluginException: No implementation found for method getDatabasesPath
```

**解決方案**：
```dart
// 確保已添加依賴
dependencies:
  sqflite: ^2.3.0
  path_provider: ^2.1.0

// 重新運行
flutter clean
flutter pub get
flutter run
```

#### 問題 5：數據遷移失敗

**症狀**：
```
DatabaseException: no such table: expenses
```

**解決方案**：
```dart
// 運行遷移工具
final result = await MigrationHelper.migrateFromSharedPreferences();
if (!result.success) {
  AppLogger.error('Migration failed: ${result.message}');
}

// 驗證遷移
final isValid = await MigrationHelper.validateMigration(
  expectedExpenseCount: oldCount,
  expectedFixedCount: oldFixedCount,
);
```

#### 問題 6：備份文件找不到

**症狀**：
```
FileSystemException: Cannot open file
```

**解決方案**：
```dart
// 檢查備份目錄
final backupDir = await getApplicationDocumentsDirectory();
final dir = Directory('${backupDir.path}/Money_App_Backups');
if (!await dir.exists()) {
  await dir.create(recursive: true);
}

// 列出備份文件
final backups = await backupService.getBackupList();
print('Backups: $backups');
```

---

### UI 問題

#### 問題 7：黑屏或空白屏幕

**症狀**：
```
應用啟動後顯示黑屏
```

**解決方案**：
```dart
// 確保 AppState 已加載
if (!appState.loaded) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

// 檢查日志
AppLogger.info('App started');
AppLogger.debug('AppState loaded: ${appState.loaded}');
```

#### 問題 8：主題切換不工作

**症狀**：
```
深色模式切換後 UI 未更新
```

**解決方案**：
```dart
// 確保 ThemeProvider 使用了 ChangeNotifier
class ThemeProvider extends ChangeNotifier {
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs?.setBool(_themePrefKey, _isDarkMode);
    notifyListeners();  // ✅ 重要：必須調用 notifyListeners
  }
}

// UI 中使用 Consumer
Consumer<ThemeProvider>(
  builder: (context, themeProvider, _) {
    return MaterialApp(
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  },
)
```

#### 問題 9：搜索結果為空

**症狀**：
```
搜索返回零結果
```

**解決方案**：
```dart
// 檢查查詢字符串
if (query.isEmpty) {
  results = [];
  return;
}

// 檢查數據源
print('Total expenses: ${expenses.length}');
print('Query: $query');

// 使用日志調試
AppLogger.info('Search query: $query');
AppLogger.info('Found ${results.length} results');
```

---

## 🧪 測試指南

### 單元測試

#### 運行所有測試

```bash
# 運行所有測試
flutter test

# 運行特定測試文件
flutter test test/unit/models_test.dart

# 生成覆蓋率報告
flutter test --coverage
```

#### 編寫新測試

```dart
// test/unit/search_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/services/search_service.dart';

void main() {
  group('SearchService Tests', () {
    test('Search finds expenses by title', () async {
      final service = SearchService();
      final expenses = [
        ExpenseItem(
          title: '午餐',
          category: '餐飲',
          amount: 12000,
          date: DateTime.now(),
        ),
      ];

      final results = await service.searchExpenses(
        expenses,
        query: '午',
      );

      expect(results.length, greaterThan(0));
      expect(results[0].item.title, contains('午'));
    });
  });
}
```

### 集成測試

```dart
// test/integration/app_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/main.dart';

void main() {
  group('App Flow Tests', () {
    testWidgets('Add expense flow', (WidgetTester tester) async {
      await tester.pumpWidget(const MoneyApp());
      
      // 點擊 FAB
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // 填寫表單
      await tester.enterText(
        find.byType(TextField).first,
        '午餐',
      );
      
      // 點擊保存
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      // 驗證支出已添加
      expect(find.text('午餐'), findsOneWidget);
    });
  });
}
```

### 手動測試檢查清單

#### 基本功能
- [ ] 應用能成功啟動
- [ ] 首頁顯示預算進度
- [ ] 能新增支出
- [ ] **新增：能編輯支出**
- [ ] 能刪除支出
- [ ] 明細頁顯示支出列表
- [ ] 能按分類篩選

#### 新增功能
- [ ] **搜索功能能正常工作**
- [ ] **備份導出成功**
- [ ] **備份恢復成功**
- [ ] **深色模式能切換**
- [ ] **多語言能切換**
- [ ] **撤銷/重做能工作**

#### 數據完整性
- [ ] 刪除後數據已保存
- [ ] 刷新應用數據仍存在
- [ ] 備份文件格式正確
- [ ] 遷移後數據計數一致

#### 性能
- [ ] 列表滾動平滑（60 FPS）
- [ ] 搜索響應快（< 500ms）
- [ ] 應用啟動快（< 2s）
- [ ] 內存占用穩定

#### UI/UX
- [ ] 所有按鈕都能點擊
- [ ] 文本對齐正確
- [ ] 顏色看起來正確
- [ ] 沒有重疊或裁剪

---

## 📊 調試技巧

### 啟用調試日志

```dart
// main.dart
import 'core/utils/logger.dart';

void main() {
  AppLogger.info('App starting...');
  
  // 其他初始化代碼
}

// 在代碼中使用日志
AppLogger.info('User tapped add button');
AppLogger.debug('Expense created: $expense');
AppLogger.warning('Migration in progress');
AppLogger.error('Database query failed', error: exception);
```

### 使用 Flutter DevTools

```bash
# 打開 DevTools
devtools

# 或自動打開
flutter run
# 然後掃描控制台中的二維碼或點擊鏈接

# 在 DevTools 中：
# 1. Inspector - 檢查 Widget 樹
# 2. Profiler - 性能分析
# 3. Memory - 內存使用
# 4. Console - 查看日志
```

### 使用斷點調試

```dart
// 在代碼中設置斷點
void _onAddExpense() {
  debugger();  // ✅ 會在此停止
  final expense = ExpenseItem(...);
}

// 條件斷點
if (expense.amount > 10000) {
  debugger();  // 只在金額 > 10000 時停止
}
```

### 打印調試信息

```dart
// 完整的對象信息
print('Expense: $expense');

// 轉換為 JSON 方便查看
print(jsonEncode(expense.toJson()));

// 使用 AppLogger
AppLogger.info('Complete expense data: ${expense.toJson()}');
```

---

## 🔍 測試場景

### 場景 1：新增和編輯

```
1. 打開應用
2. 點擊 + 按鈕
3. 輸入："午餐"，分類："餐飲"，金額："120"
4. 點擊儲存
✅ 支出應出現在列表中

5. 長按支出
6. 選擇"編輯"
7. 修改為："午餐便當"，金額："150"
8. 點擊更新
✅ 列表應更新，顯示"已編輯"標記
```

### 場景 2：搜索

```
1. 添加多個支出
2. 點擊搜索按鈕
3. 輸入："咖啡"
✅ 應過濾出相關支出

4. 選擇日期範圍
✅ 結果應根據日期過濾

5. 選擇分類："餐飲"
✅ 結果應根據分類過濾
```

### 場景 3：備份和恢復

```
1. 進入管理頁
2. 點擊"備份數據"
✅ 應看到"備份成功"提示
✅ 備份文件應保存到磁盤

3. 刪除一些支出
4. 點擊"恢復備份"
5. 選擇備份文件
✅ 數據應恢復到備份時刻
```

### 場景 4：深色模式

```
1. 進入管理頁
2. 打開"深色模式"開關
✅ UI 應立即變暗

3. 關閉開關
✅ UI 應立即變亮

4. 重新啟動應用
✅ 深色模式狀態應保存
```

---

## 🐛 常見 Bug 和修複

### Bug 1：編輯後數據未保存

**症狀**：編輯支出後刷新應用，修改消失

**原因**：編輯邏輯沒有調用 `_save()`

**修複**：
```dart
void updateExpense(String id, ExpenseItem newItem) {
  final index = expenses.indexWhere((e) => e.id == id);
  if (index >= 0) {
    expenses[index] = newItem.copyWith(editedAt: DateTime.now());
    _save();  // ✅ 必須調用 _save()
    notifyListeners();
  }
}
```

### Bug 2：搜索結果不準確

**症狀**：某些支出搜索不出來

**原因**：搜索算法的相關度計算有問題

**修複**：
```dart
double _calculateRelevance(String query, String text) {
  final lowerQuery = query.toLowerCase();
  final lowerText = text.toLowerCase();
  
  // 完全匹配
  if (lowerText == lowerQuery) return 1.0;
  
  // 包含
  if (lowerText.contains(lowerQuery)) return 0.8;
  
  // 開始於
  if (lowerText.startsWith(lowerQuery)) return 0.85;
  
  return 0.0;
}
```

### Bug 3：深色模式按鈕不工作

**症狀**：切換深色模式開關沒有反應

**原因**：未調用 `notifyListeners()`

**修複**：
```dart
Future<void> toggleTheme() async {
  _isDarkMode = !_isDarkMode;
  await _prefs?.setBool(_themePrefKey, _isDarkMode);
  notifyListeners();  // ✅ 必須調用
}
```

---

## ✅ 發佈前檢查清單

```
代碼質量
- [ ] 無編譯警告
- [ ] 無 null 安全問題
- [ ] 無未使用的導入
- [ ] 無調試代碼（debugger(), print()）

功能測試
- [ ] 所有核心功能正常
- [ ] 所有新增功能正常
- [ ] 沒有內存洩漏
- [ ] 沒有崩潰

性能
- [ ] 應用啟動 < 2s
- [ ] 列表滾動 60 FPS
- [ ] 搜索 < 500ms
- [ ] 內存占用 < 80MB

用戶體驗
- [ ] UI 看起來正確
- [ ] 文本清晰可讀
- [ ] 顏色搭配合理
- [ ] 動畫流暢

安全性
- [ ] 敏感數據已加密
- [ ] 輸入已驗證
- [ ] 沒有 SQL 注入風險
- [ ] 沒有暴露 API 密鑰

文檔
- [ ] README 已更新
- [ ] 集成指南已完成
- [ ] 故障排除指南已完成
- [ ] 所有更改已記錄
```

---

## 📞 獲取幫助

如果遇到問題：

1. **查看日志**
   ```bash
   flutter logs
   ```

2. **查看本指南**
   - 搜索症狀相關的常見問題

3. **運行診斷**
   ```bash
   flutter doctor -v
   ```

4. **檢查代碼註釋**
   - 所有關鍵代碼都有詳細註釋

5. **查看測試代碼**
   - `test/unit/models_test.dart` 有使用示例

---

**祝您測試愉快！有任何問題，請參考本指南。**

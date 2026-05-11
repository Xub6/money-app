# Qoryva 全公司 AI 交接文件
> 生成日期：2026-05-11
> 用途：讓任何 AI assistant（ChatGPT、Claude Mobile 等）能完整接手 Qoryva 任何任務
> 生成來源：Claude Code（AI Chief of Staff + CTO + COO + Software Engineer）

---

## 第一部分：如何與 Sean 協作

### Sean 是誰
- **角色**：Qoryva 創辦人 + 方向制定者
- **溝通語言**：全程繁體中文（無論 AI 是哪個模型）
- **GitHub 帳號**：Xub6

### 協作規則（必讀）

| Sean 說 | 代表 |
|---------|------|
| 「全權交給你」 | 完全授權，直接執行整條流程，無需逐步確認 |
| `check` / `查進度` | 執行公司級狀態報告（見第二部分格式）|
| 把截圖傳給你 | 主動讀圖，對齊設計細節，不要自行發揮 |

### Sean 不應該被拉去做的事
- API 付款介面錯誤排查
- SaaS 平台表單細節填寫
- n8n 節點 debug
- 重複性確認與測試
- 任何可自動化或文件化的低層操作

### 需要 Sean 批准的事
- 花費超過 $50 USD 的採購或訂閱
- 對外承諾（客戶、合作夥伴、公開聲明）
- 更換核心服務供應商
- 架構大改（影響多個模組）

### AI 可直接執行（不需 Sean 批准）
- 程式碼撰寫與修改
- 文件建立與更新
- SOP 建立
- workflow 設計與規劃
- 研究分析與報告
- 任何本地可逆操作

---

## 第二部分：公司概況

### 基本資料

| 項目 | 內容 |
|------|------|
| 公司名稱 | Qoryva |
| 定位 | AI-native company（由 AI agents 驅動日常營運）|
| 主網域 | qoryva.com |
| DNS 管理 | Cloudflare |
| 對外信箱 | hello@qoryva.com |
| 管理信箱 | admin@qoryva.com |
| 自動化平台 | n8n Cloud（Starter $20/月，已升級 2026-05-05）|
| AI Provider（production）| OpenRouter → openai/gpt-4o-mini |
| AI Provider（備援）| Anthropic Claude（credential 保留）|
| n8n workspace | https://qoryva.app.n8n.cloud |

### 公司願景
Qoryva 是 **AI-native company**，核心不是單一產品，而是一套由 AI agents、自動化流程、知識庫與任務系統組成的「公司作業系統」。終極形態：幾乎可由 AI 自行驅動日常運作，Sean 在幕後定方向、做高槓桿決策。

### 供應商策略（避免鎖定）

| 類型 | 現用 | 備援 |
|------|------|------|
| AI Provider | OpenRouter / gpt-4o-mini | Anthropic / Gemini / Groq |
| Email | Zoho Mail Lite | Resend / Mailgun |
| 自動化 | n8n Cloud | Make.com / Zapier |
| DNS / CDN | Cloudflare | — |
| App 開發 | Flutter（Dart）| React Native |
| App 發布 | Google Play Store | Apple App Store（未來）|
| 資料庫 | Notion（市場研究）| Supabase（未來）|

---

## 第三部分：公司模組進度

```
M0 基礎設施（網域/Email/DNS）  ✅ 完成
M1 客服自動化（Email→AI→回覆） ✅ 上線穩定（2026-04-28 起）
M2 公司作業系統（Company OS）  🔶 建置中（Bootstrap v1 完成）
M3 AI 角色與技能系統            🔶 初稿完成（10 角色、7 Skills）
M4 知識庫與公司記憶             📋 規劃中
M5 AI Provider 抽象層           📋 規劃中
M6 / MP-01 錢錢管家 App         🔶 Phase 3 進行中（條件式可上架）
```

### M0：基礎設施 ✅
- qoryva.com（Cloudflare DNS）
- Zoho Mail Lite：hello@、admin@、noreply@ 全設定
- MX / SPF / DKIM / DMARC 全部完成

### M1：客服自動化 ✅ 穩定上線
**架構（5 節點）：**
```
IMAP 每分鐘輪詢（admin@ inbox）
  → Filter（過濾 auto-reply / noreply / 自家信箱）
  → Code 節點（JSON.stringify 組 requestBody，處理換行/中文）
  → HTTP Request（OpenRouter → openai/gpt-4o-mini）
  → Send Reply via Zoho SMTP（from: hello@qoryva.com）
```

**驗證紀錄：**
- 英文端對端測試 ✅（2026-04-28，1 分鐘內回覆）
- 繁體中文端對端測試 ✅（2026-04-28，語言偵測正常）
- 錯誤通知機制 ✅（T-025，2026-05-05，workflow 失敗 → Gmail 警告）

**已知低優先待處理：**
- T-026：Customer Inquiry Log（Notion，Sean 確認後 AI 建 workflow）
- 中文簽名四行格式優化（小優化）

### M2：公司作業系統 🔶
已完成文件（路徑：`C:/Users/sshuser/qoryva/`）：
- `CLAUDE.md`：AI 工作規則（check 指令格式）
- `PROJECT_STATUS.md`：公司進度總覽（主入口）
- `company/COMPANY_OS.md`：AI 公司作業系統定義
- `company/AI_ROLES.md`：10 個 AI 角色定義
- `company/PROVIDER_STRATEGY.md`：供應商備援策略
- `company/BOOTSTRAP_CAPABILITIES.md`：啟動期能力地圖
- `operations/TASK_BOARD.md`：任務追蹤（T-001 ~ T-C32）
- `operations/DECISION_LOG.md`：高階決策記錄
- `operations/LESSONS_LEARNED.md`：失敗教訓庫（LL-001~004）
- `operations/INSTALL_PLAN.md`：安裝計畫（I-001~007）

### M3：AI 角色系統 🔶
**7 個 Claude Skills（路徑：`qoryva/.claude/skills/`）：**

| Skill | 職能 |
|-------|------|
| qoryva-check | 公司狀態報告（check 指令）|
| qoryva-chief-of-staff | 任務管理、決策分析、公司策略 |
| qoryva-software-engineer | 多產品工程（App Factory + 跨 App 複用）|
| qoryva-n8n-operator | n8n workflow 操作 SOP 與安全邊界 |
| qoryva-provider-strategy | AI Provider 選型與備援策略 |
| qoryva-safety-gate | Production 操作安全閘 |

**AI Design Director（Role 10，路徑：`ai-system/roles/AI_DESIGN_DIRECTOR.md`）：**
美感與體驗總監，負責 UI/UX、品牌、視覺素材。設計方向需 Sean 批准，細節優化可直接決策。

---

## 第四部分：MP-01 錢錢管家 App（最重要）

### 基本資訊

| 項目 | 內容 |
|------|------|
| App 名稱 | 錢錢管家 |
| 類型 | Flutter Android App（個人財務管理）|
| 本機路徑 | `C:/Users/sshuser/qoryva/products/apps/money-app/` |
| GitHub | https://github.com/Xub6/money-app（分支：main）|
| 套件名稱 | com.qoryva.moneyapp |
| 推送方式 | SSH（git@github.com:Xub6/money-app.git，金鑰 ~/.ssh/id_ed25519）|
| Flutter 路徑（Bash）| `/c/src/flutter/bin/flutter` |
| Flutter 路徑（Windows）| `C:/src/flutter/bin/flutter` |
| APK 輸出路徑 | `build/app/outputs/flutter-apk/app-release.apk` |
| AAB 輸出路徑 | `build/app/outputs/bundle/release/app-release.aab` |
| 目前 AAB 版本 | v2.0.0+2（49.5MB，已建置就緒）|
| 進度文件 | `progress_file.txt`（每次對話必讀）|

### 標準工作流程（每次改完功能都要跑完）
```bash
# 1. 建 APK（或 AAB）
cd ~/qoryva/products/apps/money-app
/c/src/flutter/bin/flutter build apk --release
# AAB: /c/src/flutter/bin/flutter build appbundle --release --no-tree-shake-icons

# 2. commit + push（SSH，不需要 PAT）
git add <改過的檔案>
git commit -m "feat/fix/design: 描述"
git push origin main

# 3. 更新 progress_file.txt → commit push
git add progress_file.txt
git commit -m "docs: 更新進度"
git push origin main
```

### 頁面架構（Tab）

| Tab | 頁面名稱 | 類別 | FAB 行為 |
|-----|---------|------|---------|
| 0 | DashboardPage | 記帳 | 新增支出（Icons.add）|
| 1 | DetailPage | 明細 | 新增支出（Icons.add）|
| 2 | InvestPage | 投資 | 新增投資（Icons.trending_up_rounded）|
| 3 | ManagePage | 管理 | 新增固定開銷（Icons.playlist_add_rounded）|

**導航方式：** PageView 左右滑動 + BottomAppBar 缺口中央 FAB

### 技術架構

| 項目 | 說明 |
|------|------|
| 狀態管理 | Provider（AppState、ThemeProvider）|
| 主要儲存 | SQLite（v3 schema）|
| 加密 | AES 資料加密服務 |
| 備份/還原 | 支援版本 1.0 / 2.0 / 3.0 相容 |
| 股價 | Yahoo Finance API（`lib/services/stock_service.dart`）|
| 台股中文名 | TWSE codeQuery API（`_fetchTwseNameByCode`）|
| 匯率 | `AppState.fxRates Map<String, double>`，並行抓取 7 幣別 |
| i18n | flutter_localizations，4 語言（繁中/簡中/英文/日文）|
| 圖示工具 | Node.js + canvas（`node_modules/canvas` 已安裝）|

### 顏色與設計系統

```dart
// 主色
AppColors.gold = Color(0xFFC59B63)

// 深色模式
底色：#111111
卡片：#1C1C1E

// 禁止！
Colors.white, Colors.black, Colors.grey  // 禁止 hardcode
AppColors.goldLight  // 禁止在深色模式使用

// 正確做法
Theme.of(context).colorScheme.*  // 一律用 colorScheme
```

**UI 風格：**
- 表單頁面：iOS grouped sections（section header + 欄位卡片，label 左 input 右）
- 深色模式：FilterChip / Card / TextField 的 backgroundColor/fillColor/color 容易遺漏，每次都要檢查
- Sean 傳截圖時要仔細讀圖，不要自行發揮

### 損益計算規則
```
netCurrentValueTwd = gross × (1 - feeRate - txTax)
台股 txTax = 0.003
美股 txTax = 0
```

### 已知技術陷阱

| 陷阱 | 說明 | 正確做法 |
|------|------|---------|
| 台股搜尋 | Yahoo Finance 搜不到中文 | 用 TWSE codeQuery API |
| 美股搜尋 | 用 Yahoo Finance /v1/finance/search | — |
| 台股刷新 | Yahoo 只回英文名 | 需按 🔄 才抓 TWSE 中文名 |
| Git push | Windows GCM 會攔截 HTTPS | 用 SSH，已設好金鑰 |
| 深色模式遺漏 | FilterChip/Card/TextField 容易忘 | 每次改 UI 都要檢查 |
| mounted 保護 | showSnackBar 前要檢查 | `if (mounted) ScaffoldMessenger...` |
| activeColor deprecated | Switch 的 activeColor 已棄用 | 改用 activeThumbColor |

### 已完成功能清單（截至 2026-05-11）

**Phase 1（2026-04-20 ~ 04-28）：**
深色模式（全 colorScheme）、投資頁改版、即時股價（Yahoo Finance）、台股中文搜尋（TWSE）、統一中央 FAB、頁面左右滑動（PageView）、帳戶管理（多幣別/淨資產）、券商手續費自訂（台股/美股分開）、損益計算（含稅費/淨值）、App 名稱「錢錢管家」、月份按鈕顯示實際數字、預算進度「含/不含固定開銷」切換

**Phase 2（2026-04-28 ~ 05-01）：**
SQLite 主要儲存（v3 schema）、AES 資料加密、CSV/Excel 導出（3 sheets）、備份/還原服務、復原提示框、Onboarding 6-slide 導覽、Feedback 回報功能（n8n webhook）、flutter analyze 0 warning、互動式 Coach-marks Tour（13 步）、i18n 國際化（4 語言 + 語言選擇器）、資料邏輯重構（ExpenseItem type+accountId / DB v3 / 帳戶餘額連動）、Play Store 上架素材（截圖×5 / Feature Graphic / Privacy Policy）、Firebase Auth 框架（預設關閉）

**Phase 3 進行中（2026-05-02 ~ 05-11）：**
- 支出分析升級（甜甜圈圖 + 時間切換 + 分類篩選，2026-05-02）
- 股票帳戶餘額同步（2026-05-07）
- 固定開銷自動執行（2026-05-07）
- 震動回饋全覆蓋（2026-05-09）
- 借款紀錄功能完整 CRUD（LoanRecord / LoanPayment，2026-05-09）
- i18n 全面覆蓋（50+ key，4 語言，loan/account/invest/category，2026-05-10）
- 貸款型固定開銷自動建立欠款帳戶（_getOrCreateLoanDebtAccount，linkedDebtAccountId 持久化，2026-05-10）
- 資產頁「含股票帳戶」開關（SharedPreferences 持久化，2026-05-10）
- QA MAX 全審計 P0/P1 修復（fixedTotal 雙重計算、投資損益不一致，2026-05-11）
- 新手導覽重設計（功能展示 → 設定引導邏輯，13 步，2026-05-11）

### 上架進度

| 項目 | 狀態 |
|------|------|
| Play Console 帳戶建立 | ✅ 完成 |
| 身分驗證 | ✅ 通過（2026-05-10）|
| 電話驗證 | ✅ 通過（2026-05-10）|
| Privacy Policy | ✅ GitHub Pages 上線 |
| AAB v2.0.0+2 建置 | ✅ 就緒（49.5MB）|
| P1-3 QA（語言切換循環）| ✅ Sean 真機驗收通過 |
| QA MAX 審計 P0/P1 修復 | ✅ 完成（2026-05-11）|
| Play Console 建立 App | ❌ 待 Sean 操作 |
| 上傳 AAB + 填商店資料 | ❌ Sean 建立 App 後，AI 接手 |
| 送審 | ❌ 待 AI 執行 |

### P2 待修（不阻擋上架，v2.1 修）
1. FX 備份機制
2. 借款利息收入記帳
3. 跨幣別轉帳
4. clearAll 後 debt account 清除

### 7 項待 Sean 真機確認
（詳見 progress_file.txt，建立 App 前先確認，避免送審退件）

---

## 第五部分：目前阻塞點與下一步

### 最高優先（Sean 需做）

**1. Play Console 建立 App（本週內）**
- 登入 https://play.google.com/console
- 建立新 App：套件名稱 `com.qoryva.moneyapp`，App 名稱「錢錢管家」
- 截圖告知 AI → AI 全程接手後續

**2. 真機確認 7 項**
- 見 progress_file.txt 清單
- 與建立 App 同步進行

**3. Notion 設定（截止建議 2026-05-14）**
- 建立 3 個 Notion DB（規格：`qoryva/infrastructure/notion-database-setup.md`）
- 取得 Notion API Token
- 告知 AI → AI 建立 3 個 n8n workflows（市場研究系統）

### AI 可接手（Sean 完成上述後）

1. **上架全流程**：上傳 AAB → 填商店文案 → 資料安全表單 → 內容分級問卷 → 截圖上傳 → 送審
2. **T-026**：Customer Inquiry Log n8n workflow（Notion）
3. **P2 修復清單**：Sean 授權後執行

---

## 第六部分：Check 指令格式

當 Sean 輸入 `check` 或「查進度」，固定回覆以下結構（繁體中文）：

1. **公司整體進度（3-5 句）**
2. **是否偏離原始願景**（是 / 否 / 部分偏移）
3. **目前最大阻塞點**（根因，不是表面錯誤）
4. **Sean 應該做的決策**（高槓桿事項 + 截止時間）
5. **AI 可委派的清單**
6. **下一步最高槓桿 3 件事**（排序 + 原因）
7. **四維度評估**（AI 公司方向 / Sean 解放程度 / 供應商風險 / 流程化程度）
8. **風險提醒**（戰略級）
9. **建議更新的文件**

Check 完成後更新 `PROJECT_STATUS.md` 的 Check 記錄表。

---

## 第七部分：重要文件路徑總覽

```
C:/Users/sshuser/
├── qoryva/
│   ├── CLAUDE.md                    ← AI 工作規則
│   ├── PROJECT_STATUS.md            ← 公司進度總覽（主入口）
│   ├── company/
│   │   ├── COMPANY_OS.md            ← 公司作業系統
│   │   ├── AI_ROLES.md              ← 10 個 AI 角色
│   │   ├── PROVIDER_STRATEGY.md     ← 供應商策略
│   │   └── BOOTSTRAP_CAPABILITIES.md
│   ├── operations/
│   │   ├── TASK_BOARD.md            ← 任務清單
│   │   ├── DECISION_LOG.md          ← 決策記錄
│   │   └── LESSONS_LEARNED.md       ← 失敗教訓庫
│   ├── products/
│   │   ├── APP_FACTORY.md           ← 新產品標準流程（Stage 0-15）
│   │   ├── PRODUCT_REGISTRY.md      ← 產品登記表
│   │   ├── RELEASE_CHECKLIST.md     ← 上架前檢查表
│   │   ├── REUSABLE_COMPONENTS.md   ← 可複用組件庫
│   │   └── apps/money-app/          ← 錢錢管家 App
│   │       ├── CLAUDE.md            ← App 開發規則
│   │       ├── progress_file.txt    ← 開發進度（每次必讀）
│   │       └── lib/                 ← Flutter 原始碼
│   ├── infrastructure/
│   │   ├── notion-database-setup.md ← Notion DB 設計規格
│   │   └── OPENROUTER_MIGRATION_PLAN.md
│   ├── automations/n8n/
│   │   └── MARKET_RESEARCH_WORKFLOWS.md ← 市場研究 workflow 設計
│   ├── ai-system/
│   │   └── roles/AI_DESIGN_DIRECTOR.md
│   └── .claude/skills/              ← Claude Skills 模組
└── .ssh/id_ed25519                  ← GitHub SSH 金鑰（已設好）
```

---

## 第八部分：里程碑紀錄

| 日期 | 里程碑 |
|------|--------|
| 2026-04-24 | M0 完成（網域/Email/DNS）|
| 2026-04-28 | M1 production 上線（英中雙語 AI 自動回覆）|
| 2026-04-28 | MP-01 Phase 1 100% 完成 |
| 2026-05-01 | MP-01 Phase 2 100% 完成（i18n + SQLite + 加密 + Excel）|
| 2026-05-05 | n8n Starter 升級（Trial 到期風險解除）|
| 2026-05-05 | T-025 錯誤通知 workflow 上線驗收 |
| 2026-05-05 | Google Play Console 帳戶建立 + 身分驗證送出 |
| 2026-05-05 | Privacy Policy GitHub Pages 上線 |
| 2026-05-10 | 公司資料夾全面重整（Qoryva 統一結構）|
| 2026-05-10 | 市場研究 SOP + 自動化體系建立 |
| 2026-05-10 | Google Play Console 身分驗證 ✅ 通過 |
| 2026-05-10 | Google Play Console 電話驗證 ✅ 通過 |
| 2026-05-10 | AAB v2.0.0+2 建置完成（49.5MB）|
| 2026-05-10 | P1-3 QA 語言切換循環測試 ✅ 通過 |
| 2026-05-11 | QA MAX 審計完成，P0/P1 全修復 |
| 2026-05-11 | 新手導覽重設計（13 步設定引導邏輯）|

---

*本文件由 Claude Code 自動生成並維護。如需更新，請在 Windows 本機執行 Claude Code。*

# 🚨 重大なバグ分析レポート - EA v2.0.1

## 発見日時
2025年1月

## 概要
EA全体のロジックフローを検証した結果、自動売買として正しく稼働しない可能性のある**3つの重大な問題**を発見しました。

---

## 🐛 問題1: OnTick()のバーチェックとタイムフレーム不整合（最重要）

### 問題箇所
`OnTick()` 関数 169-210行

### 問題内容

```mql5
void OnTick() {
   // 新しいバーチェック（TimeframeMonitorのみ）
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, TimeframeMonitor, 0);  // ← H4

   if(currentBarTime == lastBarTime) {
      // トレーリングストップのみ処理
      if(UseTrailingStop) {
         ManageTrailingStop();
      }
      return;  // ← ここで終了
   }

   // ... メインロジック ...

   // 第3波エントリー条件チェック（TimeframeExecute使用）
   if(g_waitingForWave3Entry && g_wave1Confirmed && g_wave2Confirmed) {
      if(CheckWave3EntryConditions()) {  // ← H1の価格を使用
         ExecuteWave3Entry();
      }
   }
}
```

### 具体的な問題

**設定例:**
- `TimeframeMonitor = H4` (4時間足)
- `TimeframeExecute = H1` (1時間足)

**動作:**
1. OnTick()はH4の新しいバーでのみメインロジックを実行
2. H4の新しいバーは4時間に1回
3. しかし第3波エントリー判定はH1の価格を使用
4. **H1の3本分のエントリーチャンスを逃す！**

**タイムライン例:**
```
00:00 - H4新バー → エントリー判定実行（H1で条件不成立）
01:00 - H1新バー → スキップ（H4は新バーでない）★逃す
02:00 - H1新バー → スキップ（H4は新バーでない）★逃す
03:00 - H1新バー → スキップ（H4は新バーでない）★逃す
04:00 - H4新バー → エントリー判定実行（もう遅い）
```

### 影響
- **致命的**: エントリーチャンスを大幅に逃す
- TimeframeMonitorとTimeframeExecuteが異なる場合、機能不全

---

## 🐛 問題2: CheckWave3EntryConditions()のタイムフレーム混在

### 問題箇所
`CheckWave3EntryConditions()` 関数 454-499行

### 問題内容

```mql5
bool CheckWave3EntryConditions() {
   // TimeframeExecute（H1）の価格を取得
   double currentPrice = iClose(_Symbol, TimeframeExecute, 0);  // H1
   double previousPrice = iClose(_Symbol, TimeframeExecute, 1);
   double price2BarsAgo = iClose(_Symbol, TimeframeExecute, 2);

   if(g_currentTrendState == TREND_STATE_UPTREND) {
      // TimeframeMonitor（H4）で検出された第2波終値と比較
      bool condition1 = currentPrice > g_wave2EndPrice;  // ← H1 vs H4の価格
      // ...
   }
}
```

### 具体的な問題

**シナリオ:**
1. H4（TimeframeMonitor）で第2波を検出
   - 第2波終値: 149.500（H4の終値）
2. H1（TimeframeExecute）でエントリー判定
   - H1の現在価格: 149.600

**問題点:**
- H4の1本のローソク足には、H1の4本分の情報が含まれる
- H4で149.500と記録されても、その中でH1は149.400～149.700と動いている可能性
- 単純な価格比較では不正確

**図解:**
```
H4足: |====== 149.500 ======|
H1足: |149.4|149.5|149.6|149.7|
             ↑
         第2波終値（H4）

現在H1: 149.600
condition1: 149.600 > 149.500 = true ← 正確か？
```

### 影響
- **高**: 不正確なエントリーシグナル
- タイミングのずれによる損失の可能性

---

## 🐛 問題3: CanOpenNewPosition()の実装不足

### 問題箇所
`CanOpenNewPosition()` 関数 763-783行

### 問題内容

```mql5
bool CanOpenNewPosition() {
   int openPositions = 0;

   for(int i = 0; i < PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i))) {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == 20250327) {  // ← ハードコード
            openPositions++;
         }
      }
   }

   if(openPositions >= MaxOpenPositions) {
      return false;
   }

   return true;
}
```

### 問題点

1. **マジックナンバーのハードコード**
   - OnInit()で `trade.SetExpertMagicNumber(20250327)` を設定
   - しかし関数内で直接 `20250327` を使用
   - 変更時に不整合の可能性

2. **通貨ペアチェックのみ**
   - 現在のシンボルのポジションのみカウント
   - しかしEAは1つのシンボルでしか動作しない想定
   - これは実は問題ないかもしれない

### 影響
- **低～中**: メンテナンス性の問題
- マジックナンバー変更時にバグの可能性

---

## 🐛 問題4: UpdatePushLowPullbackHigh()の初期化問題

### 問題箇所
`UpdatePushLowPullbackHigh()` 関数 228-290行

### 問題内容

```mql5
void UpdatePushLowPullbackHigh() {
   // ...
   bool isPriceAboveEMA = close[0] > g_emaFast[0];

   // 押し安値の更新（上昇トレンド時）
   if(isPriceAboveEMA) {
      for(int i = 1; i < 50; i++) {
         if(low[i] <= g_emaFast[i] || close[i] <= g_emaFast[i]) {
            // ...
            // 押し安値更新
            if(candidateLow > g_pushLow || g_pushLow == 0) {
               g_pushLow = candidateLow;
            }
            break;  // ← 1回だけ更新
         }
      }
   }

   // 戻り高値の更新（下降トレンド時）
   if(!isPriceAboveEMA) {  // ← else if でない
      // ...
   }
}
```

### 問題点

1. **初回実行時の挙動**
   - `g_pushLow = 0` の初期値
   - `|| g_pushLow == 0` により、初回は任意の値で更新される
   - これ自体は問題ない

2. **isPriceAboveEMAの判定が両方実行される可能性**
   - `if(isPriceAboveEMA)` と `if(!isPriceAboveEMA)` は排他的
   - しかし、価格がEMAとまったく同じ場合（稀）、両方falseになる
   - 実際にはdouble型なので完全一致は稀

3. **break後の処理**
   - 最初に見つかった候補のみ使用
   - より良い候補が後にあっても無視
   - これは設計通りかもしれない

### 影響
- **低**: 軽微な問題、実運用への影響は限定的

---

## 🔧 推奨される修正

### 修正1: OnTick()のバーチェック（最優先）

```mql5
// === 修正前 ===
void OnTick() {
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, TimeframeMonitor, 0);

   if(currentBarTime == lastBarTime) {
      if(UseTrailingStop) ManageTrailingStop();
      return;  // ← 早期リターン
   }
   // ...
}
```

```mql5
// === 修正後（案1: TimeframeExecuteでチェック）===
void OnTick() {
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, TimeframeExecute, 0);  // ← 変更

   if(currentBarTime == lastBarTime) {
      if(UseTrailingStop) ManageTrailingStop();
      return;
   }

   // TimeframeMonitorの更新は定期的に
   static datetime lastMonitorUpdate = 0;
   if(currentBarTime != lastMonitorUpdate) {
      UpdatePushLowPullbackHigh();
      CheckTrendReversal();
      ValidateWave2Retracement();
      lastMonitorUpdate = currentBarTime;
   }

   // TimeframeExecuteでエントリーチェック（毎バー）
   if(g_waitingForWave3Entry) {
      if(CheckWave3EntryConditions()) {
         ExecuteWave3Entry();
      }
   }
}
```

```mql5
// === 修正後（案2: 両方チェック）===
void OnTick() {
   static datetime lastMonitorBarTime = 0;
   static datetime lastExecuteBarTime = 0;

   datetime currentMonitorBar = iTime(_Symbol, TimeframeMonitor, 0);
   datetime currentExecuteBar = iTime(_Symbol, TimeframeExecute, 0);

   // トレーリングストップは毎ティック
   if(UseTrailingStop) ManageTrailingStop();

   // TimeframeMonitorの新バーで波動検出
   if(currentMonitorBar != lastMonitorBarTime) {
      if(!UpdateIndicatorData()) return;

      UpdatePushLowPullbackHigh();
      CheckTrendReversal();
      ValidateWave2Retracement();

      lastMonitorBarTime = currentMonitorBar;
   }

   // TimeframeExecuteの新バーでエントリー判定
   if(currentExecuteBar != lastExecuteBarTime) {
      if(g_waitingForWave3Entry) {
         if(CheckWave3EntryConditions()) {
            ExecuteWave3Entry();
         }
      }
      lastExecuteBarTime = currentExecuteBar;
   }
}
```

**推奨: 案2（両方チェック）**
- 波動検出はTimeframeMonitorで
- エントリー判定はTimeframeExecuteで
- それぞれ独立して動作

---

### 修正2: CheckWave3EntryConditions()の改善

```mql5
// === 修正後 ===
bool CheckWave3EntryConditions() {
   if(!g_waitingForWave3Entry || !g_wave1Confirmed || !g_wave2Confirmed) {
      return false;
   }

   // ★ TimeframeMonitorの価格も取得 ★
   double monitorCurrentPrice = iClose(_Symbol, TimeframeMonitor, 0);

   // TimeframeExecuteの価格を取得
   double currentPrice = iClose(_Symbol, TimeframeExecute, 0);
   double previousPrice = iClose(_Symbol, TimeframeExecute, 1);
   double price2BarsAgo = iClose(_Symbol, TimeframeExecute, 2);

   if(g_currentTrendState == TREND_STATE_UPTREND) {
      // ★ 両方のタイムフレームでチェック ★
      bool monitorCondition = monitorCurrentPrice > g_wave2EndPrice;
      bool executeCondition1 = currentPrice > g_wave2EndPrice;
      bool executeCondition2 = currentPrice > previousPrice;
      bool executeCondition3 = previousPrice > price2BarsAgo;

      // ★ すべての条件を満たす必要がある ★
      if(monitorCondition && executeCondition1 && executeCondition2 && executeCondition3) {
         if(EnableDebugMode) {
            Print("✅ 第3波買いエントリー条件成立");
            Print("   Monitor価格: ", monitorCurrentPrice, " > 第2波: ", g_wave2EndPrice);
            Print("   Execute: ", price2BarsAgo, " → ", previousPrice, " → ", currentPrice);
         }
         return true;
      }
   }

   // 下降トレンドも同様...

   return false;
}
```

---

### 修正3: マジックナンバーの定数化

```mql5
// === グローバル変数に追加 ===
const int EA_MAGIC_NUMBER = 20250327;

// === OnInit()で使用 ===
int OnInit() {
   trade.SetExpertMagicNumber(EA_MAGIC_NUMBER);
   // ...
}

// === CanOpenNewPosition()で使用 ===
bool CanOpenNewPosition() {
   int openPositions = 0;

   for(int i = 0; i < PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i))) {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == EA_MAGIC_NUMBER) {  // ← 定数使用
            openPositions++;
         }
      }
   }
   // ...
}
```

---

## 📊 優先度と影響度

| 問題 | 優先度 | 影響度 | 修正難易度 |
|------|--------|--------|----------|
| 問題1: OnTick()バーチェック | 🔴 最高 | 致命的 | 中 |
| 問題2: タイムフレーム混在 | 🟠 高 | 高 | 中 |
| 問題3: マジックナンバー | 🟡 中 | 低 | 易 |
| 問題4: 初期化問題 | 🟢 低 | 低 | - |

---

## ✅ 検証方法

### テスト1: OnTick()のバーチェック

```mql5
// テスト用のデバッグコードを追加
void OnTick() {
   static int tickCount = 0;
   tickCount++;

   if(EnableDebugMode && tickCount % 100 == 0) {
      Print("Tick: ", tickCount,
            " MonitorBar: ", iTime(_Symbol, TimeframeMonitor, 0),
            " ExecuteBar: ", iTime(_Symbol, TimeframeExecute, 0));
   }
   // ...
}
```

**期待される動作:**
- TimeframeMonitorとTimeframeExecuteの両方の新バーを検出
- エントリーチャンスを逃さない

---

## 🎯 修正後の期待される改善

1. **エントリーチャンスの増加**
   - H4/H1設定で、4倍のエントリー機会

2. **より正確なエントリータイミング**
   - タイムフレーム間の整合性が向上

3. **メンテナンス性の向上**
   - マジックナンバーの一元管理

---

## 📝 次のステップ

1. ✅ 問題1（OnTick）の修正（最優先）
2. ✅ 問題2（タイムフレーム混在）の修正
3. ✅ 問題3（マジックナンバー）の修正
4. ✅ 包括的なテスト
5. ✅ バックテストでの検証

---

**作成日:** 2025年1月
**対象バージョン:** v2.0.1 → v2.0.2（修正予定）

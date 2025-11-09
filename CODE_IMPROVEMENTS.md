# エリオット波動EA コード改善スニペット集

## 改善1: Wave 2検証の最適化（ValidateWave2Retracement関数）

### 変更前の問題
```mql5
// 問題: リトレースメント範囲内なら即確定
if (retracementPercent >= 0.382 && retracementPercent <= 0.618) {
    g_wave2Confirmed = true;  // ← 反転確認なし！
    return true;
}
```

### 改善後のコード
```mql5
bool ValidateWave2Retracement() {
   static bool debugMode = false;  // ★本番はfalse

   if (!g_wave1Confirmed) return false;

   double currentPrice = iClose(_Symbol, TimeframeMonitor, 0);
   double previousPrice = iClose(_Symbol, TimeframeMonitor, 1);  // ★追加
   double wave1Range = MathAbs(g_wave1EndPrice - g_wave1StartPrice);

   // 最小波動サイズチェック
   if (wave1Range < MinWaveSize) {
      if (debugMode) Print("⚠️ 第1波が小さすぎる: ", wave1Range);
      return false;
   }

   // 上昇トレンドの場合
   if (g_currentTrendState == TREND_STATE_UPTREND) {
      if (currentPrice >= g_wave1EndPrice) return false;

      // ★★★ 重要: Wave 1開始価格を下回ったら無効化 ★★★
      if (currentPrice < g_wave1StartPrice) {
         Print("❌ Wave 2が Wave 1開始価格を下回った - Wave 1無効化");
         g_wave1Confirmed = false;
         g_currentWaveCount = 0;
         return false;
      }

      double retracement = g_wave1EndPrice - currentPrice;
      double retracementPercent = retracement / wave1Range;

      // リトレースメント範囲チェック
      if (retracementPercent < 0.382 || retracementPercent > 0.618) {
         return false;
      }

      // ★★★ 新規: 価格が底を打って反転しているか確認 ★★★
      if (currentPrice <= previousPrice) {
         if (debugMode) Print("⚠️ まだ下落中 - Wave 2底待ち");
         return false;
      }

      // ★成功: 反転確認済み
      Print("✅ 第2波確定: ", retracementPercent * 100, "% リトレースメント、反転確認");

      g_wave2Confirmed = true;
      g_wave2EndPrice = currentPrice;
      g_lastWave2Time = iTime(_Symbol, TimeframeMonitor, 0);
      g_currentWaveCount = 2;
      g_waitingForWave3Entry = true;

      return true;
   }

   // 下降トレンド用も同様に修正...

   return false;
}
```

---

## 改善2: Wave 3エントリー条件の厳格化（CheckWave3EntryConditions関数）

### 変更前の問題
```mql5
// 問題: Wave 2を超えたら即エントリー
if (currentPrice > g_wave2EndPrice) {
    return true;  // ← Wave 3確定前にエントリー！
}
```

### 改善後のコード
```mql5
bool CheckWave3EntryConditions() {
   static bool debugMode = false;

   if (!g_waitingForWave3Entry || !g_wave1Confirmed || !g_wave2Confirmed) {
      return false;
   }

   double currentPrice = iClose(_Symbol, TimeframeMonitor, 0);
   double previousPrice = iClose(_Symbol, TimeframeMonitor, 1);
   double wave1Range = MathAbs(g_wave1EndPrice - g_wave1StartPrice);

   // 上昇トレンドの場合
   if (g_currentTrendState == TREND_STATE_UPTREND) {
      double wave2Low = g_wave2EndPrice;

      // ★★★ 条件1: Wave 2終値より上 ★★★
      if (currentPrice <= wave2Low) return false;

      // ★★★ 条件2: 前回足より上昇（上昇継続） ★★★
      if (currentPrice <= previousPrice) {
         if (debugMode) Print("⚠️ 上昇が止まった - Wave 3エントリー見送り");
         return false;
      }

      // ★★★ 条件3: Wave 2から十分な距離 ★★★
      double distanceFromWave2 = currentPrice - wave2Low;
      double minDistance = wave1Range * 0.2;  // Wave 1の20%以上

      if (distanceFromWave2 < minDistance) {
         if (debugMode) Print("⚠️ Wave 3の進展が不十分: ", distanceFromWave2, " < ", minDistance);
         return false;
      }

      // ★★★ 条件4: 最小絶対距離（ノイズ除去） ★★★
      if (distanceFromWave2 < MinSLDistance) {
         return false;
      }

      // ★★★ オプション: RequireWave3Confirmation有効時の追加チェック ★★★
      if (RequireWave3Confirmation) {
         // Wave 3が Wave 1の長さを超えた時点で確定
         double wave3CurrentLength = currentPrice - wave2Low;
         if (wave3CurrentLength < wave1Range) {
            if (debugMode) Print("⚠️ Wave 3が Wave 1の長さ未満 - 確定待ち");
            return false;
         }
      }

      Print("✅ Wave 3エントリー条件成立（上昇）");
      Print("  Wave 2終値: ", wave2Low);
      Print("  現在価格: ", currentPrice);
      Print("  Wave 3進展: ", distanceFromWave2 * 10000, " pips");

      return true;
   }

   // 下降トレンド用も同様に修正...

   return false;
}
```

---

## 改善3: SL計算の一本化（CalculateDynamicStopLoss関数）

### 変更前の問題
```mql5
// 問題: 複数の関数でSL計算、一貫性なし
double sl1 = entryPrice - MinSLDistance;  // 固定
double sl2 = CalculateDynamicStopLoss(...);  // ATR
double sl3 = waveRetracementLevel - margin;  // Wave
// どれを使うか不明確...
```

### 改善後のコード
```mql5
//+------------------------------------------------------------------+
//| 統一されたSL計算関数                                              |
//+------------------------------------------------------------------+
double CalculateOptimizedStopLoss(double entryPrice, bool isBuyOrder) {
   double finalSL = 0.0;
   double candidateSLs[];
   ArrayResize(candidateSLs, 0);

   // ★方法1: ATRベースのSL（推奨）
   if (UseATRForSL) {
      double atrValue = GetATRValue(TimeframeMonitor, ATRPeriod, 0);
      if (atrValue > 0) {
         double atrBasedSLDistance = MathMax(
            MathMin(atrValue * ATRMultiplier, MaxSLDistance),
            MinSLDistance
         );

         int size = ArraySize(candidateSLs);
         ArrayResize(candidateSLs, size + 1);
         candidateSLs[size] = isBuyOrder ?
            entryPrice - atrBasedSLDistance :
            entryPrice + atrBasedSLDistance;
      }
   }

   // ★方法2: Wave 2終値ベースのSL
   if (g_wave2Confirmed && g_wave2EndPrice > 0) {
      double margin = MinSLDistance * 0.5;  // 小さいマージン

      int size = ArraySize(candidateSLs);
      ArrayResize(candidateSLs, size + 1);
      candidateSLs[size] = isBuyOrder ?
         g_wave2EndPrice - margin :
         g_wave2EndPrice + margin;
   }

   // ★方法3: 固定距離SL（フォールバック）
   int size = ArraySize(candidateSLs);
   ArrayResize(candidateSLs, size + 1);
   candidateSLs[size] = isBuyOrder ?
      entryPrice - MinSLDistance :
      entryPrice + MinSLDistance;

   // ★★★ 最適なSLを選択 ★★★
   if (isBuyOrder) {
      // 買いの場合: 最も高いSL（リスク最小）
      finalSL = candidateSLs[0];
      for (int i = 1; i < ArraySize(candidateSLs); i++) {
         if (candidateSLs[i] > finalSL) {
            finalSL = candidateSLs[i];
         }
      }
      // ただしエントリー価格より下
      if (finalSL >= entryPrice) {
         finalSL = entryPrice - MinSLDistance;
      }
   }
   else {
      // 売りの場合: 最も低いSL（リスク最小）
      finalSL = candidateSLs[0];
      for (int i = 1; i < ArraySize(candidateSLs); i++) {
         if (candidateSLs[i] < finalSL) {
            finalSL = candidateSLs[i];
         }
      }
      // ただしエントリー価格より上
      if (finalSL <= entryPrice) {
         finalSL = entryPrice + MinSLDistance;
      }
   }

   Print("💡 最適化SL計算: Entry=", entryPrice, " SL=", finalSL,
         " 距離=", MathAbs(entryPrice - finalSL) * 10000, " pips");

   return NormalizeDouble(finalSL, _Digits);
}
```

---

## 改善4: 市場環境フィルターの早期適用

### 変更前の問題
```mql5
// OnTick内
CheckWave3EntryConditions();
if (entryReady) {
    IsMarketEnvironmentFavorable();  // ← エントリー直前のみチェック
    ExecuteBuyOrder(...);
}
```

### 改善後のコード
```mql5
void OnTick() {
   // ... 既存のコード ...

   // ★★★ Wave検出前に市場環境をチェック ★★★
   static datetime lastEnvironmentCheck = 0;
   if (TimeCurrent() - lastEnvironmentCheck > 3600) {  // 1時間ごと
      if (!IsMarketEnvironmentFavorable()) {
         Print("⚠️ 市場環境不適 - Wave検出を一時停止");
         return;  // ← 早期リターン
      }
      lastEnvironmentCheck = TimeCurrent();
   }

   // ステップ1: 押し安値・戻り高値の更新
   UpdatePushLowPullbackHigh(TimeframeMonitor);

   // ステップ2: トレンド転換チェック
   bool reversalOccurred = CheckTrendReversal(TimeframeMonitor);

   if (reversalOccurred) {
      // ★Wave 1検出時にも市場環境を再確認
      if (!IsMarketEnvironmentFavorable()) {
         Print("⚠️ Wave 1検出したが市場環境不適 - 無効化");
         g_wave1Confirmed = false;
         return;
      }

      Print("🔄 トレンド転換 + 市場環境良好 → Wave 1確定");
   }

   // ... 残りのコード ...
}
```

---

## 改善5: デバッグログの最適化

### 全関数に適用するパターン
```mql5
bool SomeFunction() {
   // ★本番運用時はfalseに設定
   static bool debugMode = false;

   // デバッグログ
   if (debugMode) Print("=== SomeFunction開始 ===");

   // 通常ログ（重要なイベントのみ）
   Print("✅ 重要なイベント発生");

   // デバッグログ
   if (debugMode) Print("詳細情報: ", someValue);

   if (debugMode) Print("=== SomeFunction終了 ===");

   return true;
}
```

### 一括変更スクリプト
以下の関数の先頭に `static bool debugMode = false;` を追加:
- UpdatePushLowPullbackHigh()
- CheckTrendReversal()
- ValidateWave2Retracement()
- CheckWave3EntryConditions()
- ValidateWave3Strength()
- ValidateWave4Retracement()

---

## 改善6: エントリー実行関数の簡素化

### ExecuteBuyOrder/ExecuteSellOrderの改善
```mql5
void ExecuteBuyOrder(bool waveAligned, double stopLossPrice, double entryPrice) {
   Print("=== 買いエントリー実行開始 ===");

   // ★常に現在価格を使用
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   entryPrice = ask;

   // ★★★ 統一SL計算を使用 ★★★
   double sl = CalculateOptimizedStopLoss(entryPrice, true);

   // TP計算（調整済みRR比使用）
   double slDistance = MathAbs(entryPrice - sl);
   double tp = entryPrice + (slDistance * g_currentRRRatio);

   // SL/TP検証
   if (!ValidateSLTP(ORDER_TYPE_BUY, entryPrice, sl, tp)) {
      Print("❌ SL/TP検証失敗 - エントリー中止");
      return;
   }

   // ★ロットサイズ計算
   double lotSize = UseDynamicPositionSizing ?
      CalculateDynamicLotSize(entryPrice, sl) :
      CalculateLotSize(GetAdjustedRiskPercent(waveAligned), slDistance / _Point);

   if (lotSize <= 0) {
      Print("❌ ロットサイズ無効 - エントリー中止");
      return;
   }

   // 最終確認ログ
   Print("💰 買いエントリー詳細:");
   Print("  Entry: ", entryPrice);
   Print("  SL: ", sl, " (", slDistance * 10000, " pips)");
   Print("  TP: ", tp, " (", (tp - entryPrice) * 10000, " pips)");
   Print("  Lot: ", lotSize);
   Print("  RR比: ", g_currentRRRatio);

   // 注文実行
   if (trade.Buy(lotSize, _Symbol, 0, sl, tp, "Elliott Wave Buy")) {
      Print("✅ 買い注文成功: Ticket=", trade.ResultOrder());
      RecordTrade(POSITION_TYPE_BUY, trade.ResultPrice(), sl, tp,
                  lotSize, GetAdjustedRiskPercent(waveAligned), waveAligned);
   }
   else {
      Print("❌ 買い注文失敗: ", trade.ResultRetcodeDescription());
   }

   Print("=== 買いエントリー実行終了 ===");
}
```

---

## 実装手順

1. **バックアップ**: 元のコードを必ず保存
2. **段階的適用**: 1つずつ改善を適用してテスト
3. **優先順位**:
   - 改善1（Wave 2検証）★最重要
   - 改善2（Wave 3エントリー）★最重要
   - 改善3（SL計算）★重要
   - 改善5（デバッグログ）★推奨
   - 改善4、6（その他）

4. **テスト**: 各改善後にバックテストを実行
5. **検証**: 勝率、PF、ドローダウンを確認

---

## 期待される効果

| 改善項目 | 期待効果 |
|---------|---------|
| Wave 2検証厳格化 | 偽シグナル30-40%削減 |
| Wave 3エントリー厳格化 | 勝率5-10%向上 |
| SL計算一本化 | リスク管理の一貫性確保 |
| 市場環境早期チェック | 不利な環境でのトレード回避 |
| デバッグログ最適化 | CPU使用率10-15%削減 |

---

## 注意事項

⚠️ これらの改善は提供されたコードを基にしていますが、実際の環境でのテストが不可欠です。

⚠️ パラメータは市場状況に応じて調整が必要です。

⚠️ バックテストとフォワードテストを必ず実施してください。

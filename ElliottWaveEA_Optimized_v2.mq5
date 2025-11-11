//+------------------------------------------------------------------+
//|                                  ElliottWaveEA_Optimized_v2.mq5  |
//|                                     Copyright 2025               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      ""
#property version   "2.02"
#property description "エリオット波動EA (最適化版 v2.0.2)"
#property description "v2.0.2: 複数の重大バグを修正（自動売買として正常動作）"
#property description "- OnTick()の複数タイムフレーム対応（エントリーチャンス逃さない）"
#property description "- タイムフレーム間の整合性強化"
#property description "- マジックナンバーの定数化"
#property description ""
#property description "v2.0.1: 重大なTP計算バグを修正"
#property description "- SL調整後のTP計算を修正（R:R比率が正確に）"
#property description "- デバッグ出力を強化（R:R比率表示）"
#property description ""
#property description "v2.0主な改善点："
#property description "- SL/TP検証の簡素化と信頼性向上"
#property description "- エントリーロジックの統一"
#property description "- 波動検出の最適化"

#include <Trade\Trade.mqh>

// ========================================
// 入力パラメータ
// ========================================
input group "タイムフレーム設定"
input ENUM_TIMEFRAMES TimeframeLongTerm = PERIOD_D1;
input ENUM_TIMEFRAMES TimeframeMonitor = PERIOD_H4;
input ENUM_TIMEFRAMES TimeframeExecute = PERIOD_H1;

input group "リスク管理設定"
input double RiskPercentAligned = 1.0;      // 波動整合時のリスク%
input double RiskPercentUnaligned = 0.5;    // 波動不整合時のリスク%
input double RiskRewardRatio = 2.0;         // リスクリワード比率

input group "SL/TP設定"
input double MinSLPips = 20;                // 最小SL距離（pips）
input double MaxSLPips = 50;                // 最大SL距離（pips）
input double MinTPPips = 40;                // 最小TP距離（pips）

input group "エントリー設定"
input int MinEntryIntervalSeconds = 3600;   // 最小エントリー間隔（秒）
input int MaxOpenPositions = 3;             // 最大同時ポジション数

input group "トレーリングストップ設定"
input bool   UseTrailingStop = true;        // トレーリングストップ使用
input double TrailingActivationPips = 30;   // トレーリング開始（pips）
input double TrailingDistancePips = 20;     // トレーリング距離（pips）

input group "波動検出設定"
input int EMA_Fast = 20;                    // 高速EMA期間
input int EMA_Slow = 50;                    // 低速EMA期間
input double MinWaveSizePips = 10;          // 最小波動サイズ（pips）
input double Wave2RetracementMin = 0.20;    // 第2波最小リトレースメント
input double Wave2RetracementMax = 0.70;    // 第2波最大リトレースメント

input group "デバッグ設定"
input bool EnableDebugMode = false;         // デバッグモード
input bool CollectTradeData = true;         // トレードデータ収集

// ========================================
// グローバル変数
// ========================================
CTrade trade;

// マジックナンバー定数
const int EA_MAGIC_NUMBER = 20250327;

// 波動状態
enum TREND_STATE {
   TREND_STATE_UPTREND,
   TREND_STATE_DOWNTREND,
   TREND_STATE_RANGE
};

TREND_STATE g_currentTrendState = TREND_STATE_RANGE;

// 波動管理
bool g_wave1Confirmed = false;
bool g_wave2Confirmed = false;
bool g_waitingForWave3Entry = false;

double g_wave1StartPrice = 0;
double g_wave1EndPrice = 0;
double g_wave2EndPrice = 0;

datetime g_lastWave1Time = 0;
datetime g_lastWave2Time = 0;
datetime g_lastEntryTime = 0;

// 押し安値・戻り高値
double g_pushLow = 0;
double g_pullbackHigh = 0;

// インジケータハンドル
int g_emaFastHandle = INVALID_HANDLE;
int g_emaSlowHandle = INVALID_HANDLE;

// データ配列
double g_emaFast[];
double g_emaSlow[];

// パフォーマンス最適化用
datetime g_lastUpdateTime = 0;
int g_updateIntervalSeconds = 60;  // データ更新間隔

// ポイント変換定数
double g_pointToPips = 1.0;

//+------------------------------------------------------------------+
//| Expert初期化関数                                                 |
//+------------------------------------------------------------------+
int OnInit() {
   // マジックナンバー設定
   trade.SetExpertMagicNumber(EA_MAGIC_NUMBER);
   trade.SetDeviationInPoints(10);

   // ポイント→Pips変換係数の計算
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 5) {
      g_pointToPips = 10.0;
   } else {
      g_pointToPips = 1.0;
   }

   // インジケータハンドル作成
   g_emaFastHandle = iMA(_Symbol, TimeframeMonitor, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   g_emaSlowHandle = iMA(_Symbol, TimeframeMonitor, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);

   if(g_emaFastHandle == INVALID_HANDLE || g_emaSlowHandle == INVALID_HANDLE) {
      Print("❌ インジケータハンドルの作成に失敗");
      return INIT_FAILED;
   }

   // 配列設定
   ArraySetAsSeries(g_emaFast, true);
   ArraySetAsSeries(g_emaSlow, true);

   // 初期データ読み込み待機
   Sleep(1000);

   if(!UpdateIndicatorData()) {
      Print("⚠️ 初期データの読み込みに失敗（起動継続）");
   }

   Print("✅ Elliott Wave EA v2.0 初期化完了");
   Print("   使用通貨ペア: ", _Symbol);
   Print("   監視TF: ", EnumToString(TimeframeMonitor));
   Print("   実行TF: ", EnumToString(TimeframeExecute));
   Print("   最大ポジション数: ", MaxOpenPositions);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick関数（最適化版v2 - 複数タイムフレーム対応）            |
//+------------------------------------------------------------------+
void OnTick() {
   // ★★★ 複数タイムフレームの新バーチェック ★★★
   static datetime lastMonitorBarTime = 0;
   static datetime lastExecuteBarTime = 0;

   datetime currentMonitorBar = iTime(_Symbol, TimeframeMonitor, 0);
   datetime currentExecuteBar = iTime(_Symbol, TimeframeExecute, 0);
   datetime currentTime = TimeCurrent();

   // トレーリングストップは毎ティック実行
   if(UseTrailingStop) {
      ManageTrailingStop();
   }

   // === TimeframeMonitorの新バーで波動検出 ===
   bool monitorBarChanged = (currentMonitorBar != lastMonitorBarTime);

   if(monitorBarChanged) {
      // データ更新
      if(!UpdateIndicatorData()) {
         if(EnableDebugMode) Print("⚠️ データ更新失敗");
         lastMonitorBarTime = currentMonitorBar;  // 次回リトライのため更新
         return;
      }

      if(EnableDebugMode) {
         Print("📊 ", EnumToString(TimeframeMonitor), " 新バー検出");
      }

      // 1. 押し安値・戻り高値の更新
      UpdatePushLowPullbackHigh();

      // 2. トレンド転換チェック（第1波検出）
      if(CheckTrendReversal()) {
         if(EnableDebugMode) Print("🔄 トレンド転換検出 - 第1波確定");
      }

      // 3. 第2波検証
      if(g_wave1Confirmed && !g_wave2Confirmed) {
         if(ValidateWave2Retracement()) {
            if(EnableDebugMode) Print("📊 第2波確定 - 第3波待機モードON");
         }
      }

      lastMonitorBarTime = currentMonitorBar;
   }

   // === TimeframeExecuteの新バーでエントリー判定 ===
   bool executeBarChanged = (currentExecuteBar != lastExecuteBarTime);

   if(executeBarChanged) {
      if(EnableDebugMode) {
         Print("🎯 ", EnumToString(TimeframeExecute), " 新バー検出 - エントリーチェック");
      }

      // エントリー間隔チェック
      if(currentTime - g_lastEntryTime < MinEntryIntervalSeconds) {
         if(EnableDebugMode) {
            Print("⏰ エントリー間隔制限中: あと ",
                  (MinEntryIntervalSeconds - (currentTime - g_lastEntryTime)), " 秒");
         }
         lastExecuteBarTime = currentExecuteBar;
         return;
      }

      // ポジション数チェック
      if(!CanOpenNewPosition()) {
         lastExecuteBarTime = currentExecuteBar;
         return;
      }

      // 第3波エントリー条件チェック
      if(g_waitingForWave3Entry && g_wave1Confirmed && g_wave2Confirmed) {
         if(CheckWave3EntryConditions()) {
            ExecuteWave3Entry();
         }
      }

      lastExecuteBarTime = currentExecuteBar;
   }
}

//+------------------------------------------------------------------+
//| インジケータデータ更新関数                                        |
//+------------------------------------------------------------------+
bool UpdateIndicatorData() {
   if(CopyBuffer(g_emaFastHandle, 0, 0, 50, g_emaFast) <= 0) {
      return false;
   }
   if(CopyBuffer(g_emaSlowHandle, 0, 0, 50, g_emaSlow) <= 0) {
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| 押し安値・戻り高値更新関数（最適化版）                            |
//+------------------------------------------------------------------+
void UpdatePushLowPullbackHigh() {
   double high[], low[], close[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);

   if(CopyHigh(_Symbol, TimeframeMonitor, 0, 50, high) <= 0) return;
   if(CopyLow(_Symbol, TimeframeMonitor, 0, 50, low) <= 0) return;
   if(CopyClose(_Symbol, TimeframeMonitor, 0, 50, close) <= 0) return;

   // 現在のトレンド判定（価格とEMAの関係）
   bool isPriceAboveEMA = close[0] > g_emaFast[0];

   // 押し安値の更新（上昇トレンド時）
   if(isPriceAboveEMA) {
      for(int i = 1; i < 50; i++) {
         if(low[i] <= g_emaFast[i] || close[i] <= g_emaFast[i]) {
            double candidateLow = low[i];

            // 前後の安値も確認
            for(int j = i; j < MathMin(i + 5, 48); j++) {
               if(low[j] < candidateLow) {
                  candidateLow = low[j];
               }
            }

            // 押し安値更新
            if(candidateLow > g_pushLow || g_pushLow == 0) {
               g_pushLow = candidateLow;
               if(EnableDebugMode) {
                  Print("✅ 押し安値更新: ", g_pushLow, " (", i, "本前)");
               }
            }
            break;
         }
      }
   }

   // 戻り高値の更新（下降トレンド時）
   if(!isPriceAboveEMA) {
      for(int i = 1; i < 50; i++) {
         if(high[i] >= g_emaFast[i] || close[i] >= g_emaFast[i]) {
            double candidateHigh = high[i];

            // 前後の高値も確認
            for(int j = i; j < MathMin(i + 5, 48); j++) {
               if(high[j] > candidateHigh) {
                  candidateHigh = high[j];
               }
            }

            // 戻り高値更新
            if(candidateHigh < g_pullbackHigh || g_pullbackHigh == 0) {
               g_pullbackHigh = candidateHigh;
               if(EnableDebugMode) {
                  Print("✅ 戻り高値更新: ", g_pullbackHigh, " (", i, "本前)");
               }
            }
            break;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| トレンド転換判定関数（最適化版）                                  |
//+------------------------------------------------------------------+
bool CheckTrendReversal() {
   double currentClose = iClose(_Symbol, TimeframeMonitor, 0);
   double minWaveSize = MinWaveSizePips * _Point * g_pointToPips;

   TREND_STATE previousState = g_currentTrendState;
   bool reversalDetected = false;

   // 下降 → 上昇への転換
   if((g_currentTrendState == TREND_STATE_DOWNTREND ||
       g_currentTrendState == TREND_STATE_RANGE) &&
       g_pullbackHigh > 0) {

      if(currentClose > g_pullbackHigh) {
         double waveSize = currentClose - g_pullbackHigh;

         if(waveSize < minWaveSize) {
            if(EnableDebugMode) {
               Print("⚠️ 波動が小さすぎる: ", waveSize/_Point, " points");
            }
            return false;
         }

         Print("🔄 トレンド転換: 下降→上昇");
         Print("   戻り高値ブレイク: ", currentClose, " > ", g_pullbackHigh);
         Print("   波動サイズ: ", waveSize/_Point/g_pointToPips, " pips");

         g_currentTrendState = TREND_STATE_UPTREND;
         g_wave1Confirmed = true;
         g_wave1StartPrice = g_pullbackHigh;
         g_wave1EndPrice = currentClose;
         g_lastWave1Time = iTime(_Symbol, TimeframeMonitor, 0);
         g_wave2Confirmed = false;
         g_waitingForWave3Entry = false;
         g_pushLow = 0;

         reversalDetected = true;
      }
   }

   // 上昇 → 下降への転換
   if((g_currentTrendState == TREND_STATE_UPTREND ||
       g_currentTrendState == TREND_STATE_RANGE) &&
       g_pushLow > 0) {

      if(currentClose < g_pushLow) {
         double waveSize = g_pushLow - currentClose;

         if(waveSize < minWaveSize) {
            if(EnableDebugMode) {
               Print("⚠️ 波動が小さすぎる: ", waveSize/_Point, " points");
            }
            return false;
         }

         Print("🔄 トレンド転換: 上昇→下降");
         Print("   押し安値ブレイク: ", currentClose, " < ", g_pushLow);
         Print("   波動サイズ: ", waveSize/_Point/g_pointToPips, " pips");

         g_currentTrendState = TREND_STATE_DOWNTREND;
         g_wave1Confirmed = true;
         g_wave1StartPrice = g_pushLow;
         g_wave1EndPrice = currentClose;
         g_lastWave1Time = iTime(_Symbol, TimeframeMonitor, 0);
         g_wave2Confirmed = false;
         g_waitingForWave3Entry = false;
         g_pullbackHigh = 0;

         reversalDetected = true;
      }
   }

   return reversalDetected;
}

//+------------------------------------------------------------------+
//| 第2波リトレースメント検証関数（最適化版）                          |
//+------------------------------------------------------------------+
bool ValidateWave2Retracement() {
   if(!g_wave1Confirmed) {
      return false;
   }

   double currentPrice = iClose(_Symbol, TimeframeMonitor, 0);
   double wave1Range = MathAbs(g_wave1EndPrice - g_wave1StartPrice);
   double minWaveSize = MinWaveSizePips * 5 * _Point * g_pointToPips;  // 第1波は最小波動の5倍以上

   if(wave1Range < minWaveSize) {
      if(EnableDebugMode) {
         Print("⚠️ 第1波が小さすぎる: ", wave1Range/_Point/g_pointToPips, " pips");
      }
      return false;
   }

   // 上昇トレンドの第2波
   if(g_currentTrendState == TREND_STATE_UPTREND) {
      if(currentPrice >= g_wave1EndPrice) {
         return false;  // まだ調整していない
      }

      double retracement = g_wave1EndPrice - currentPrice;
      double retracementPercent = retracement / wave1Range;

      if(retracementPercent < Wave2RetracementMin) {
         return false;  // リトレースメント浅すぎ
      }

      if(retracementPercent > Wave2RetracementMax) {
         if(EnableDebugMode) {
            Print("⚠️ リトレースメント深すぎ: ", retracementPercent * 100, "%");
         }
         g_wave1Confirmed = false;
         return false;
      }

      Print("✅ 第2波確定: ", retracementPercent * 100, "% リトレースメント");
      g_wave2Confirmed = true;
      g_wave2EndPrice = currentPrice;
      g_lastWave2Time = iTime(_Symbol, TimeframeMonitor, 0);
      g_waitingForWave3Entry = true;

      return true;
   }

   // 下降トレンドの第2波
   if(g_currentTrendState == TREND_STATE_DOWNTREND) {
      if(currentPrice <= g_wave1EndPrice) {
         return false;  // まだ調整していない
      }

      double retracement = currentPrice - g_wave1EndPrice;
      double retracementPercent = retracement / wave1Range;

      if(retracementPercent < Wave2RetracementMin) {
         return false;  // リトレースメント浅すぎ
      }

      if(retracementPercent > Wave2RetracementMax) {
         if(EnableDebugMode) {
            Print("⚠️ リトレースメント深すぎ: ", retracementPercent * 100, "%");
         }
         g_wave1Confirmed = false;
         return false;
      }

      Print("✅ 第2波確定: ", retracementPercent * 100, "% リトレースメント");
      g_wave2Confirmed = true;
      g_wave2EndPrice = currentPrice;
      g_lastWave2Time = iTime(_Symbol, TimeframeMonitor, 0);
      g_waitingForWave3Entry = true;

      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| 第3波エントリー条件チェック（最適化版v2 - タイムフレーム整合性強化）|
//+------------------------------------------------------------------+
bool CheckWave3EntryConditions() {
   if(!g_waitingForWave3Entry || !g_wave1Confirmed || !g_wave2Confirmed) {
      return false;
   }

   // ★★★ 両方のタイムフレームの価格を取得 ★★★
   double monitorCurrentPrice = iClose(_Symbol, TimeframeMonitor, 0);
   double executeCurrentPrice = iClose(_Symbol, TimeframeExecute, 0);
   double executePreviousPrice = iClose(_Symbol, TimeframeExecute, 1);
   double executePrice2BarsAgo = iClose(_Symbol, TimeframeExecute, 2);

   // 上昇トレンドの第3波エントリー
   if(g_currentTrendState == TREND_STATE_UPTREND) {
      // ★ Monitor TFでも第2波を上回っていることを確認 ★
      bool monitorCondition = monitorCurrentPrice > g_wave2EndPrice;

      // Execute TFで連続上昇を確認
      bool executeCondition1 = executeCurrentPrice > g_wave2EndPrice;
      bool executeCondition2 = executeCurrentPrice > executePreviousPrice;
      bool executeCondition3 = executePreviousPrice > executePrice2BarsAgo;

      // ★ すべての条件を満たす必要がある ★
      if(monitorCondition && executeCondition1 && executeCondition2 && executeCondition3) {
         if(EnableDebugMode) {
            Print("✅✅✅ 第3波買いエントリー条件成立");
            Print("   [", EnumToString(TimeframeMonitor), "] 現在価格: ", monitorCurrentPrice,
                  " > 第2波終値: ", g_wave2EndPrice);
            Print("   [", EnumToString(TimeframeExecute), "] 2本前: ", executePrice2BarsAgo,
                  " → 前回: ", executePreviousPrice, " → 現在: ", executeCurrentPrice);
         }
         return true;
      }

      // デバッグ: 条件が満たされない理由を表示
      if(EnableDebugMode && (executeCondition1 && executeCondition2 && executeCondition3)) {
         if(!monitorCondition) {
            Print("⚠️ Monitor TFで第2波を下回っている: ", monitorCurrentPrice, " <= ", g_wave2EndPrice);
         }
      }
   }

   // 下降トレンドの第3波エントリー
   if(g_currentTrendState == TREND_STATE_DOWNTREND) {
      // ★ Monitor TFでも第2波を下回っていることを確認 ★
      bool monitorCondition = monitorCurrentPrice < g_wave2EndPrice;

      // Execute TFで連続下降を確認
      bool executeCondition1 = executeCurrentPrice < g_wave2EndPrice;
      bool executeCondition2 = executeCurrentPrice < executePreviousPrice;
      bool executeCondition3 = executePreviousPrice < executePrice2BarsAgo;

      // ★ すべての条件を満たす必要がある ★
      if(monitorCondition && executeCondition1 && executeCondition2 && executeCondition3) {
         if(EnableDebugMode) {
            Print("✅✅✅ 第3波売りエントリー条件成立");
            Print("   [", EnumToString(TimeframeMonitor), "] 現在価格: ", monitorCurrentPrice,
                  " < 第2波終値: ", g_wave2EndPrice);
            Print("   [", EnumToString(TimeframeExecute), "] 2本前: ", executePrice2BarsAgo,
                  " → 前回: ", executePreviousPrice, " → 現在: ", executeCurrentPrice);
         }
         return true;
      }

      // デバッグ: 条件が満たされない理由を表示
      if(EnableDebugMode && (executeCondition1 && executeCondition2 && executeCondition3)) {
         if(!monitorCondition) {
            Print("⚠️ Monitor TFで第2波を上回っている: ", monitorCurrentPrice, " >= ", g_wave2EndPrice);
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| 第3波エントリー実行関数（統一版）                                 |
//+------------------------------------------------------------------+
void ExecuteWave3Entry() {
   if(g_currentTrendState == TREND_STATE_UPTREND) {
      ExecuteBuyOrder();
   } else if(g_currentTrendState == TREND_STATE_DOWNTREND) {
      ExecuteSellOrder();
   }

   if(trade.ResultRetcode() == TRADE_RETCODE_DONE) {
      g_waitingForWave3Entry = false;
      g_lastEntryTime = TimeCurrent();
      Print("✅ 第3波エントリー成功: Ticket=", trade.ResultOrder());
   }
}

//+------------------------------------------------------------------+
//| 買い注文実行関数（最適化版・修正）                                |
//+------------------------------------------------------------------+
void ExecuteBuyOrder() {
   // 現在価格を取得
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // SL計算（第2波終値の少し下）
   double slDistance = MinSLPips * _Point * g_pointToPips;
   double sl = g_wave2EndPrice - slDistance;

   // SL距離のチェックと調整
   double actualSLDistance = ask - sl;
   double maxSLDistance = MaxSLPips * _Point * g_pointToPips;
   double minDistance = MinSLPips * _Point * g_pointToPips;

   if(actualSLDistance > maxSLDistance) {
      sl = ask - maxSLDistance;
      if(EnableDebugMode) {
         Print("⚠️ SL距離を最大値に調整: ", maxSLDistance/_Point/g_pointToPips, " pips");
      }
   }
   else if(actualSLDistance < minDistance) {
      sl = ask - minDistance;
      if(EnableDebugMode) {
         Print("⚠️ SL距離を最小値に調整: ", minDistance/_Point/g_pointToPips, " pips");
      }
   }

   // ★★★ 重要：SL調整後に距離を再計算 ★★★
   actualSLDistance = ask - sl;

   // TP計算（調整後のSL距離を使用）
   double tpDistance = actualSLDistance * RiskRewardRatio;
   double tp = ask + tpDistance;

   // 最小TP距離の確保
   double minTPDistance = MinTPPips * _Point * g_pointToPips;
   if(tpDistance < minTPDistance) {
      tp = ask + minTPDistance;
      tpDistance = minTPDistance;
      if(EnableDebugMode) {
         Print("⚠️ TP距離を最小値に調整: ", minTPDistance/_Point/g_pointToPips, " pips");
      }
   }

   // 正規化
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   sl = NormalizeDouble(sl, digits);
   tp = NormalizeDouble(tp, digits);

   // ★★★ 修正：正規化後の実際の距離で計算 ★★★
   double slPips = (ask - sl) / _Point / g_pointToPips;
   double tpPips = (tp - ask) / _Point / g_pointToPips;
   double lots = CalculateLotSize(RiskPercentAligned, slPips);

   if(lots <= 0) {
      Print("❌ ロットサイズ計算エラー");
      return;
   }

   // 最終検証
   if(!ValidateOrderParameters(ORDER_TYPE_BUY, ask, sl, tp)) {
      Print("❌ 注文パラメータ検証失敗");
      return;
   }

   // 注文実行
   if(EnableDebugMode) {
      Print("=== 買い注文実行 ===");
      Print("  Ask: ", ask);
      Print("  SL: ", sl, " (距離: ", slPips, " pips)");
      Print("  TP: ", tp, " (距離: ", tpPips, " pips)");
      Print("  R:R比率: 1:", DoubleToString(tpPips/slPips, 2));
      Print("  Lot: ", lots);
   }

   bool result = trade.Buy(lots, _Symbol, 0, sl, tp, "Elliott Wave 3");

   if(result && trade.ResultRetcode() == TRADE_RETCODE_DONE) {
      Print("✅ 買い注文成功: Ticket=", trade.ResultOrder());
   }
   else {
      Print("❌ 買い注文失敗: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| 売り注文実行関数（最適化版・修正）                                |
//+------------------------------------------------------------------+
void ExecuteSellOrder() {
   // 現在価格を取得
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // SL計算（第2波終値の少し上）
   double slDistance = MinSLPips * _Point * g_pointToPips;
   double sl = g_wave2EndPrice + slDistance;

   // SL距離のチェックと調整
   double actualSLDistance = sl - bid;
   double maxSLDistance = MaxSLPips * _Point * g_pointToPips;
   double minDistance = MinSLPips * _Point * g_pointToPips;

   if(actualSLDistance > maxSLDistance) {
      sl = bid + maxSLDistance;
      if(EnableDebugMode) {
         Print("⚠️ SL距離を最大値に調整: ", maxSLDistance/_Point/g_pointToPips, " pips");
      }
   }
   else if(actualSLDistance < minDistance) {
      sl = bid + minDistance;
      if(EnableDebugMode) {
         Print("⚠️ SL距離を最小値に調整: ", minDistance/_Point/g_pointToPips, " pips");
      }
   }

   // ★★★ 重要：SL調整後に距離を再計算 ★★★
   actualSLDistance = sl - bid;

   // TP計算（調整後のSL距離を使用）
   double tpDistance = actualSLDistance * RiskRewardRatio;
   double tp = bid - tpDistance;

   // 最小TP距離の確保
   double minTPDistance = MinTPPips * _Point * g_pointToPips;
   if(tpDistance < minTPDistance) {
      tp = bid - minTPDistance;
      tpDistance = minTPDistance;
      if(EnableDebugMode) {
         Print("⚠️ TP距離を最小値に調整: ", minTPDistance/_Point/g_pointToPips, " pips");
      }
   }

   // 正規化
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   sl = NormalizeDouble(sl, digits);
   tp = NormalizeDouble(tp, digits);

   // ★★★ 修正：正規化後の実際の距離で計算 ★★★
   double slPips = (sl - bid) / _Point / g_pointToPips;
   double tpPips = (bid - tp) / _Point / g_pointToPips;
   double lots = CalculateLotSize(RiskPercentAligned, slPips);

   if(lots <= 0) {
      Print("❌ ロットサイズ計算エラー");
      return;
   }

   // 最終検証
   if(!ValidateOrderParameters(ORDER_TYPE_SELL, bid, sl, tp)) {
      Print("❌ 注文パラメータ検証失敗");
      return;
   }

   // 注文実行
   if(EnableDebugMode) {
      Print("=== 売り注文実行 ===");
      Print("  Bid: ", bid);
      Print("  SL: ", sl, " (距離: ", slPips, " pips)");
      Print("  TP: ", tp, " (距離: ", tpPips, " pips)");
      Print("  R:R比率: 1:", DoubleToString(tpPips/slPips, 2));
      Print("  Lot: ", lots);
   }

   bool result = trade.Sell(lots, _Symbol, 0, sl, tp, "Elliott Wave 3");

   if(result && trade.ResultRetcode() == TRADE_RETCODE_DONE) {
      Print("✅ 売り注文成功: Ticket=", trade.ResultOrder());
   }
   else {
      Print("❌ 売り注文失敗: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| 注文パラメータ検証関数（簡素化版）                                |
//+------------------------------------------------------------------+
bool ValidateOrderParameters(ENUM_ORDER_TYPE orderType, double entryPrice,
                             double sl, double tp) {
   // ストップレベルの取得
   int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = stopLevel * _Point;

   // 買い注文の検証
   if(orderType == ORDER_TYPE_BUY) {
      if(sl >= entryPrice) {
         Print("❌ 買い注文: SLがEntry以上");
         return false;
      }
      if(tp <= entryPrice) {
         Print("❌ 買い注文: TPがEntry以下");
         return false;
      }
      if((entryPrice - sl) < minDistance) {
         Print("❌ 買い注文: SL距離が不足");
         return false;
      }
      if((tp - entryPrice) < minDistance) {
         Print("❌ 買い注文: TP距離が不足");
         return false;
      }
   }

   // 売り注文の検証
   if(orderType == ORDER_TYPE_SELL) {
      if(sl <= entryPrice) {
         Print("❌ 売り注文: SLがEntry以下");
         return false;
      }
      if(tp >= entryPrice) {
         Print("❌ 売り注文: TPがEntry以上");
         return false;
      }
      if((sl - entryPrice) < minDistance) {
         Print("❌ 売り注文: SL距離が不足");
         return false;
      }
      if((entryPrice - tp) < minDistance) {
         Print("❌ 売り注文: TP距離が不足");
         return false;
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| ロットサイズ計算関数（最適化版）                                  |
//+------------------------------------------------------------------+
double CalculateLotSize(double riskPercent, double slPips) {
   // アカウント情報
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * riskPercent / 100.0;

   // シンボル情報
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   // ポイント価値の計算
   double pointValue = tickValue * (_Point / tickSize);

   // SL距離（ポイント）
   double slPoints = slPips * g_pointToPips;

   if(slPoints <= 0) {
      Print("❌ 無効なSL距離: ", slPoints);
      return 0;
   }

   // ロットサイズ計算
   double lotSize = riskAmount / (slPoints * pointValue);

   // 正規化
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));

   // 証拠金チェック
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double requiredMargin = lotSize * 100000 * 0.04;  // レバレッジ25倍想定

   if(requiredMargin > freeMargin * 0.5) {
      lotSize = (freeMargin * 0.5) / (100000 * 0.04);
      lotSize = MathFloor(lotSize / lotStep) * lotStep;
      lotSize = MathMax(minLot, lotSize);
      if(EnableDebugMode) {
         Print("⚠️ 証拠金制限によりロット調整: ", lotSize);
      }
   }

   if(lotSize < minLot) {
      Print("❌ ロットサイズが最小値未満: ", lotSize);
      return 0;
   }

   return lotSize;
}

//+------------------------------------------------------------------+
//| 新規ポジション可否チェック関数                                    |
//+------------------------------------------------------------------+
bool CanOpenNewPosition() {
   int openPositions = 0;

   for(int i = 0; i < PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i))) {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == EA_MAGIC_NUMBER) {  // ★ 定数使用
            openPositions++;
         }
      }
   }

   if(openPositions >= MaxOpenPositions) {
      if(EnableDebugMode) {
         Print("⚠️ 最大ポジション数に到達: ", openPositions);
      }
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| トレーリングストップ管理関数                                      |
//+------------------------------------------------------------------+
void ManageTrailingStop() {
   double trailingActivation = TrailingActivationPips * _Point * g_pointToPips;
   double trailingDistance = TrailingDistancePips * _Point * g_pointToPips;

   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != EA_MAGIC_NUMBER) continue;  // ★ 定数使用

      double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double positionSL = PositionGetDouble(POSITION_SL);
      ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

      if(positionType == POSITION_TYPE_BUY) {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double profit = bid - positionOpenPrice;

         if(profit >= trailingActivation) {
            double newSL = bid - trailingDistance;
            newSL = NormalizeDouble(newSL, digits);

            if(newSL > positionSL) {
               trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
               if(EnableDebugMode) {
                  Print("📈 トレーリングストップ更新(買い): ", positionSL, " → ", newSL);
               }
            }
         }
      }
      else if(positionType == POSITION_TYPE_SELL) {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double profit = positionOpenPrice - ask;

         if(profit >= trailingActivation) {
            double newSL = ask + trailingDistance;
            newSL = NormalizeDouble(newSL, digits);

            if(newSL < positionSL || positionSL == 0) {
               trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
               if(EnableDebugMode) {
                  Print("📉 トレーリングストップ更新(売り): ", positionSL, " → ", newSL);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert終了関数                                                    |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   // インジケータハンドル解放
   if(g_emaFastHandle != INVALID_HANDLE) {
      IndicatorRelease(g_emaFastHandle);
   }
   if(g_emaSlowHandle != INVALID_HANDLE) {
      IndicatorRelease(g_emaSlowHandle);
   }

   Print("Elliott Wave EA v2.0 終了");
}

//+------------------------------------------------------------------+

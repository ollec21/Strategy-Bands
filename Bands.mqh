//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of Bands Strategy based on the Bollinger Bands indicator.
 *
 * @docs
 * - https://docs.mql4.com/indicators/iBands
 * - https://www.mql5.com/en/docs/indicators/iBands
 */

// Includes.
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

// User inputs.
#ifdef __input__ input #endif string __Bands_Parameters__ = "-- Settings for the Bollinger Bands indicator --"; // >>> BANDS <<<
#ifdef __input__ input #endif int Bands_Period = 16; // Period
#ifdef __input__ input #endif double Bands_Period_Ratio = 1.0; // Period ratio between timeframes (0.5-1.5)
#ifdef __input__ input #endif ENUM_APPLIED_PRICE Bands_Applied_Price = 4; // Applied Price
#ifdef __input__ input #endif double Bands_Deviation = 4.10000000; // Deviation
#ifdef __input__ input #endif double Bands_Deviation_Ratio = 1.0; // Deviation ratio between timeframes (0.5-1.5)
#ifdef __input__ input #endif int Bands_Shift = 0; // Shift
#ifdef __input__ input #endif int Bands_Shift_Far = 0; // Shift Far
// @todo #ifdef __input__ input #endif int Bands_SignalLevel = 0; // Signal level
#ifdef __input__ input #endif int Bands_SignalMethod = 0; // Signal method (-127-127)
#ifdef __input__ input #endif string Bands_SignalMethods = 0; // Signal methods (-127-127)

class Bands: public Strategy {

protected:

  double bands[H1][FINAL_ENUM_INDICATOR_INDEX][FINAL_BANDS_ENTRY];
  int       open_method = EMPTY;    // Open method.
  double    open_level  = 0.0;     // Open level.

public:

  /**
   * Update indicator values.
   */
  bool Update(int tf = EMPTY) {
    // Calculates the Bollinger Bands indicator.
    // int sid, bands_period = Bands_Period; // Not used at the moment.
    // sid = GetStrategyViaIndicator(BANDS, tf); bands_period = info[sid][CUSTOM_PERIOD]; // Not used at the moment.
    ratio = tf == 30 ? 1.0 : fmax(Bands_Period_Ratio, NEAR_ZERO) / tf * 30;
    ratio2 = tf == 30 ? 1.0 : fmax(Bands_Deviation_Ratio, NEAR_ZERO) / tf * 30;
    for (i = 0; i < FINAL_ENUM_INDICATOR_INDEX; i++) {
      shift = i + Bands_Shift + (i == FINAL_ENUM_INDICATOR_INDEX - 1 ? Bands_Shift_Far : 0);
      bands[index][i][BANDS_BASE]  = iBands(symbol, tf, (int) (Bands_Period * ratio), Bands_Deviation * ratio2, 0, Bands_Applied_Price, BANDS_BASE,  shift);
      bands[index][i][BANDS_UPPER] = iBands(symbol, tf, (int) (Bands_Period * ratio), Bands_Deviation * ratio2, 0, Bands_Applied_Price, BANDS_UPPER, shift);
      bands[index][i][BANDS_LOWER] = iBands(symbol, tf, (int) (Bands_Period * ratio), Bands_Deviation * ratio2, 0, Bands_Applied_Price, BANDS_LOWER, shift);
    }
    success = (bool)bands[index][CURR][BANDS_BASE];
    if (VerboseDebug) PrintFormat("Bands M%d: %s", tf, Arrays::ArrToString3D(bands, ",", Digits));
  }

  /**
   * Checks whether signal is on buy or sell.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal
   */
  bool Signal(int cmd, ENUM_TIMEFRAMES tf = PERIOD_M1, int signal_method = EMPTY, double signal_level = EMPTY) {
    bool result = FALSE; int period = Timeframe::TfToIndex(tf);
    UpdateIndicator(S_BANDS, tf);
    if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_BANDS, tf, 0);
    if (signal_level  == EMPTY) signal_level  = GetStrategySignalLevel(S_BANDS, tf, 0);
    double lowest = fmin(Low[CURR], fmin(Low[PREV], Low[FAR]));
    double highest = fmax(High[CURR], fmax(High[PREV], High[FAR]));
    switch (cmd) {
      case OP_BUY:
        // Price value was lower than the lower band.
        result = (
            lowest < fmax(fmax(bands[period][CURR][BANDS_LOWER], bands[period][PREV][BANDS_LOWER]), bands[period][FAR][BANDS_LOWER])
            );
        // Buy: price crossed lower line upwards (returned to it from below).
        if ((signal_method &   1) != 0) result &= fmin(Close[PREV], Close[FAR]) < bands[period][CURR][BANDS_LOWER];
        if ((signal_method &   2) != 0) result &= (bands[period][CURR][BANDS_LOWER] > bands[period][FAR][BANDS_LOWER]);
        if ((signal_method &   4) != 0) result &= (bands[period][CURR][BANDS_BASE] > bands[period][FAR][BANDS_BASE]);
        if ((signal_method &   8) != 0) result &= (bands[period][CURR][BANDS_UPPER] > bands[period][FAR][BANDS_UPPER]);
        if ((signal_method &  16) != 0) result &= highest > bands[period][CURR][BANDS_BASE];
        if ((signal_method &  32) != 0) result &= Open[CURR] < bands[period][CURR][BANDS_BASE];
        if ((signal_method &  64) != 0) result &= fmin(Close[PREV], Close[FAR]) > bands[period][CURR][BANDS_BASE];
        // if ((signal_method & 128) != 0) result &= !Trade_Bands(Convert::NegateOrderType(cmd), (ENUM_TIMEFRAMES) Convert::IndexToTf(fmin(period + 1, M30)));
      case OP_SELL:
        // Price value was higher than the upper band.
        result = (
            highest > fmin(fmin(bands[period][CURR][BANDS_UPPER], bands[period][PREV][BANDS_UPPER]), bands[period][FAR][BANDS_UPPER])
            );
        // Sell: price crossed upper line downwards (returned to it from above).
        if ((signal_method &   1) != 0) result &= fmin(Close[PREV], Close[FAR]) > bands[period][CURR][BANDS_UPPER];
        if ((signal_method &   2) != 0) result &= (bands[period][CURR][BANDS_LOWER] < bands[period][FAR][BANDS_LOWER]);
        if ((signal_method &   4) != 0) result &= (bands[period][CURR][BANDS_BASE] < bands[period][FAR][BANDS_BASE]);
        if ((signal_method &   8) != 0) result &= (bands[period][CURR][BANDS_UPPER] < bands[period][FAR][BANDS_UPPER]);
        if ((signal_method &  16) != 0) result &= lowest < bands[period][CURR][BANDS_BASE];
        if ((signal_method &  32) != 0) result &= Open[CURR] > bands[period][CURR][BANDS_BASE];
        if ((signal_method &  64) != 0) result &= fmin(Close[PREV], Close[FAR]) < bands[period][CURR][BANDS_BASE];
        // if ((signal_method & 128) != 0) result &= !Trade_Bands(Convert::NegateOrderType(cmd), (ENUM_TIMEFRAMES) Convert::IndexToTf(fmin(period + 1, M30)));
        break;
    }
    result &= signal_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    if (VerboseTrace && result) {
      PrintFormat("%s:%d: Signal: %d/%d/%d/%g", __FUNCTION__, __LINE__, cmd, tf, signal_method, signal_level);
    }
    return result;
  }

};

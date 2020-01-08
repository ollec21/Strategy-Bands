//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements Bands strategy based on the Bollinger Bands indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_Bands.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __Bands_Parameters__ = "-- Bands strategy params --";  // >>> BANDS <<<
INPUT int Bands_Active_Tf = 127;  // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32,H4=64...)
INPUT int Bands_Period = 2;       // Period for M1
INPUT ENUM_APPLIED_PRICE Bands_Applied_Price = PRICE_CLOSE;  // Applied Price
INPUT double Bands_Deviation = 0.3;                          // Deviation
INPUT int Bands_HShift = 0;                                  // Horizontal shift
INPUT int Bands_Shift = 0;                                   // Shift (relative to the current bar, 0 - default)
INPUT ENUM_TRAIL_TYPE Bands_TrailingStopMethod = 7;          // Trail stop method
INPUT ENUM_TRAIL_TYPE Bands_TrailingProfitMethod = 22;       // Trail profit method
INPUT int Bands_SignalOpenLevel = 18;                        // Signal open level
INPUT int Bands_SignalBaseMethod = -85;                      // Signal method (-127-127)
INPUT int Bands_SignalOpenMethod1 = 971;                     // Open condition 1 (0-1023)
INPUT int Bands_SignalOpenMethod2 = 0;                       // Open condition 2 (0-1023)
INPUT int Bands_SignalCloseLevel = 0;                        // Signal close level
INPUT ENUM_MARKET_EVENT Bands_SignalCloseMethod1 = 24;       // Close condition
INPUT ENUM_MARKET_EVENT Bands_SignalCloseMethod2 = 0;        // Close condition
INPUT double Bands_MaxSpread = 0;                            // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_Bands_Params : Stg_Params {
  unsigned int Bands_Period;
  double Bands_Deviation;
  int Bands_HShift;
  ENUM_APPLIED_PRICE Bands_Applied_Price;
  int Bands_Shift;
  ENUM_TRAIL_TYPE Bands_TrailingStopMethod;
  ENUM_TRAIL_TYPE Bands_TrailingProfitMethod;
  double Bands_SignalOpenLevel;
  long Bands_SignalBaseMethod;
  long Bands_SignalOpenMethod1;
  long Bands_SignalOpenMethod2;
  double Bands_SignalCloseLevel;
  ENUM_MARKET_EVENT Bands_SignalCloseMethod1;
  ENUM_MARKET_EVENT Bands_SignalCloseMethod2;
  double Bands_MaxSpread;

  // Constructor: Set default param values.
  Stg_Bands_Params()
      : Bands_Period(::Bands_Period),
        Bands_Deviation(::Bands_Deviation),
        Bands_HShift(::Bands_HShift),
        Bands_Applied_Price(::Bands_Applied_Price),
        Bands_Shift(::Bands_Shift),
        Bands_TrailingStopMethod(::Bands_TrailingStopMethod),
        Bands_TrailingProfitMethod(::Bands_TrailingProfitMethod),
        Bands_SignalOpenLevel(::Bands_SignalOpenLevel),
        Bands_SignalBaseMethod(::Bands_SignalBaseMethod),
        Bands_SignalOpenMethod1(::Bands_SignalOpenMethod1),
        Bands_SignalOpenMethod2(::Bands_SignalOpenMethod2),
        Bands_SignalCloseLevel(::Bands_SignalCloseLevel),
        Bands_SignalCloseMethod1(::Bands_SignalCloseMethod1),
        Bands_SignalCloseMethod2(::Bands_SignalCloseMethod2),
        Bands_MaxSpread(::Bands_MaxSpread) {}
  void Init() {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_Bands : public Strategy {
 public:
  Stg_Bands(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Bands *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_Bands_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_Bands_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_Bands_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_Bands_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_Bands_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_Bands_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_Bands_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    Bands_Params bands_params(_params.Bands_Period, _params.Bands_Deviation, Bands_HShift, Bands_Applied_Price);
    IndicatorParams bands_iparams(10, INDI_BANDS);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_Bands(bands_params, bands_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Bands_SignalBaseMethod, _params.Bands_SignalOpenMethod1, _params.Bands_SignalOpenMethod2,
                       _params.Bands_SignalCloseMethod1, _params.Bands_SignalCloseMethod2,
                       _params.Bands_SignalOpenLevel, _params.Bands_SignalCloseLevel);
    sparams.SetStops(_params.Bands_TrailingProfitMethod, _params.Bands_TrailingStopMethod);
    sparams.SetMaxSpread(_params.Bands_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Bands(sparams, "Bands");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double bands_0_base = ((Indi_Bands *)this.Data()).GetValue(BAND_BASE, 0);
    double bands_0_lower = ((Indi_Bands *)this.Data()).GetValue(BAND_LOWER, 0);
    double bands_0_upper = ((Indi_Bands *)this.Data()).GetValue(BAND_UPPER, 0);
    double bands_1_base = ((Indi_Bands *)this.Data()).GetValue(BAND_BASE, 1);
    double bands_1_lower = ((Indi_Bands *)this.Data()).GetValue(BAND_LOWER, 1);
    double bands_1_upper = ((Indi_Bands *)this.Data()).GetValue(BAND_UPPER, 1);
    double bands_2_base = ((Indi_Bands *)this.Data()).GetValue(BAND_BASE, 2);
    double bands_2_lower = ((Indi_Bands *)this.Data()).GetValue(BAND_LOWER, 2);
    double bands_2_upper = ((Indi_Bands *)this.Data()).GetValue(BAND_UPPER, 2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level == EMPTY) _signal_level = GetSignalOpenLevel();
    double lowest = fmin(Low[CURR], fmin(Low[PREV], Low[FAR]));
    double highest = fmax(High[CURR], fmax(High[PREV], High[FAR]));
    double level = _signal_level * Chart().GetPipSize();
    switch (_cmd) {
      // Buy: price crossed lower line upwards (returned to it from below).
      case ORDER_TYPE_BUY:
        // Price value was lower than the lower band.
        _result = (lowest > 0 && lowest < fmax(fmax(bands_0_lower, bands_1_lower), bands_2_lower)) - level;
        if (_signal_method != 0) {
          if (METHOD(_signal_method, 0)) _result &= fmin(Close[PREV], Close[FAR]) < bands_0_lower;
          if (METHOD(_signal_method, 1)) _result &= (bands_0_lower > bands_2_lower);
          if (METHOD(_signal_method, 2)) _result &= (bands_0_base > bands_2_base);
          if (METHOD(_signal_method, 3)) _result &= (bands_0_upper > bands_2_upper);
          if (METHOD(_signal_method, 4)) _result &= highest > bands_0_base;
          if (METHOD(_signal_method, 5)) _result &= Open[CURR] < bands_0_base;
          if (METHOD(_signal_method, 6)) _result &= fmin(Close[PREV], Close[FAR]) > bands_0_base;
          // if (METHOD(_signal_method, 7)) _result &= !Trade_Bands(Convert::NegateOrderType(cmd), (ENUM_TIMEFRAMES)
          // Convert::IndexToTf(fmin(period + 1, M30)));
        }
        break;
      // Sell: price crossed upper line downwards (returned to it from above).
      case ORDER_TYPE_SELL:
        // Price value was higher than the upper band.
        _result = (lowest > 0 && highest > fmin(fmin(bands_0_upper, bands_1_upper), bands_2_upper)) + level;
        if (_signal_method != 0) {
          if (METHOD(_signal_method, 0)) _result &= fmin(Close[PREV], Close[FAR]) > bands_0_upper;
          if (METHOD(_signal_method, 1)) _result &= (bands_0_lower < bands_2_lower);
          if (METHOD(_signal_method, 2)) _result &= (bands_0_base < bands_2_base);
          if (METHOD(_signal_method, 3)) _result &= (bands_0_upper < bands_2_upper);
          if (METHOD(_signal_method, 4)) _result &= lowest < bands_0_base;
          if (METHOD(_signal_method, 5)) _result &= Open[CURR] > bands_0_base;
          if (METHOD(_signal_method, 6)) _result &= fmin(Close[PREV], Close[FAR]) < bands_0_base;
          // if (METHOD(_signal_method, 7)) _result &= !Trade_Bands(Convert::NegateOrderType(cmd), (ENUM_TIMEFRAMES)
          // Convert::IndexToTf(fmin(period + 1, M30)));
        }
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};

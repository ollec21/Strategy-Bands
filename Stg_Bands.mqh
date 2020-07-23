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
INPUT int Bands_Period = 2;                                         // Period
INPUT ENUM_APPLIED_PRICE Bands_Applied_Price = PRICE_CLOSE;         // Applied Price
INPUT double Bands_Deviation = 0.3;                                 // Deviation
INPUT int Bands_HShift = 0;                                         // Horizontal shift
INPUT int Bands_Shift = 0;                                          // Shift (relative to the current bar, 0 - default)
INPUT int Bands_SignalOpenMethod = 0;                               // Signal open method (-63-63)
INPUT double Bands_SignalOpenLevel = 18;                            // Signal open level (-49-49)
INPUT int Bands_SignalOpenFilterMethod = 18;                        // Signal open filter method (-49-49)
INPUT int Bands_SignalOpenBoostMethod = 18;                         // Signal open boost method (-49-49)
INPUT int Bands_SignalCloseMethod = 0;                              // Signal close method (-63-63)
INPUT double Bands_SignalCloseLevel = 18;                           // Signal close level (-49-49)
INPUT int Bands_PriceLimitMethod = 0;                               // Price limit method (0-6)
INPUT double Bands_PriceLimitLevel = 10;                            // Price limit level
INPUT double Bands_MaxSpread = 0;                                   // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_Bands_Params : StgParams {
  unsigned int Bands_Period;
  double Bands_Deviation;
  int Bands_HShift;
  ENUM_APPLIED_PRICE Bands_Applied_Price;
  int Bands_Shift;
  int Bands_SignalOpenMethod;
  double Bands_SignalOpenLevel;
  int Bands_SignalOpenFilterMethod;
  int Bands_SignalOpenBoostMethod;
  int Bands_SignalCloseMethod;
  double Bands_SignalCloseLevel;
  int Bands_PriceLimitMethod;
  double Bands_PriceLimitLevel;
  double Bands_MaxSpread;

  // Constructor: Set default param values.
  Stg_Bands_Params()
      : Bands_Period(::Bands_Period),
        Bands_Deviation(::Bands_Deviation),
        Bands_HShift(::Bands_HShift),
        Bands_Applied_Price(::Bands_Applied_Price),
        Bands_Shift(::Bands_Shift),
        Bands_SignalOpenMethod(::Bands_SignalOpenMethod),
        Bands_SignalOpenLevel(::Bands_SignalOpenLevel),
        Bands_SignalOpenFilterMethod(::Bands_SignalOpenFilterMethod),
        Bands_SignalOpenBoostMethod(::Bands_SignalOpenBoostMethod),
        Bands_SignalCloseMethod(::Bands_SignalCloseMethod),
        Bands_SignalCloseLevel(::Bands_SignalCloseLevel),
        Bands_PriceLimitMethod(::Bands_PriceLimitMethod),
        Bands_PriceLimitLevel(::Bands_PriceLimitLevel),
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
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_Bands_Params>(_params, _tf, stg_bands_m1, stg_bands_m5, stg_bands_m15, stg_bands_m30,
                                      stg_bands_h1, stg_bands_h4, stg_bands_h4);
    }
    // Initialize strategy parameters.
    BandsParams bands_params(_params.Bands_Period, _params.Bands_Deviation, Bands_HShift, Bands_Applied_Price);
    bands_params.SetTf(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_Bands(bands_params), NULL, NULL);
    sparams.logger.Ptr().SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Bands_SignalOpenMethod, _params.Bands_SignalOpenLevel,
                       _params.Bands_SignalOpenFilterMethod, _params.Bands_SignalOpenBoostMethod,
                       _params.Bands_SignalCloseMethod, _params.Bands_SignalCloseLevel);
    sparams.SetPriceLimits(_params.Bands_PriceLimitMethod, _params.Bands_PriceLimitLevel);
    sparams.SetMaxSpread(_params.Bands_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Bands(sparams, "Bands");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    Chart *_chart = Chart();
    Indi_Bands *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    double level = _level * Chart().GetPipSize();
    switch (_cmd) {
      // Buy: price crossed lower line upwards (returned to it from below).
      case ORDER_TYPE_BUY: {
        // Price value was lower than the lower band.
        double lowest_price = fmin(_chart.GetLow(CURR), fmin(_chart.GetLow(PREV), _chart.GetLow(PPREV)));
        _result = (lowest_price < fmax(fmax(_indi[CURR].value[BAND_LOWER], _indi[PREV].value[BAND_LOWER]), _indi[PPREV].value[BAND_LOWER])) - level;
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= fmin(Close[PREV], Close[PPREV]) < _indi[CURR].value[BAND_LOWER];
          if (METHOD(_method, 1)) _result &= (_indi[CURR].value[BAND_LOWER] > _indi[PPREV].value[BAND_LOWER]);
          if (METHOD(_method, 2)) _result &= (_indi[CURR].value[BAND_BASE] > _indi[PPREV].value[BAND_BASE]);
          if (METHOD(_method, 3)) _result &= (_indi[CURR].value[BAND_UPPER] > _indi[PPREV].value[BAND_UPPER]);
          if (METHOD(_method, 4)) _result &= lowest_price < _indi[CURR].value[BAND_BASE];
          if (METHOD(_method, 5)) _result &= Open[CURR] < _indi[CURR].value[BAND_BASE];
          if (METHOD(_method, 6)) _result &= fmin(Close[PREV], Close[PPREV]) > _indi[CURR].value[BAND_BASE];
        }
        break;
      }
      // Sell: price crossed upper line downwards (returned to it from above).
      case ORDER_TYPE_SELL: {
        // Price value was higher than the upper band.
        double highest_price = fmin(_chart.GetHigh(CURR), fmin(_chart.GetHigh(PREV), _chart.GetHigh(PPREV)));
        _result = (highest_price > fmin(fmin(_indi[CURR].value[BAND_UPPER], _indi[PREV].value[BAND_UPPER]), _indi[PPREV].value[BAND_UPPER])) + level;
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= fmin(Close[PREV], Close[PPREV]) > _indi[CURR].value[BAND_UPPER];
          if (METHOD(_method, 1)) _result &= (_indi[CURR].value[BAND_LOWER] < _indi[PPREV].value[BAND_LOWER]);
          if (METHOD(_method, 2)) _result &= (_indi[CURR].value[BAND_BASE] < _indi[PPREV].value[BAND_BASE]);
          if (METHOD(_method, 3)) _result &= (_indi[CURR].value[BAND_UPPER] < _indi[PPREV].value[BAND_UPPER]);
          if (METHOD(_method, 4)) _result &= highest_price > _indi[CURR].value[BAND_BASE];
          if (METHOD(_method, 5)) _result &= Open[CURR] > _indi[CURR].value[BAND_BASE];
          if (METHOD(_method, 6)) _result &= fmin(Close[PREV], Close[PPREV]) < _indi[CURR].value[BAND_BASE];
        }
        break;
      }
    }
    return _result;
  }

  /**
   * Check strategy's opening signal additional filter.
   */
  bool SignalOpenFilter(ENUM_ORDER_TYPE _cmd, int _method = 0) {
    bool _result = true;
    if (_method != 0) {
      // if (METHOD(_method, 0)) _result &= Trade().IsTrend(_cmd);
      // if (METHOD(_method, 1)) _result &= Trade().IsPivot(_cmd);
      // if (METHOD(_method, 2)) _result &= Trade().IsPeakHours(_cmd);
      // if (METHOD(_method, 3)) _result &= Trade().IsRoundNumber(_cmd);
      // if (METHOD(_method, 4)) _result &= Trade().IsHedging(_cmd);
      // if (METHOD(_method, 5)) _result &= Trade().IsPeakBar(_cmd);
    }
    return _result;
  }

  /**
   * Gets strategy's lot size boost (when enabled).
   */
  double SignalOpenBoost(ENUM_ORDER_TYPE _cmd, int _method = 0) {
    bool _result = 1.0;
    if (_method != 0) {
      // if (METHOD(_method, 0)) if (Trade().IsTrend(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 1)) if (Trade().IsPivot(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 2)) if (Trade().IsPeakHours(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 3)) if (Trade().IsRoundNumber(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 4)) if (Trade().IsHedging(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 5)) if (Trade().IsPeakBar(_cmd)) _result *= 1.1;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    return SignalOpen(Order::NegateOrderType(_cmd), _method, _level);
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  double PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, double _level = 0.0) {
    Indi_Bands *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _direction;
    double _result = _default_value;
    switch (_method) {
      case 0:
        _result = (_direction > 0 ? _indi[CURR].value[BAND_UPPER] : _indi[CURR].value[BAND_LOWER]) + _trail * _direction;
        break;
      case 1:
        _result = (_direction > 0 ? _indi[PREV].value[BAND_UPPER] : _indi[PREV].value[BAND_LOWER]) + _trail * _direction;
        break;
      case 2:
        _result = (_direction > 0 ? _indi[PPREV].value[BAND_UPPER] : _indi[PPREV].value[BAND_LOWER]) + _trail * _direction;
        break;
      case 3:
        _result = (_direction > 0 ? fmax(_indi[PREV].value[BAND_UPPER], _indi[PPREV].value[BAND_UPPER]) : fmin(_indi[PREV].value[BAND_LOWER], _indi[PPREV].value[BAND_LOWER])) +
                  _trail * _direction;
        break;
      case 4:
        _result = _indi[CURR].value[BAND_BASE] + _trail * _direction;
        break;
      case 5:
        _result = _indi[PREV].value[BAND_BASE] + _trail * _direction;
        break;
      case 6:
        _result = _indi[PPREV].value[BAND_BASE] + _trail * _direction;
        break;
      case 7: {
        int _bar_count = (int) _level * (int) _indi.GetPeriod();
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count)) : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
        break;
      }
    }
    return _result;
  }
};

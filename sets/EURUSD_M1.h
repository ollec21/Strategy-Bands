//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Bands_EURUSD_M1_Params : Stg_Bands_Params {
  Stg_Bands_EURUSD_M1_Params() {
    symbol = "EURUSD";
    tf = PERIOD_M1;
    Bands_Period = 2;
    Bands_Deviation = 0.3;
    Bands_HShift = 0;
    Bands_Applied_Price = PRICE_CLOSE;
    Bands_Shift = 0;
    Bands_TrailingStopMethod = 7;
    Bands_TrailingProfitMethod = 22;
    Bands_SignalOpenLevel = 18;
    Bands_SignalBaseMethod = -85;
    Bands_SignalOpenMethod1 = 971;
    Bands_SignalOpenMethod2 = 0;
    Bands_SignalCloseLevel = 0;
    Bands_SignalCloseMethod1 = 24;
    Bands_SignalCloseMethod2 = 0;
    Bands_MaxSpread = 2;
  }
};

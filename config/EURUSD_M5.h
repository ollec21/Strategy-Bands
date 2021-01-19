/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_Bands_Params_M5 : BandsParams {
  Indi_Bands_Params_M5() : BandsParams(indi_bands_defaults, PERIOD_M5) {
    applied_price = (ENUM_APPLIED_PRICE)5;
    deviation = 0.6;
    period = 16;
    bshift = 3;
    shift = 0;
  }
} indi_bands_m5;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Bands_Params_M5 : StgParams {
  // Struct constructor.
  Stg_Bands_Params_M5() : StgParams(stg_bands_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)0.0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)0;
    price_stop_method = 0;
    price_stop_level = (float)1;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_bands_m5;

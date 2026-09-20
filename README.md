# NEXUS Futures 4.0

Native Android foundation (no WebView) for a separate package `com.eezh.nexusfutures`.

Includes a native command centre, trade terminal, AI coach, strategy lab, risk/settings screens, Binance Futures public historical candle bootstrap, live kline WebSocket, EMA/RSI/ATR/market-structure/liquidity/FVG/confluence analysis, and paper-only safety mode.

Live exchange orders are deliberately disabled in this build. A production live layer still requires signed authentication, Android Keystore credential storage, exchange filters, idempotent order handling, partial-fill handling, reconciliation, rate-limit handling, network recovery and extensive paper/shadow testing.

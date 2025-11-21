# Triangular Arbitrage EA for BTC-ETH-USD
## Professional MT5 Expert Advisor for Cryptocurrency Triangular Arbitrage

---

## 📋 OVERVIEW

This Expert Advisor implements **triangular arbitrage** for the BTC/USD, ETH/USD, and BTC/ETH triangle on Deriv MT5 or any compatible MetaTrader 5 broker offering these cryptocurrency pairs.

### What is Triangular Arbitrage?

Triangular arbitrage exploits price discrepancies between three related trading pairs. The EA continuously monitors:
- **BTC/USD** (Bitcoin vs US Dollar)
- **ETH/USD** (Ethereum vs US Dollar)  
- **BTC/ETH** (Bitcoin vs Ethereum)

When prices diverge from their theoretical relationship, the EA can execute a profitable cycle.

### Two Paths:

**FORWARD PATH:** USD → BTC → ETH → USD
```
1. Buy BTC with USD
2. Convert BTC to ETH
3. Sell ETH for USD
Result: More USD than you started with
```

**REVERSE PATH:** USD → ETH → BTC → USD
```
1. Buy ETH with USD
2. Convert ETH to BTC
3. Sell BTC for USD
Result: More USD than you started with
```

---

## 🚀 INSTALLATION

### Step 1: Copy EA to MetaTrader 5

1. Open **MetaTrader 5**
2. Click **File** → **Open Data Folder**
3. Navigate to: `MQL5/Experts/`
4. Copy `TriangularArbitrage_BTC_ETH_USD.mq5` to this folder
5. Restart MT5 or press **F5** in MetaEditor to refresh

### Step 2: Compile (if needed)

1. Open **MetaEditor** (F4 in MT5)
2. Open the EA file
3. Click **Compile** (F7) or the compile button
4. Check for 0 errors in the compilation log

### Step 3: Add to Chart

1. Open any chart (BTCUSD recommended)
2. Navigate to **Navigator** → **Expert Advisors**
3. Drag `TriangularArbitrage_BTC_ETH_USD` onto the chart
4. Configure parameters (see below)
5. Click **OK**

---

## ⚙️ CONFIGURATION PARAMETERS

### Trading Pairs
```
Symbol 1: BTCUSD    - Bitcoin vs US Dollar
Symbol 2: ETHUSD    - Ethereum vs US Dollar
Symbol 3: BTCETH    - Bitcoin vs Ethereum (cross pair)
```
⚠️ **CRITICAL:** Verify these exact symbol names match your broker's naming convention!
- Some brokers use: `BTC/USD`, `BTCUSD`, `Bitcoin`, etc.
- Check in **Market Watch** for correct symbols

### Profit & Risk Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| **Minimum Profit %** | 0.5% | Minimum profit required after spreads to execute trade |
| **Max Slippage %** | 2.0% | Maximum acceptable slippage |
| **Lot Size** | 0.01 | Fixed lot size per trade |
| **Use % of Balance** | false | Enable to calculate lot size from balance |
| **Risk %** | 1.0% | Percentage of balance to risk (if enabled) |

**Recommendation:**
- Start with 0.5% minimum profit for testing
- Increase to 1.0%+ for live trading to account for execution delays
- Use 0.01 lots for initial testing

### Execution Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| **Magic Number** | 789456 | Unique identifier for EA trades |
| **Slippage Points** | 50 | Maximum slippage in points |
| **Check Interval Ms** | 500 | How often to scan for opportunities (milliseconds) |
| **Enable Live Trading** | true | Turn ON for real trades, OFF for monitoring |
| **Close Opposite Positions** | true | Close conflicting positions before new cycle |

**Recommendation:**
- Set to 100-500ms for optimal scanning speed
- Keep slippage at 50 points for crypto volatility
- Use **MONITORING MODE** (Enable Trading = false) first!

### Display & Monitoring

| Parameter | Default | Description |
|-----------|---------|-------------|
| **Show Panel** | true | Display information panel on chart |
| **Panel X/Y** | 20/30 | Panel position on chart |
| **Panel Color** | Dark Slate Gray | Background color |
| **Text Color** | White | Text color |

### Advanced Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| **Log Details** | true | Write detailed logs to Journal |
| **Max Daily Trades** | 200 | Daily trade limit (safety feature) |
| **Min Liquidity** | 0.0 | Minimum order book depth (0=disable) |

---

## 🧪 TESTING IN STRATEGY TESTER

### Step 1: Open Strategy Tester

1. Press **Ctrl+R** or click View → Strategy Tester
2. Select `TriangularArbitrage_BTC_ETH_USD` from Expert Advisor dropdown

### Step 2: Configure Test Settings

**Basic Settings:**
```
Symbol:          BTCUSD (or your main pair)
Period:          M5 or M15 (for faster testing)
Date Range:      Last 1-3 months recommended
Initial Deposit: $1,000 - $10,000
Leverage:        1:20 (crypto leverage on Deriv)
```

**Model:**
- **"Every tick based on real ticks"** (most accurate) - RECOMMENDED
- "1 minute OHLC" (faster, less accurate)
- "Open prices only" (fastest, least accurate)

### Step 3: Set EA Parameters

**For Testing:**
```
Enable Live Trading:    true
Minimum Profit %:       0.5% (lower for more trades)
Lot Size:              0.01
Check Interval Ms:     500
Show Panel:            false (disable for faster testing)
```

### Step 4: Run Test

1. Click **Start**
2. Monitor in **Journal** tab for opportunities found
3. Review results in **Results** and **Graph** tabs

### Expected Results:

**Good Test Results:**
- ✅ Win rate: 70-90%
- ✅ Profit factor: 1.5-3.0+
- ✅ Average profit per trade: 0.5-2%
- ✅ 10-50 trades per day

**Warning Signs:**
- ❌ Win rate < 50%
- ❌ Large drawdowns
- ❌ Very few opportunities
- ❌ Negative profit factor

---

## 📊 OPTIMIZATION GUIDE

### Parameters to Optimize

Use Strategy Tester's **Optimization** mode to find best settings:

1. **Minimum Profit %**
   - Range: 0.3 - 2.0
   - Step: 0.1
   - Goal: Find sweet spot between frequency and profitability

2. **Check Interval Ms**
   - Range: 100 - 1000
   - Step: 100
   - Goal: Balance speed vs CPU usage

3. **Lot Size**
   - Range: 0.01 - 0.10
   - Step: 0.01
   - Goal: Optimize position sizing

### Optimization Settings:

```
Optimization Mode:    Complete algorithm (thorough)
                     or Genetic algorithm (faster)
Criterion:           Custom (built into EA)
Forward Period:      1/3 (validate results)
```

---

## 🎯 LIVE TRADING CHECKLIST

### Before Going Live:

- [ ] **Test on DEMO account** for at least 1 week, [Create a DEMO account ](https://track.deriv.com/_vZspB8H3n2wpl7dR3lTXiGNd7ZgqdRLk/1/)
- [ ] **Verify symbol names** match your broker exactly
- [ ] **Check spreads** during your trading hours (should be reasonable)
- [ ] **Confirm all 3 pairs** are available and liquid
- [ ] **Set realistic profit threshold** (1.0%+ recommended)
- [ ] **Start with minimum lot size** (0.01)
- [ ] **Enable panel** to monitor performance
- [ ] **Have VPS ready** for 24/7 operation (optional but recommended)
- [ ] **Set appropriate daily trade limit**

### Recommended Live Settings:

```
Minimum Profit %:        1.0 - 1.5%  (higher for safety)
Lot Size:               0.01 - 0.05  (start small!)
Enable Live Trading:    true
Max Daily Trades:       50 - 100
Check Interval:         500 - 1000ms
Show Panel:             true
```

---

## ⚠️ CRITICAL WARNINGS & LIMITATIONS

### 1. **Speed is Everything**
- Arbitrage opportunities last **seconds**
- Without VPS or ultra-fast connection, you may miss trades
- Consider upgrading to VPS hosting for optimal performance

### 2. **Spread Costs**
- Crypto spreads can be **$10-$100** on BTC/USD
- EA accounts for spreads in profit calculation
- Higher spreads = fewer opportunities

### 3. **Slippage Risk**
- High volatility = more slippage
- Set appropriate slippage tolerance
- Monitor actual fills vs expected prices

### 4. **Order Execution**
- Not all brokers allow hedging (required for this strategy)
- Execution must be instantaneous across all 3 legs
- Partial fills can break the arbitrage cycle

### 5. **Market Conditions**
- Works best during **high volatility** periods
- Low volatility = fewer opportunities
- Major news events can cause extreme spreads

### 6. **Capital Requirements**
- Minimum: $500-$1,000 with leverage
- Recommended: $2,000-$5,000+
- Remember: You're trading 3 positions simultaneously

### 7. **Risk Management**
- This EA does NOT use stop losses (by design)
- Relies on instant execution of all 3 legs
- Failed execution on any leg = potential loss
- Always monitor performance closely

---

## 📈 MONITORING & PERFORMANCE

### Information Panel Shows:

1. **Status**: Active (trading) or Monitoring (watching only)
2. **Triangle**: The three pairs being monitored
3. **Opportunity**: Whether profitable setup exists
4. **Profit**: Expected profit % and dollar amount
5. **Trades**: Daily and total trade count
6. **Prices**: Current BTC and ETH prices

### Key Metrics to Watch:

- **Opportunity frequency**: Should find 5-20+ per day
- **Execution success rate**: Should be >90%
- **Average profit per trade**: Should exceed 0.5%
- **Daily trade count**: Should increase during volatile periods
- **Slippage**: Should stay within tolerance

---

## 🔧 TROUBLESHOOTING

### "Symbol not found" error
➜ Check exact symbol names in Market Watch
➜ Right-click Market Watch → Show All
➜ Adjust EA parameters to match

### No opportunities found
➜ Spreads may be too wide
➜ Lower minimum profit threshold
➜ Check if all pairs are actively trading
➜ Try different time of day (more volatility)

### Trades not executing
➜ Verify "Enable Live Trading" is ON
➜ Check if AutoTrading is enabled (button in toolbar)
➜ Verify account has sufficient margin
➜ Check broker allows hedging

### Panel not showing
➜ Set "Show Panel" to true
➜ Adjust X/Y coordinates if off-screen
➜ Check if objects are visible (Chart → Objects → List)

### High CPU usage
➜ Increase "Check Interval Ms" to 1000+
➜ Disable panel in settings
➜ Disable detailed logging

---

## 💡 TIPS FOR SUCCESS

1. **Start Small**: Use 0.01 lots until you're confident
2. **Monitor First**: Run in monitoring mode for 24 hours
3. **Pick Good Times**: Trade during high volatility (Asian/London open)
4. **Use VPS**: 24/7 operation maximizes opportunities
5. **Check Spreads**: Avoid trading during extremely wide spreads
6. **Set Alerts**: Monitor via MT5 mobile app
7. **Review Daily**: Check performance every 24 hours
8. **Be Patient**: May take days to find optimal settings
9. **Adjust Thresholds**: Increase min profit if too many losing trades
10. **Stay Updated**: Crypto markets change - adjust EA accordingly

---

## 📞 SUPPORT & RESOURCES

### Documentation:
- MetaTrader 5 Documentation: https://www.mql5.com/en/docs
- Deriv MT5 Guide: [https://deriv.com/trading-platforms/mt5](https://deriv.com/blog/posts/your-guide-to-deriv-mt5-the-world-famous-cfd-trading-platform)
- Crashboomtrading.com https://crashboomtrading.com/

### Testing:
- Always test thoroughly on DEMO first
- Forward test for minimum 1 week
- Backtest on recent data (last 3-6 months)

### Risk Disclaimer:
Trading cryptocurrencies involves substantial risk. This EA is provided "as is" without warranty. Past performance does not guarantee future results. Never trade with money you cannot afford to lose.

---

## 📜 VERSION HISTORY

**v1.00** - Initial Release
- BTC-ETH-USD triangular arbitrage
- Forward and reverse path detection
- Real-time spread calculation
- Information panel
- Strategy tester support
- Daily trade limits
- Risk management features

---

## 🎓 ADDITIONAL NOTES

### How the EA Decides:

1. **Scans prices** every X milliseconds (configurable)
2. **Calculates both paths** (forward and reverse)
3. **Subtracts spreads** from theoretical profit
4. **Compares to minimum** profit threshold
5. **Executes best path** if profitable
6. **Logs results** for analysis

### Position Management:

- Opens 3 positions simultaneously (one per pair)
- Uses unique Magic Number to identify its trades
- Can close conflicting positions automatically
- Tracks total daily trades
- Records performance statistics

### Strategy Tester Integration:

- Supports backtesting on historical data
- Custom fitness function for optimization
- Forward testing validation
- Detailed performance metrics
- Compatible with MT5 optimization algorithms

---

**Good luck with your triangular arbitrage trading!** 🚀💰

Remember: The key to success is **thorough testing**, **proper configuration**, and **constant monitoring**.

//+------------------------------------------------------------------+
//|                              TriangularArbitrage_BTC_ETH_USD.mq5 |
//|                                           Crypto Arbitrage Expert |
//|                                      https://www.deriv.com        |
//+------------------------------------------------------------------+
#property copyright "Crypto Arbitrage Expert"
#property link      "https://www.dineth.lk"
#property version   "1.01"
#property description "Triangular Arbitrage EA for BTC/USD, ETH/USD, BTC/ETH"
#property description "Exploits price discrepancies in cryptocurrency triangular relationships"
#property description "Optimized for 1-minute chart operations"

//--- Include necessary files
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//--- Input parameters
input group "=== Trading Pairs ==="
input string InpSymbol1 = "BTCUSD";           // Symbol 1: BTC/USD
input string InpSymbol2 = "ETHUSD";           // Symbol 2: ETH/USD
input string InpSymbol3 = "BTCETH";           // Symbol 3: BTC/ETH

input group "=== Profit & Risk Parameters ==="
input double InpMinProfitPercent = 0.5;       // Minimum Profit % (after spreads)
input double InpMaxSlippagePercent = 2.0;     // Maximum Slippage % Allowed
input double InpLotSize = 0.01;               // Lot Size per Trade
input bool   InpUsePercentLot = false;        // Use % of Balance for Lot Size
input double InpRiskPercent = 1.0;            // Risk % of Balance (if enabled)

input group "=== Execution Settings ==="
input int    InpMagicNumber = 789456;         // Magic Number
input int    InpSlippagePoints = 50;          // Slippage (points)
input int    InpCheckIntervalMs = 500;        // Check Interval (milliseconds)
input bool   InpEnableTrading = true;         // Enable Live Trading
input bool   InpCloseOnOpposite = true;       // Close Opposite Positions

input group "=== Display & Monitoring ==="
input bool   InpShowPanel = true;             // Show Information Panel
input int    InpPanelX = 20;                  // Panel X Position
input int    InpPanelY = 30;                  // Panel Y Position
input color  InpPanelColor = clrDarkSlateGray;// Panel Background Color
input color  InpTextColor = clrWhite;         // Text Color

input group "=== Advanced Settings ==="
input bool   InpLogDetails = true;            // Log Detailed Information
input int    InpMaxTradesPerPeriod = 200;     // Maximum Trades Per Period
input double InpMinLiquidity = 0.0;           // Minimum Order Book Depth (0=disable)
input ENUM_TIMEFRAMES InpResetTimeframe = PERIOD_M1; // Trade Counter Reset Timeframe

//--- Global variables
CTrade trade;
CSymbolInfo sym1, sym2, sym3;
CPositionInfo position;
CAccountInfo account;

datetime lastCheckTime = 0;
int periodTradeCount = 0;
datetime currentPeriod = 0;
double totalProfit = 0;
int totalTrades = 0;
int profitableTrades = 0;

struct ArbitrageOpportunity
{
    bool exists;
    bool isForward;          // true = USD->BTC->ETH->USD, false = USD->ETH->BTC->USD
    double profitPercent;
    double expectedProfit;
    double path1Price;       // First leg price
    double path2Price;       // Second leg price
    double path3Price;       // Third leg price
    string description;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Set magic number
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippagePoints);
    trade.LogLevel(LOG_LEVEL_ERRORS);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(InpSymbol1);
    
    //--- Initialize symbols
    if(!sym1.Name(InpSymbol1))
    {
        PrintFormat("Failed to initialize symbol: %s", InpSymbol1);
        return(INIT_FAILED);
    }
    if(!sym2.Name(InpSymbol2))
    {
        PrintFormat("Failed to initialize symbol: %s", InpSymbol2);
        return(INIT_FAILED);
    }
    if(!sym3.Name(InpSymbol3))
    {
        PrintFormat("Failed to initialize symbol: %s", InpSymbol3);
        return(INIT_FAILED);
    }
    
    //--- Refresh symbol information
    sym1.Refresh();
    sym2.Refresh();
    sym3.Refresh();
    
    //--- Check if symbols are available
    if(!sym1.Select() || !sym2.Select() || !sym3.Select())
    {
        Print("Error: One or more symbols are not available in Market Watch");
        Print("Please add ", InpSymbol1, ", ", InpSymbol2, ", and ", InpSymbol3, " to Market Watch");
        return(INIT_FAILED);
    }
    
    //--- Validate minimum profit
    if(InpMinProfitPercent <= 0)
    {
        Print("Error: Minimum profit percent must be greater than 0");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    //--- Initialize period for trade counter
    currentPeriod = iTime(InpSymbol1, InpResetTimeframe, 0);
    
    //--- Create display panel
    if(InpShowPanel)
    {
        CreatePanel();
    }
    
    //--- Print initialization info
    PrintFormat("=== Triangular Arbitrage EA Initialized ===");
    PrintFormat("Triangle: %s - %s - %s", InpSymbol1, InpSymbol2, InpSymbol3);
    PrintFormat("Min Profit: %.2f%% | Lot Size: %.2f | Trading: %s", 
                InpMinProfitPercent, InpLotSize, InpEnableTrading ? "ENABLED" : "DISABLED");
    PrintFormat("Working on %s timeframe for trade counter", EnumToString(InpResetTimeframe));
    PrintFormat("Attach this EA to any chart - it works on tick data");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- Remove panel
    if(InpShowPanel)
    {
        RemovePanel();
    }
    
    //--- Print statistics
    PrintFormat("=== EA Removed: Total Trades: %d | Profitable: %d | Total Profit: %.2f ===", 
                totalTrades, profitableTrades, totalProfit);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Check if enough time has passed since last check
    if(GetTickCount() - (uint)lastCheckTime < (uint)InpCheckIntervalMs)
        return;
    
    lastCheckTime = GetTickCount();
    
    //--- Reset period counter if new period
    datetime newPeriod = iTime(InpSymbol1, InpResetTimeframe, 0);
    if(newPeriod != currentPeriod)
    {
        currentPeriod = newPeriod;
        periodTradeCount = 0;
        if(InpLogDetails)
            PrintFormat("New %s period started - trade counter reset", EnumToString(InpResetTimeframe));
    }
    
    //--- Check period trade limit
    if(periodTradeCount >= InpMaxTradesPerPeriod)
    {
        if(InpLogDetails)
            Print("Period trade limit reached: ", periodTradeCount);
        return;
    }
    
    //--- Refresh symbol prices
    if(!sym1.RefreshRates() || !sym2.RefreshRates() || !sym3.RefreshRates())
    {
        if(InpLogDetails)
            Print("Failed to refresh rates");
        return;
    }
    
    //--- Check for arbitrage opportunity
    ArbitrageOpportunity opp = CheckArbitrageOpportunity();
    
    //--- Update panel
    if(InpShowPanel)
    {
        UpdatePanel(opp);
    }
    
    //--- Execute trade if opportunity exists
    if(opp.exists && InpEnableTrading)
    {
        ExecuteArbitrage(opp);
    }
}

//+------------------------------------------------------------------+
//| Check for triangular arbitrage opportunity                       |
//+------------------------------------------------------------------+
ArbitrageOpportunity CheckArbitrageOpportunity()
{
    ArbitrageOpportunity opp;
    opp.exists = false;
    opp.isForward = true;
    opp.profitPercent = 0;
    opp.expectedProfit = 0;
    
    //--- Get current prices
    double btcUsdBid = sym1.Bid();
    double btcUsdAsk = sym1.Ask();
    double ethUsdBid = sym2.Bid();
    double ethUsdAsk = sym2.Ask();
    double btcEthBid = sym3.Bid();  // Price to sell BTC for ETH
    double btcEthAsk = sym3.Ask();  // Price to buy BTC with ETH
    
    //--- Calculate spreads
    double spread1 = btcUsdAsk - btcUsdBid;
    double spread2 = ethUsdAsk - ethUsdBid;
    double spread3 = btcEthAsk - btcEthBid;
    
    //--- Starting capital (normalized to 1 USD)
    double startCapital = 1.0;
    
    //--- FORWARD PATH: USD -> BTC -> ETH -> USD
    // 1. Buy BTC with USD (spend USD, get BTC)
    double btcAmount1 = startCapital / btcUsdAsk;
    
    // 2. Convert BTC to ETH (sell BTC, get ETH)
    double ethAmount1 = btcAmount1 * btcEthBid;
    
    // 3. Sell ETH for USD (sell ETH, get USD)
    double finalUsd1 = ethAmount1 * ethUsdBid;
    
    double forwardProfit = finalUsd1 - startCapital;
    double forwardProfitPercent = (forwardProfit / startCapital) * 100.0;
    
    //--- REVERSE PATH: USD -> ETH -> BTC -> USD
    // 1. Buy ETH with USD (spend USD, get ETH)
    double ethAmount2 = startCapital / ethUsdAsk;
    
    // 2. Convert ETH to BTC (buy BTC with ETH)
    double btcAmount2 = ethAmount2 / btcEthAsk;
    
    // 3. Sell BTC for USD (sell BTC, get USD)
    double finalUsd2 = btcAmount2 * btcUsdBid;
    
    double reverseProfit = finalUsd2 - startCapital;
    double reverseProfitPercent = (reverseProfit / startCapital) * 100.0;
    
    //--- Determine best path
    if(forwardProfitPercent > reverseProfitPercent && forwardProfitPercent > InpMinProfitPercent)
    {
        opp.exists = true;
        opp.isForward = true;
        opp.profitPercent = forwardProfitPercent;
        opp.expectedProfit = forwardProfit;
        opp.path1Price = btcUsdAsk;
        opp.path2Price = btcEthBid;
        opp.path3Price = ethUsdBid;
        opp.description = StringFormat("FORWARD: USD->BTC(%.2f)->ETH(%.4f)->USD | Profit: %.2f%%", 
                                       btcUsdAsk, btcEthBid, forwardProfitPercent);
    }
    else if(reverseProfitPercent > InpMinProfitPercent)
    {
        opp.exists = true;
        opp.isForward = false;
        opp.profitPercent = reverseProfitPercent;
        opp.expectedProfit = reverseProfit;
        opp.path1Price = ethUsdAsk;
        opp.path2Price = btcEthAsk;
        opp.path3Price = btcUsdBid;
        opp.description = StringFormat("REVERSE: USD->ETH(%.2f)->BTC(%.4f)->USD | Profit: %.2f%%", 
                                       ethUsdAsk, btcEthAsk, reverseProfitPercent);
    }
    
    //--- Log opportunity if found
    if(opp.exists && InpLogDetails)
    {
        PrintFormat(">>> OPPORTUNITY DETECTED: %s", opp.description);
        PrintFormat("    Spreads: BTC/USD=%.2f | ETH/USD=%.2f | BTC/ETH=%.6f", 
                    spread1, spread2, spread3);
    }
    
    return opp;
}

//+------------------------------------------------------------------+
//| Execute triangular arbitrage                                     |
//+------------------------------------------------------------------+
void ExecuteArbitrage(ArbitrageOpportunity &opp)
{
    //--- Calculate lot size
    double lotSize = InpLotSize;
    
    if(InpUsePercentLot)
    {
        double balance = account.Balance();
        double riskAmount = balance * InpRiskPercent / 100.0;
        lotSize = NormalizeLot(InpSymbol1, riskAmount / sym1.Ask());
    }
    
    //--- Normalize lot sizes for each symbol
    double lot1 = NormalizeLot(InpSymbol1, lotSize);
    double lot2 = NormalizeLot(InpSymbol2, lotSize);
    double lot3 = NormalizeLot(InpSymbol3, lotSize);
    
    //--- Check lot sizes
    if(lot1 < sym1.LotsMin() || lot2 < sym2.LotsMin() || lot3 < sym3.LotsMin())
    {
        Print("Error: Lot size too small for one or more symbols");
        return;
    }
    
    //--- Close opposite positions if enabled
    if(InpCloseOnOpposite)
    {
        CloseAllPositions();
    }
    
    bool success = false;
    
    if(opp.isForward)
    {
        //--- FORWARD: USD -> BTC -> ETH -> USD
        success = ExecuteForwardPath(lot1, lot2, lot3);
    }
    else
    {
        //--- REVERSE: USD -> ETH -> BTC -> USD
        success = ExecuteReversePath(lot1, lot2, lot3);
    }
    
    if(success)
    {
        periodTradeCount++;
        totalTrades++;
        
        PrintFormat("=== Trade Executed: %s | Period Trades: %d/%d ===", 
                    opp.isForward ? "FORWARD" : "REVERSE", 
                    periodTradeCount, InpMaxTradesPerPeriod);
    }
}

//+------------------------------------------------------------------+
//| Execute forward path: USD -> BTC -> ETH -> USD                   |
//+------------------------------------------------------------------+
bool ExecuteForwardPath(double lot1, double lot2, double lot3)
{
    //--- Step 1: Buy BTC with USD
    if(!trade.Buy(lot1, InpSymbol1, 0, 0, 0, "Arb-F1: Buy BTC"))
    {
        PrintFormat("Failed to buy BTC: %s", trade.ResultRetcodeDescription());
        return false;
    }
    
    Sleep(100); // Small delay for execution
    
    //--- Step 2: Sell BTC for ETH (Sell BTC/ETH means get ETH)
    if(!trade.Sell(lot3, InpSymbol3, 0, 0, 0, "Arb-F2: BTC->ETH"))
    {
        PrintFormat("Failed to convert BTC to ETH: %s", trade.ResultRetcodeDescription());
        return false;
    }
    
    Sleep(100);
    
    //--- Step 3: Sell ETH for USD
    if(!trade.Sell(lot2, InpSymbol2, 0, 0, 0, "Arb-F3: Sell ETH"))
    {
        PrintFormat("Failed to sell ETH: %s", trade.ResultRetcodeDescription());
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Execute reverse path: USD -> ETH -> BTC -> USD                   |
//+------------------------------------------------------------------+
bool ExecuteReversePath(double lot1, double lot2, double lot3)
{
    //--- Step 1: Buy ETH with USD
    if(!trade.Buy(lot2, InpSymbol2, 0, 0, 0, "Arb-R1: Buy ETH"))
    {
        PrintFormat("Failed to buy ETH: %s", trade.ResultRetcodeDescription());
        return false;
    }
    
    Sleep(100);
    
    //--- Step 2: Buy BTC with ETH (Buy BTC/ETH means spend ETH, get BTC)
    if(!trade.Buy(lot3, InpSymbol3, 0, 0, 0, "Arb-R2: ETH->BTC"))
    {
        PrintFormat("Failed to convert ETH to BTC: %s", trade.ResultRetcodeDescription());
        return false;
    }
    
    Sleep(100);
    
    //--- Step 3: Sell BTC for USD
    if(!trade.Sell(lot1, InpSymbol1, 0, 0, 0, "Arb-R3: Sell BTC"))
    {
        PrintFormat("Failed to sell BTC: %s", trade.ResultRetcodeDescription());
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Normalize lot size                                               |
//+------------------------------------------------------------------+
double NormalizeLot(string symbol, double lots)
{
    CSymbolInfo sym;
    sym.Name(symbol);
    sym.Refresh();
    
    double lotStep = sym.LotsStep();
    double lotMin = sym.LotsMin();
    double lotMax = sym.LotsMax();
    
    lots = MathFloor(lots / lotStep) * lotStep;
    lots = MathMax(lots, lotMin);
    lots = MathMin(lots, lotMax);
    
    return lots;
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber)
            {
                trade.PositionClose(position.Ticket());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Create information panel                                         |
//+------------------------------------------------------------------+
void CreatePanel()
{
    string prefix = "ArbPanel_";
    
    //--- Create background
    ObjectCreate(0, prefix + "BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XDISTANCE, InpPanelX);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YDISTANCE, InpPanelY);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XSIZE, 420);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YSIZE, 240);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BGCOLOR, InpPanelColor);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BACK, true);
    
    //--- Create title
    ObjectCreate(0, prefix + "Title", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "Title", OBJPROP_XDISTANCE, InpPanelX + 10);
    ObjectSetInteger(0, prefix + "Title", OBJPROP_YDISTANCE, InpPanelY + 5);
    ObjectSetString(0, prefix + "Title", OBJPROP_TEXT, "▶ TRIANGULAR ARBITRAGE [" + EnumToString(InpResetTimeframe) + "]");
    ObjectSetInteger(0, prefix + "Title", OBJPROP_COLOR, clrYellow);
    ObjectSetInteger(0, prefix + "Title", OBJPROP_FONTSIZE, 9);
    ObjectSetString(0, prefix + "Title", OBJPROP_FONT, "Arial Bold");
    
    //--- Create info labels
    string labels[] = {"Status", "Triangle", "Opportunity", "Profit", "Trades", "Prices", "Period"};
    
    for(int i = 0; i < ArraySize(labels); i++)
    {
        ObjectCreate(0, prefix + "Label" + IntegerToString(i), OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, prefix + "Label" + IntegerToString(i), OBJPROP_XDISTANCE, InpPanelX + 10);
        ObjectSetInteger(0, prefix + "Label" + IntegerToString(i), OBJPROP_YDISTANCE, InpPanelY + 30 + (i * 30));
        ObjectSetString(0, prefix + "Label" + IntegerToString(i), OBJPROP_TEXT, labels[i] + ":");
        ObjectSetInteger(0, prefix + "Label" + IntegerToString(i), OBJPROP_COLOR, InpTextColor);
        ObjectSetInteger(0, prefix + "Label" + IntegerToString(i), OBJPROP_FONTSIZE, 8);
    }
    
    //--- Create value labels
    for(int i = 0; i < ArraySize(labels); i++)
    {
        ObjectCreate(0, prefix + "Value" + IntegerToString(i), OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, prefix + "Value" + IntegerToString(i), OBJPROP_XDISTANCE, InpPanelX + 100);
        ObjectSetInteger(0, prefix + "Value" + IntegerToString(i), OBJPROP_YDISTANCE, InpPanelY + 30 + (i * 30));
        ObjectSetString(0, prefix + "Value" + IntegerToString(i), OBJPROP_TEXT, "Initializing...");
        ObjectSetInteger(0, prefix + "Value" + IntegerToString(i), OBJPROP_COLOR, clrLimeGreen);
        ObjectSetInteger(0, prefix + "Value" + IntegerToString(i), OBJPROP_FONTSIZE, 8);
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Update information panel                                         |
//+------------------------------------------------------------------+
void UpdatePanel(ArbitrageOpportunity &opp)
{
    string prefix = "ArbPanel_";
    
    //--- Update status
    string status = InpEnableTrading ? "● ACTIVE" : "○ MONITORING";
    color statusColor = InpEnableTrading ? clrLimeGreen : clrOrange;
    ObjectSetString(0, prefix + "Value0", OBJPROP_TEXT, status);
    ObjectSetInteger(0, prefix + "Value0", OBJPROP_COLOR, statusColor);
    
    //--- Update triangle info
    string triangle = InpSymbol1 + " - " + InpSymbol2 + " - " + InpSymbol3;
    ObjectSetString(0, prefix + "Value1", OBJPROP_TEXT, triangle);
    
    //--- Update opportunity status
    string oppStatus = opp.exists ? "✓ FOUND" : "✗ None";
    color oppColor = opp.exists ? clrYellow : clrGray;
    ObjectSetString(0, prefix + "Value2", OBJPROP_TEXT, oppStatus);
    ObjectSetInteger(0, prefix + "Value2", OBJPROP_COLOR, oppColor);
    
    //--- Update profit
    string profit = opp.exists ? StringFormat("%.2f%% ($%.2f)", opp.profitPercent, opp.expectedProfit * InpLotSize * 100000) : "0.00%";
    ObjectSetString(0, prefix + "Value3", OBJPROP_TEXT, profit);
    ObjectSetInteger(0, prefix + "Value3", OBJPROP_COLOR, opp.exists ? clrYellow : clrGray);
    
    //--- Update trades
    string trades = StringFormat("%d/%d | Total: %d", periodTradeCount, InpMaxTradesPerPeriod, totalTrades);
    ObjectSetString(0, prefix + "Value4", OBJPROP_TEXT, trades);
    
    //--- Update prices
    string prices = StringFormat("BTC: $%.0f | ETH: $%.0f", sym1.Bid(), sym2.Bid());
    ObjectSetString(0, prefix + "Value5", OBJPROP_TEXT, prices);
    
    //--- Update period info
    string periodInfo = StringFormat("%s candle", EnumToString(InpResetTimeframe));
    ObjectSetString(0, prefix + "Value6", OBJPROP_TEXT, periodInfo);
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Remove information panel                                         |
//+------------------------------------------------------------------+
void RemovePanel()
{
    string prefix = "ArbPanel_";
    
    ObjectDelete(0, prefix + "BG");
    ObjectDelete(0, prefix + "Title");
    
    for(int i = 0; i < 7; i++)
    {
        ObjectDelete(0, prefix + "Label" + IntegerToString(i));
        ObjectDelete(0, prefix + "Value" + IntegerToString(i));
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| OnTester function for strategy tester optimization               |
//+------------------------------------------------------------------+
double OnTester()
{
    double profit = TesterStatistics(STAT_PROFIT);
    double trades = TesterStatistics(STAT_TRADES);
    double winRate = TesterStatistics(STAT_PROFIT_TRADES) / MathMax(trades, 1) * 100.0;
    
    //--- Custom fitness: profit factor weighted by win rate
    double profitFactor = TesterStatistics(STAT_PROFIT_FACTOR);
    double fitness = profitFactor * (winRate / 100.0);
    
    return fitness;
}
//+------------------------------------------------------------------+

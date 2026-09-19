#!/usr/bin/env bash
set -euo pipefail

APP="NEXUS Futures"
PKG="com.eezh.nexusfutures"

rm -rf app gradle settings.gradle build.gradle gradlew gradlew.bat gradle.properties
mkdir -p app/src/main/java/com/eezh/nexusfutures app/src/main/res/values app/src/main/assets

cat > settings.gradle <<'EOF'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories { google(); mavenCentral() }
}
rootProject.name='NEXUS-Futures'
include ':app'
EOF

cat > build.gradle <<'EOF'
plugins {
    id 'com.android.application' version '8.7.3' apply false
}
EOF

cat > gradle.properties <<'EOF'
android.useAndroidX=true
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
EOF

cat > app/build.gradle <<'EOF'
plugins { id 'com.android.application' }

android {
    namespace 'com.eezh.nexusfutures'
    compileSdk 35

    defaultConfig {
        applicationId 'com.eezh.nexusfutures'
        minSdk 26
        targetSdk 35
        versionCode 4
        versionName '4.0.0'
    }
}

dependencies {
    implementation 'androidx.webkit:webkit:1.12.1'
}
EOF

cat > app/src/main/res/values/strings.xml <<'EOF'
<resources><string name="app_name">NEXUS Futures</string></resources>
EOF

cat > app/src/main/res/values/styles.xml <<'EOF'
<resources>
    <style name="AppTheme" parent="@android:style/Theme.DeviceDefault.NoActionBar">
        <item name="android:fontFamily">sans</item>
        <item name="android:windowLightStatusBar">false</item>
        <item name="android:statusBarColor">#080b12</item>
        <item name="android:navigationBarColor">#080b12</item>
    </style>
</resources>
EOF

cat > app/src/main/AndroidManifest.xml <<'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application android:theme="@style/AppTheme" android:label="NEXUS Futures" android:usesCleartextTraffic="false">
        <activity android:name=".MainActivity" android:screenOrientation="portrait" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

cat > app/src/main/java/com/eezh/nexusfutures/MainActivity.java <<'EOF'
package com.eezh.nexusfutures;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        WebView w = new WebView(this);
        w.setWebViewClient(new WebViewClient());
        WebSettings s = w.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setAllowFileAccessFromFileURLs(true);
        s.setAllowUniversalAccessFromFileURLs(true);
        s.setBuiltInZoomControls(false);
        s.setDisplayZoomControls(false);
        w.loadUrl("file:///android_asset/index.html");
        setContentView(w);
    }
}
EOF

cat > app/src/main/assets/index.html <<'EOF'
<!doctype html>
<html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<title>NEXUS Futures</title>
<style>
:root{--bg:#050812;--panel:#0b1220;--panel2:#101a2c;--line:#20304a;--text:#eef5ff;--muted:#8191ab;--cyan:#45d8ff;--violet:#9b6cff;--green:#32e69b;--red:#ff5573;--gold:#f3c75f}
*{box-sizing:border-box}body{margin:0;background:radial-gradient(circle at 80% 0,#102445 0,#050812 38%);color:var(--text);font:14px Arial,sans-serif}
header{padding:15px 16px 12px;border-bottom:1px solid var(--line);position:sticky;top:0;background:rgba(5,8,18,.94);backdrop-filter:blur(12px);z-index:10}
.brand{display:flex;align-items:center;gap:10px}.logo{width:38px;height:38px;border-radius:12px;border:1px solid #49dfff;background:linear-gradient(145deg,#102d49,#11102b);display:grid;place-items:center;box-shadow:0 0 20px #3dd8ff33;font-size:25px;font-weight:900;color:#fff}.brand h1{margin:0;font-size:19px;letter-spacing:2px}.sub{color:var(--muted);font-size:10px;letter-spacing:1.2px;margin-top:3px}
.wrap{padding:12px;padding-bottom:82px}.screen{display:none}.screen.active{display:block}.grid{display:grid;grid-template-columns:repeat(2,1fr);gap:9px}.card{background:linear-gradient(145deg,#0d1727,#09101c);border:1px solid var(--line);border-radius:15px;padding:12px;margin-bottom:10px;box-shadow:0 8px 30px #0003}.label{color:var(--muted);font-size:9px;text-transform:uppercase;letter-spacing:1px}.big{font-size:20px;font-weight:800;margin-top:5px}.green{color:var(--green)}.red{color:var(--red)}.yellow{color:var(--gold)}.cyan{color:var(--cyan)}.violet{color:#b18cff}
.row{display:flex;gap:8px;align-items:center;flex-wrap:wrap}.row>*{flex:1}select,input,button{width:100%;background:#101b2c;border:1px solid #2b3d5a;color:var(--text);border-radius:9px;padding:10px}button{font-weight:800}.primary{background:linear-gradient(90deg,#1b9f78,#27cfa0);border:0}.danger{background:#6f2638;border-color:#a83b54}
.tabs{display:flex;gap:6px;overflow:auto;margin:0 0 10px}.tab{white-space:nowrap;padding:8px 11px;border:1px solid var(--line);border-radius:9px;color:var(--muted);font-size:11px}.tab.on{color:#fff;border-color:#42cfff;background:#12304a}
table{width:100%;border-collapse:collapse}td{padding:7px 3px;border-bottom:1px solid #1b283d}td:last-child{text-align:right;font-weight:700}.bar{height:7px;background:#17243a;border-radius:10px;overflow:hidden}.fill{height:100%;background:linear-gradient(90deg,var(--cyan),var(--violet));width:0}
canvas{width:100%;height:180px;background:#07101b;border-radius:10px}.badge{display:inline-block;padding:4px 7px;border-radius:20px;background:#14243a;color:#a9c1df;font-size:9px}.ai{border-color:#5e4fa0;background:linear-gradient(145deg,#11152b,#0b1220)}.aihead{display:flex;align-items:center;gap:8px}.aiorb{width:34px;height:34px;border-radius:50%;display:grid;place-items:center;background:radial-gradient(circle,#7fe8ff,#6d44e8);box-shadow:0 0 20px #6b73ff88;font-weight:900}.bubble{margin-top:10px;background:#111d31;border:1px solid #263b59;padding:11px;border-radius:11px;line-height:1.45}.chip{display:inline-block;padding:7px 9px;border:1px solid #2a3b55;border-radius:9px;margin:4px 3px 0 0;color:#a9c0dc;font-size:10px}
.bottom{position:fixed;bottom:0;left:0;right:0;background:rgba(6,10,19,.97);border-top:1px solid var(--line);display:flex;justify-content:space-around;padding:7px 4px;z-index:20}.nav{color:#71819a;font-size:9px;text-align:center}.nav b{display:block;font-size:18px}.nav.on{color:var(--cyan)}
pre{white-space:pre-wrap;color:#9eacc0;font-size:10px;max-height:170px;overflow:auto}.metric{display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid #1c2940}.hero{padding:16px;border-radius:16px;background:linear-gradient(135deg,#102a42,#161133);border:1px solid #294667;margin-bottom:10px}.hero h2{margin:0 0 5px;font-size:23px}.tiny{font-size:10px;color:var(--muted)}
</style></head>
<body>
<header><div class="brand"><div class="logo">N</div><div><h1>NEXUS FUTURES</h1><div class="sub">AI-ASSISTED • ADAPTIVE • DISCIPLINED</div></div></div></header>
<div class="wrap">

<section id="home" class="screen active">
<div class="hero"><h2>Trade smarter. Evolve further.</h2><div class="sub">Your market intelligence and paper-trading command centre.</div></div>
<div class="grid">
<div class="card"><div class="label">Equity</div><div id="eq" class="big">$10,000.00</div></div>
<div class="card"><div class="label">Today's P&L</div><div id="pnl" class="big">$0.00</div></div>
<div class="card"><div class="label">Open Risk</div><div id="openrisk" class="big cyan">0.00%</div></div>
<div class="card"><div class="label">Engine</div><div id="status" class="big yellow">STOPPED</div></div>
</div>
<div class="card"><b>Market Radar</b><div id="radar"></div></div>
<div class="card ai"><div class="aihead"><div class="aiorb">N</div><div><b>NEXUS AI</b><div class="tiny">Learning & market coach</div></div></div><div id="aihome" class="bubble">Connect to the market and I’ll explain what the engine is seeing.</div></div>
</section>

<section id="trade" class="screen">
<div class="card"><div class="row">
<div><div class="label">Symbol</div><select id="sym"><option>BTCUSDT</option><option>ETHUSDT</option><option>BNBUSDT</option><option>SOLUSDT</option><option>XRPUSDT</option></select></div>
<div><div class="label">Timeframe</div><select id="tf"><option>1m</option><option selected>5m</option><option>15m</option><option>1h</option></select></div>
</div></div>
<div class="card"><div class="row" style="margin-bottom:8px"><span class="badge" id="conn">● CONNECTING</span><span class="tiny" id="dataage">Waiting for market data…</span></div><canvas id="chart"></canvas></div>
<div class="card"><b>Live Intelligence</b><table>
<tr><td>Price</td><td id="price">—</td></tr><tr><td>Trend / EMA</td><td id="trend">—</td></tr><tr><td>RSI</td><td id="rsi">—</td></tr><tr><td>ATR</td><td id="atr">—</td></tr><tr><td>Structure</td><td id="structure">—</td></tr><tr><td>Liquidity</td><td id="sweep">—</td></tr><tr><td>FVG / Imbalance</td><td id="fvg">—</td></tr></table><br><div class="label">Confluence</div><div class="bar"><div id="scorebar" class="fill"></div></div><div style="text-align:right;margin-top:5px"><b id="score">0</b>/8</div></div>
<div class="card ai"><div class="aihead"><div class="aiorb">N</div><b>NEXUS AI — Setup Coach</b></div><div id="aitrade" class="bubble">Waiting for enough market data.</div><div><span class="chip" onclick="teach('What is confluence?')">Explain confluence</span><span class="chip" onclick="teach('Why this setup?')">Why this setup?</span><span class="chip" onclick="teach('How should I manage risk?')">Risk lesson</span></div></div>
<div class="card"><b>Paper Engine</b><div class="row"><button class="primary" onclick="startBot()">START</button><button onclick="stopBot()">STOP</button><button class="danger" onclick="kill()">KILL</button></div></div>
<div class="card"><b>Position</b><table><tr><td>Side</td><td id="pside">FLAT</td></tr><tr><td>Entry</td><td id="pentry">—</td></tr><tr><td>SL</td><td id="psl">—</td></tr><tr><td>TP</td><td id="ptp">—</td></tr><tr><td>Size</td><td id="psize">—</td></tr><tr><td>Unrealised</td><td id="upnl">—</td></tr></table></div>
</section>

<section id="ai" class="screen">
<div class="hero"><h2>NEXUS AI</h2><div class="sub">Explain • Teach • Review • Improve</div></div>
<div class="card ai"><div class="aihead"><div class="aiorb">N</div><div><b>Market Coach</b><div class="tiny">Context-aware guidance from current bot data</div></div></div><div id="aichat" class="bubble">Ask NEXUS about the current market, a setup, risk, or your recent paper trades.</div><div><span class="chip" onclick="teach('Give me a market lesson')">Market lesson</span><span class="chip" onclick="teach('Review my current setup')">Review setup</span><span class="chip" onclick="teach('What did I learn today?')">Daily lesson</span><span class="chip" onclick="teach('How can I improve?')">Improve</span></div></div>
<div class="card"><b>Learning Loop</b><div class="metric"><span>Observations</span><b id="obs">0</b></div><div class="metric"><span>Paper trades</span><b id="trades">0</b></div><div class="metric"><span>Lessons generated</span><b id="lessons">0</b></div><div class="metric"><span>Adaptive status</span><b class="green">ANALYSING</b></div></div>
<div class="card"><b>Today’s lesson</b><div id="lesson" class="bubble">NEXUS will build a lesson from actual signals and paper results as data accumulates.</div></div>
</section>

<section id="analytics" class="screen">
<div class="hero"><h2>Analytics</h2><div class="sub">Measure the system before changing the system.</div></div>
<div class="grid"><div class="card"><div class="label">Trades</div><div id="atrades" class="big">0</div></div><div class="card"><div class="label">Win rate</div><div id="winrate" class="big">—</div></div><div class="card"><div class="label">Profit factor</div><div id="pf" class="big">—</div></div><div class="card"><div class="label">Learning score</div><div id="learnscore" class="big cyan">0</div></div></div>
<div class="card"><b>Performance Engine</b><div id="analyticsText" class="bubble">Waiting for paper-trade history.</div></div>
<div class="card"><b>Adaptive rulebook</b><div class="metric"><span>Observation</span><b>ON</b></div><div class="metric"><span>Hypothesis testing</span><b>ON</b></div><div class="metric"><span>Auto-live changes</span><b class="red">OFF</b></div><div class="tiny">NEXUS can propose adjustments from measured results; it does not silently rewrite live trading rules.</div></div>
</section>

<section id="settings" class="screen">
<div class="hero"><h2>Risk & Settings</h2><div class="sub">Safety first. Intelligence second. Execution third.</div></div>
<div class="card"><b>Risk Engine</b><div class="row"><div><div class="label">Risk / trade %</div><input id="risk" type="number" value="0.50" step="0.05"></div><div><div class="label">Max daily loss %</div><input id="maxloss" type="number" value="2.00" step="0.25"></div></div></div>
<div class="card"><b>Operating Mode</b><div class="row"><button class="primary">PAPER</button><button disabled>SHADOW</button><button disabled>LIVE</button></div><br><div class="tiny">LIVE trading remains disabled in this build. Real-money execution requires exchange authentication, signed orders, reconciliation, idempotency, secure key storage and extensive testing.</div></div>
<div class="card"><b>System Log</b><pre id="log"></pre></div>
</section>
</div>

<nav class="bottom">
<div class="nav on" onclick="show('home',this)"><b>⌂</b>Home</div><div class="nav" onclick="show('trade',this)"><b>⌁</b>Trade</div><div class="nav" onclick="show('ai',this)"><b>✦</b>AI</div><div class="nav" onclick="show('analytics',this)"><b>▥</b>Analytics</div><div class="nav" onclick="show('settings',this)"><b>⚙</b>Risk</div>
</nav>

<script>
let ws=null,running=false,killed=false,price=0,equity=10000,dayPnl=0,pos=null;
let closes=[],highs=[],lows=[],vols=[],lastBar=0,trades=[],observations=0,lessons=0;
const $=id=>document.getElementById(id);
function show(id,el){document.querySelectorAll('.screen').forEach(x=>x.classList.remove('active'));$(id).classList.add('active');document.querySelectorAll('.nav').forEach(x=>x.classList.remove('on'));el.classList.add('on')}
function log(x){let t=new Date().toLocaleTimeString();$("log").textContent=("["+t+"] "+x+"\n"+$("log").textContent).slice(0,7000)}
function ema(a,n){if(a.length<n)return null;let k=2/(n+1),e=a.slice(0,n).reduce((x,y)=>x+y,0)/n;for(let i=n;i<a.length;i++)e=a[i]*k+e*(1-k);return e}
function rsi(a,n=14){if(a.length<n+1)return null;let g=0,l=0;for(let i=a.length-n;i<a.length;i++){let d=a[i]-a[i-1];if(d>0)g+=d;else l-=d}return l===0?100:100-100/(1+g/l)}
function atr(n=14){if(highs.length<n+1)return null;let t=[];for(let i=1;i<highs.length;i++)t.push(Math.max(highs[i]-lows[i],Math.abs(highs[i]-closes[i-1]),Math.abs(lows[i]-closes[i-1])));return t.slice(-n).reduce((a,b)=>a+b,0)/n}
function fmt(x){return Number(x).toLocaleString(undefined,{maximumFractionDigits:2})}
function analyze(){
 if(closes.length<55)return;
 observations++;
 let e20=ema(closes,20),e50=ema(closes,50),rr=rsi(closes),aa=atr(),bull=e20>e50;
 let rh=Math.max(...highs.slice(-20)),rl=Math.min(...lows.slice(-20));
 let sweep=lows.at(-1)<Math.min(...lows.slice(-6,-1))?"SELL-SIDE SWEEP":highs.at(-1)>Math.max(...highs.slice(-6,-1))?"BUY-SIDE SWEEP":"NONE";
 let structure=closes.at(-1)>rh?"BULL BOS":closes.at(-1)<rl?"BEAR BOS":bull?"BULL STRUCTURE":"BEAR STRUCTURE";
 let fvg=Math.abs(closes.at(-1)-closes.at(-3))>(aa||0)*1.2,score=0;
 if((bull&&closes.at(-1)>e20)||(!bull&&closes.at(-1)<e20))score++;
 if((bull&&rr>52)||(!bull&&rr<48))score++; if(structure.includes("BOS"))score+=2;
 if(sweep!="NONE")score++; if(fvg)score++;
 if(vols.at(-1)>vols.slice(-20).reduce((a,b)=>a+b,0)/20)score++;
 if((bull&&closes.at(-1)>closes.at(-5))||(!bull&&closes.at(-1)<closes.at(-5)))score++;
 $("price").textContent=fmt(price);$("trend").textContent=(bull?"BULLISH":"BEARISH")+" • EMA20 "+fmt(e20)+" / EMA50 "+fmt(e50);
 $("trend").className=bull?"green":"red";$("rsi").textContent=fmt(rr);$("atr").textContent=fmt(aa);$("structure").textContent=structure;$("sweep").textContent=sweep;$("fvg").textContent=fvg?"PRESENT":"NONE";
 $("score").textContent=score;$("scorebar").style.width=(score/8*100)+"%";
 let insight=(bull?"Bullish":"Bearish")+" structure with "+(sweep=="NONE"?"no fresh":"a recent")+" liquidity sweep. Confluence is "+score+"/8.";
 $("aitrade").textContent=insight+" NEXUS will only consider an automatic paper entry when the configured threshold is met.";
 $("aihome").textContent=score>=6?"Setup quality is elevated at "+score+"/8. I would still respect the configured risk limits.":"No high-confluence setup is confirmed yet. Patience is part of the strategy.";
 $("obs").textContent=observations;$("learnscore").textContent=Math.min(100,Math.round(observations/10));
 if(running&&!killed&&!pos&&score>=6)openPosition(bull,aa);
 draw();updateAnalytics();
}
function openPosition(bull,aa){
 if(!aa||price<=0)return;let rp=Math.max(.05,Math.min(5,Number($("risk").value)||.5)),cash=equity*rp/100,dist=aa*1.5,qty=cash/dist;
 pos={side:bull?"LONG":"SHORT",entry:price,sl:bull?price-dist:price+dist,tp:bull?price+dist*2:price-dist*2,qty,riskCash:cash};
 log("PAPER "+pos.side+" opened @ "+fmt(price)+" | confluence >= 6/8");updatePos();
}
function closePosition(exit,reason){
 if(!pos)return;let dir=pos.side==="LONG"?1:-1,pnl=(exit-pos.entry)*pos.qty*dir;
 equity+=pnl;dayPnl+=pnl;trades.push({pnl,side:pos.side});lessons++;
 log("PAPER "+pos.side+" closed | "+reason+" | P&L "+fmt(pnl));pos=null;
 $("eq").textContent="$"+fmt(equity);$("pnl").textContent="$"+fmt(dayPnl);updatePos();updateAnalytics();
}
function updatePos(){
 if(!pos){$("pside").textContent="FLAT";["pentry","psl","ptp","psize","upnl"].forEach(x=>$(x).textContent="—");$("openrisk").textContent="0.00%";return}
 $("pside").textContent=pos.side;$("pentry").textContent=fmt(pos.entry);$("psl").textContent=fmt(pos.sl);$("ptp").textContent=fmt(pos.tp);$("psize").textContent=fmt(pos.qty);
 let u=(price-pos.entry)*pos.qty*(pos.side==="LONG"?1:-1);$("upnl").textContent=(u>=0?"+":"")+fmt(u);$("upnl").className=u>=0?"green":"red";$("openrisk").textContent=((pos.riskCash/equity)*100).toFixed(2)+"%";
}
function checkExit(){
 if(!pos)return;if(pos.side==="LONG"&&(price<=pos.sl||price>=pos.tp))closePosition(price,price<=pos.sl?"STOP LOSS":"TAKE PROFIT");
 if(pos&&pos.side==="SHORT"&&(price>=pos.sl||price<=pos.tp))closePosition(price,price>=pos.sl?"STOP LOSS":"TAKE PROFIT");
 let max=Math.abs(equity*(Number($("maxloss").value)||2)/100);if(dayPnl<=-max){killed=true;running=false;$("status").textContent="KILLED";$("status").className="big red";log("Daily loss limit reached")}
 updatePos();
}
async function loadHistory(){
  const symbol=$("sym").value, interval=$("tf").value;
  $("conn").textContent="● LOADING HISTORY"; $("conn").className="badge yellow";
  $("dataage").textContent="Fetching recent candles…";
  try{
    const url="https://fapi.binance.com/fapi/v1/klines?symbol="+symbol+"&interval="+interval+"&limit=250";
    const r=await fetch(url,{cache:"no-store"});
    if(!r.ok) throw new Error("HTTP "+r.status);
    const data=await r.json();
    closes=[];highs=[];lows=[];vols=[];
    data.forEach(k=>{
      highs.push(Number(k[2])); lows.push(Number(k[3])); closes.push(Number(k[4])); vols.push(Number(k[5]));
    });
    if(data.length){
      lastBar=Number(data[data.length-1][0]);
      price=Number(data[data.length-1][4]);
      $("price").textContent=fmt(price);
      $("conn").textContent="● HISTORY READY"; $("conn").className="badge cyan";
      $("dataage").textContent=data.length+" candles loaded";
      analyze();
      log("Loaded "+data.length+" historical "+interval+" candles for "+symbol);
    }
  }catch(e){
    $("conn").textContent="● HISTORY ERROR"; $("conn").className="badge red";
    $("dataage").textContent="Could not load candles";
    log("History error: "+e.message);
  }
}
function connect(){
  if(ws)try{ws.close()}catch(e){}
  let s=$("sym").value.toLowerCase(),t=$("tf").value;
  $("conn").textContent="● CONNECTING LIVE"; $("conn").className="badge yellow";
  ws=new WebSocket("wss://fstream.binance.com/ws/"+s+"@kline_"+t);
  ws.onopen=()=>{ $("conn").textContent="● LIVE"; $("conn").className="badge green"; $("dataage").textContent="Live market stream connected"; log("Connected to Binance Futures live stream"); };
  ws.onclose=()=>{ $("conn").textContent="● RECONNECTING"; $("conn").className="badge yellow"; $("dataage").textContent="Live stream disconnected"; log("Stream disconnected — reconnecting"); setTimeout(()=>{if(!killed)connect()},3000)};
  ws.onerror=()=>{ $("conn").textContent="● STREAM ERROR"; $("conn").className="badge red"; log("WebSocket error"); };
  ws.onmessage=e=>{
    let d=JSON.parse(e.data),k=d.k;if(!k)return;
    price=Number(k.c); $("price").textContent=fmt(price);
    $("dataage").textContent="Live • "+new Date().toLocaleTimeString();
    let bt=Number(k.t);
    if(closes.length===0){
      closes.push(price); highs.push(+k.h); lows.push(+k.l); vols.push(+k.v); lastBar=bt;
    } else if(bt===lastBar){
      closes[closes.length-1]=price; highs[highs.length-1]=+k.h; lows[lows.length-1]=+k.l; vols[vols.length-1]=+k.v;
    } else {
      lastBar=bt; closes.push(price); highs.push(+k.h); lows.push(+k.l); vols.push(+k.v);
      if(closes.length>300){closes.shift();highs.shift();lows.shift();vols.shift()}
    }
    if(closes.length>=55) analyze();
    checkExit();
  };
}
async function initializeMarket(){
  await loadHistory();
  if(!killed) connect();
}
function startBot(){killed=false;running=true;$("status").textContent="RUNNING";$("status").className="big green";log("Paper engine started")}
function stopBot(){running=false;$("status").textContent="STOPPED";$("status").className="big yellow";log("Paper engine stopped")}
function kill(){running=false;killed=true;if(pos)closePosition(price,"KILL SWITCH");$("status").textContent="KILLED";$("status").className="big red";log("KILL SWITCH activated")}
function teach(q){lessons++;let msg;if(q.includes("confluence"))msg="Confluence means multiple independent conditions agree. NEXUS combines trend, structure, liquidity, momentum, imbalance and volume instead of relying on one indicator.";else if(q.includes("Why"))msg="The current setup is evaluated from the live structure, EMA relationship, RSI, ATR, liquidity behaviour, imbalance and volume. A high score does not remove risk.";else if(q.includes("risk"))msg="Risk sizing starts from the amount you are willing to lose at the stop, then derives position size from stop distance. The goal is to keep losses bounded rather than chase a target.";else if(q.includes("improve"))msg="Improvement comes from measuring trades by setup, regime, symbol and timeframe. NEXUS proposes changes only after enough evidence; it does not silently rewrite live rules.";else msg="Today’s lesson: a good trading system is not one that trades constantly. It is one that waits for defined conditions, controls risk and learns from measured outcomes.";
$("aichat").textContent=msg;$("lesson").textContent=msg;$("lessons").textContent=lessons}
function updateAnalytics(){
 $("trades").textContent=trades.length;$("atrades").textContent=trades.length;
 if(!trades.length)return;$("winrate").textContent=(trades.filter(t=>t.pnl>0).length/trades.length*100).toFixed(1)+"%";
 let wins=trades.filter(t=>t.pnl>0).reduce((a,b)=>a+b.pnl,0),loss=Math.abs(trades.filter(t=>t.pnl<0).reduce((a,b)=>a+b.pnl,0));
 $("pf").textContent=loss?wins/loss.toFixed(2):"∞";
 $("analyticsText").textContent="NEXUS has "+trades.length+" paper trade(s). It is tracking outcome patterns and will use larger samples before proposing adaptive rule changes.";
 $("radar").innerHTML='<div class="metric"><span>'+$("sym").value+'</span><b class="cyan">'+$("score").textContent+'/8</b></div><div class="metric"><span>Current price</span><b>'+fmt(price)+'</b></div><div class="metric"><span>Engine</span><b class="'+(running?"green":"yellow")+'">'+(running?"RUNNING":"STOPPED")+'</b></div>';
}
function draw(){
  let c=$("chart"),x=c.getContext("2d"),w=c.width=c.clientWidth*2,h=c.height=c.clientHeight*2;
  x.clearRect(0,0,w,h);
  if(closes.length<2)return;
  let n=Math.min(70,closes.length),from=closes.length-n;
  let hh=highs.slice(from),ll=lows.slice(from),cc=closes.slice(from);
  let mn=Math.min(...ll),mx=Math.max(...hh),pad=18;
  let step=(w-pad*2)/n, scale=v=>h-pad-(v-mn)/(mx-mn||1)*(h-pad*2);
  // grid
  x.strokeStyle="#142238";x.lineWidth=1;
  for(let i=1;i<5;i++){let gy=pad+i*(h-pad*2)/5;x.beginPath();x.moveTo(pad,gy);x.lineTo(w-pad,gy);x.stroke()}
  // candles
  cc.forEach((v,i)=>{
    let hi=scale(hh[i]),lo=scale(ll[i]),open=i?cc[i-1]:v,close=v;
    let oy=scale(open),cy=scale(close),cx=pad+i*step+step/2;
    x.strokeStyle=close>=open?"#32e69b":"#ff5573";x.lineWidth=2;
    x.beginPath();x.moveTo(cx,hi);x.lineTo(cx,lo);x.stroke();
    x.fillStyle=close>=open?"#32e69b":"#ff5573";
    let top=Math.min(oy,cy), bh=Math.max(2,Math.abs(oy-cy));
    x.fillRect(cx-step*.28,top,step*.56,bh);
  });
  function overlay(period,stroke){
    if(closes.length<period)return;
    let all=[];for(let i=period;i<=closes.length;i++)all.push(ema(closes.slice(0,i),period));
    let vals=all.slice(-n);x.strokeStyle=stroke;x.lineWidth=3;x.beginPath();
    vals.forEach((v,i)=>{let px=pad+(i+.5)*step,py=scale(v);i?x.lineTo(px,py):x.moveTo(px,py)});x.stroke();
  }
  overlay(20,"#45d8ff");overlay(50,"#9b6cff");
}
$("sym").onchange=()=>{closes=[];highs=[];lows=[];vols=[];initializeMarket()};$("tf").onchange=()=>{closes=[];highs=[];lows=[];vols=[];initializeMarket()};initializeMarket();log("NEXUS 4.0 initialized — loading market intelligence");
</script></body></html>
EOFF

echo "NEXUS Futures 2.0 project generated."

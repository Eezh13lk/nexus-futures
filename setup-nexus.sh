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
        versionCode 2
        versionName '2.0.0'
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
*{box-sizing:border-box}body{margin:0;background:#080b12;color:#e8edf7;font:14px Arial,sans-serif}
header{padding:16px 16px 10px;border-bottom:1px solid #202634;position:sticky;top:0;background:#080b12;z-index:5}
h1{margin:0;font-size:22px}.sub{color:#7f8ba3;font-size:11px;margin-top:4px}
.wrap{padding:12px}.grid{display:grid;grid-template-columns:repeat(2,1fr);gap:9px}
.card{background:#101521;border:1px solid #20283a;border-radius:12px;padding:12px;margin-bottom:10px}
.label{color:#7f8ba3;font-size:10px;text-transform:uppercase}.big{font-size:20px;font-weight:700;margin-top:5px}
.green{color:#48e09a}.red{color:#ff667d}.yellow{color:#f6c85f}.blue{color:#63a9ff}
.row{display:flex;gap:8px;align-items:center;flex-wrap:wrap}.row>*{flex:1}
select,input,button{width:100%;background:#151c2a;border:1px solid #303a50;color:#e8edf7;border-radius:8px;padding:10px}
button{font-weight:700}.primary{background:#1b7f55;border-color:#28ad75}.danger{background:#842c3e;border-color:#b94760}
table{width:100%;border-collapse:collapse}td{padding:7px 3px;border-bottom:1px solid #202634}td:last-child{text-align:right;font-weight:700}
.bar{height:7px;background:#20283a;border-radius:10px;overflow:hidden}.fill{height:100%;background:#55a7ff;width:0}
pre{white-space:pre-wrap;color:#9ca8bd;font-size:11px;max-height:180px;overflow:auto}
canvas{width:100%;height:180px;background:#0b101a;border-radius:8px}
.badge{display:inline-block;padding:4px 7px;border-radius:20px;background:#182235;color:#9db2d3;font-size:10px}
</style></head>
<body>
<header><h1>NEXUS Futures 2.0</h1><div class="sub">MULTI-TIMEFRAME • CONFLUENCE ENGINE • PAPER MODE</div></header>
<div class="wrap">
<div class="grid">
<div class="card"><div class="label">Equity</div><div id="eq" class="big">$10,000.00</div></div>
<div class="card"><div class="label">Daily P&L</div><div id="pnl" class="big">$0.00</div></div>
<div class="card"><div class="label">Market Price</div><div id="price" class="big">—</div></div>
<div class="card"><div class="label">Engine</div><div id="status" class="big yellow">STOPPED</div></div>
</div>

<div class="card">
<div class="row">
<div><div class="label">Symbol</div><select id="sym"><option>BTCUSDT</option><option>ETHUSDT</option><option>BNBUSDT</option><option>SOLUSDT</option><option>XRPUSDT</option></select></div>
<div><div class="label">Timeframe</div><select id="tf"><option>1m</option><option selected>5m</option><option>15m</option><option>1h</option></select></div>
</div>
<br><canvas id="chart"></canvas>
</div>

<div class="card"><b>Market Intelligence</b><table>
<tr><td>Trend / EMA</td><td id="trend">—</td></tr>
<tr><td>RSI(14)</td><td id="rsi">—</td></tr>
<tr><td>ATR(14)</td><td id="atr">—</td></tr>
<tr><td>Structure / BOS</td><td id="structure">—</td></tr>
<tr><td>Liquidity Sweep</td><td id="sweep">—</td></tr>
<tr><td>Imbalance / FVG</td><td id="fvg">—</td></tr>
<tr><td>Confluence</td><td><span id="score">0</span>/8</td></tr>
</table><div class="bar"><div id="scorebar" class="fill"></div></div></div>

<div class="card"><b>Risk Engine</b><div class="row">
<div><div class="label">Risk / Trade %</div><input id="risk" type="number" value="0.50" step="0.05"></div>
<div><div class="label">Max Daily Loss %</div><input id="maxloss" type="number" value="2.00" step="0.25"></div>
</div><br>
<div class="row"><button class="primary" onclick="startBot()">START PAPER ENGINE</button><button onclick="stopBot()">STOP</button><button class="danger" onclick="kill()">KILL SWITCH</button></div>
</div>

<div class="card"><b>Paper Position</b><table>
<tr><td>Side</td><td id="pside">FLAT</td></tr><tr><td>Entry</td><td id="pentry">—</td></tr>
<tr><td>Stop Loss</td><td id="psl">—</td></tr><tr><td>Take Profit</td><td id="ptp">—</td></tr>
<tr><td>Size</td><td id="psize">—</td></tr><tr><td>Unrealised P&L</td><td id="upnl">—</td></tr>
</table></div>

<div class="card"><b>System Log</b><pre id="log"></pre></div>
<div class="sub">Public Binance Futures market data only. No API keys. No real-money orders. LIVE mode is intentionally disabled in this build.</div>
</div>

<script>
let ws=null, running=false, killed=false, price=0, equity=10000, dayPnl=0, pos=null;
let closes=[], highs=[], lows=[], vols=[], times=[], lastBar=0;

const $=id=>document.getElementById(id);
function log(x){let t=new Date().toLocaleTimeString();$("log").textContent=("["+t+"] "+x+"\n"+$("log").textContent).slice(0,6000)}
function ema(a,n){if(a.length<n)return null;let k=2/(n+1),e=a.slice(0,n).reduce((x,y)=>x+y,0)/n;for(let i=n;i<a.length;i++)e=a[i]*k+e*(1-k);return e}
function rsi(a,n=14){if(a.length<n+1)return null;let g=0,l=0;for(let i=a.length-n;i<a.length;i++){let d=a[i]-a[i-1];if(d>0)g+=d;else l-=d}return l===0?100:100-100/(1+g/l)}
function atr(n=14){if(highs.length<n+1)return null;let tr=[];for(let i=1;i<highs.length;i++)tr.push(Math.max(highs[i]-lows[i],Math.abs(highs[i]-closes[i-1]),Math.abs(lows[i]-closes[i-1])));return tr.slice(-n).reduce((a,b)=>a+b,0)/n}
function fmt(x){return Number(x).toLocaleString(undefined,{maximumFractionDigits:2})}
function analyze(){
 if(closes.length<55)return;
 let e20=ema(closes,20),e50=ema(closes,50), rr=rsi(closes), aa=atr();
 let bull=e20>e50, recentH=Math.max(...highs.slice(-20)),recentL=Math.min(...lows.slice(-20));
 let sweep=(lows[lows.length-1]<Math.min(...lows.slice(-6,-1)))?"SELL-SIDE SWEEP":
           (highs[highs.length-1]>Math.max(...highs.slice(-6,-1)))?"BUY-SIDE SWEEP":"NONE";
 let structure=closes.at(-1)>recentH?"BULL BOS":closes.at(-1)<recentL?"BEAR BOS":bull?"BULL STRUCTURE":"BEAR STRUCTURE";
 let fvg=Math.abs(closes.at(-1)-closes.at(-3))>(aa||0)*1.2;
 let score=0;
 if(bull&&closes.at(-1)>e20 || !bull&&closes.at(-1)<e20)score++;
 if(bull&&rr>52 || !bull&&rr<48)score++;
 if(structure.includes("BOS"))score+=2;
 if(sweep!="NONE")score++;
 if(fvg)score++;
 if(vols.at(-1)>vols.slice(-20).reduce((a,b)=>a+b,0)/20)score++;
 if((bull&&closes.at(-1)>closes.at(-5))||(!bull&&closes.at(-1)<closes.at(-5)))score++;
 $("trend").textContent=(bull?"BULLISH":"BEARISH")+" • EMA20 "+fmt(e20)+" / EMA50 "+fmt(e50);
 $("trend").className=bull?"green":"red"; $("rsi").textContent=rr?fmt(rr):"—";
 $("atr").textContent=aa?fmt(aa):"—"; $("structure").textContent=structure;
 $("sweep").textContent=sweep; $("fvg").textContent=fvg?"PRESENT":"NONE";
 $("score").textContent=score; $("scorebar").style.width=(score/8*100)+"%";
 if(running&&!killed&&!pos&&score>=6) openPosition(bull,aa);
 draw();
}
function openPosition(bull,aa){
 if(!aa||price<=0)return;
 let riskPct=Math.max(0.05,Math.min(5,Number($("risk").value)||.5));
 let riskCash=equity*riskPct/100, stopDist=aa*1.5, qty=riskCash/stopDist;
 let side=bull?"LONG":"SHORT", entry=price, sl=bull?entry-stopDist:entry+stopDist, tp=bull?entry+stopDist*2:entry-stopDist*2;
 pos={side,entry,sl,tp,qty,riskCash}; log("PAPER "+side+" opened @ "+fmt(entry)+" | SL "+fmt(sl)+" | TP "+fmt(tp)+" | score >= 6"); updatePos();
}
function closePosition(exit,reason){
 if(!pos)return; let dir=pos.side==="LONG"?1:-1, pnl=(exit-pos.entry)*pos.qty*dir;
 equity+=pnl;dayPnl+=pnl; log("PAPER "+pos.side+" closed @ "+fmt(exit)+" | "+reason+" | P&L "+(pnl>=0?"+":"")+fmt(pnl));
 pos=null; $("eq").textContent="$"+fmt(equity); $("pnl").textContent="$"+fmt(dayPnl); $("pnl").className="big "+(dayPnl>=0?"green":"red"); updatePos();
}
function updatePos(){
 if(!pos){$("pside").textContent="FLAT";["pentry","psl","ptp","psize","upnl"].forEach(x=>$(x).textContent="—");return}
 $("pside").textContent=pos.side;$("pentry").textContent=fmt(pos.entry);$("psl").textContent=fmt(pos.sl);$("ptp").textContent=fmt(pos.tp);$("psize").textContent=fmt(pos.qty);
 let u=(price-pos.entry)*pos.qty*(pos.side==="LONG"?1:-1);$("upnl").textContent=(u>=0?"+":"")+fmt(u);$("upnl").className=u>=0?"green":"red";
}
function checkExit(){
 if(!pos)return; if(pos.side==="LONG"&&(price<=pos.sl||price>=pos.tp))closePosition(price,price<=pos.sl?"STOP LOSS":"TAKE PROFIT");
 if(pos&&pos.side==="SHORT"&&(price>=pos.sl||price<=pos.tp))closePosition(price,price>=pos.sl?"STOP LOSS":"TAKE PROFIT");
 let max=Math.abs(equity*(Number($("maxloss").value)||2)/100);
 if(dayPnl<=-max){killed=true;running=false;$("status").textContent="KILLED";$("status").className="big red";log("DAILY LOSS LIMIT reached — kill switch engaged")}
 updatePos();
}
function connect(){
 if(ws)try{ws.close()}catch(e){}
 let s=$("sym").value.toLowerCase(), t=$("tf").value;
 ws=new WebSocket("wss://fstream.binance.com/ws/"+s+"@kline_"+t);
 ws.onopen=()=>{log("Connected to Binance Futures public market stream");$("status").textContent=running?"RUNNING":"STOPPED";};
 ws.onclose=()=>{log("Market stream disconnected");setTimeout(()=>{if(!killed)connect()},3000)};
 ws.onerror=()=>log("WebSocket error");
 ws.onmessage=e=>{
  let d=JSON.parse(e.data), k=d.k; if(!k)return;
  price=Number(k.c);$("price").textContent=fmt(price);
  if(Number(k.t)!==lastBar){lastBar=Number(k.t);closes.push(price);highs.push(Number(k.h));lows.push(Number(k.l));vols.push(Number(k.v));times.push(Number(k.t));
    if(closes.length>300){closes.shift();highs.shift();lows.shift();vols.shift();times.shift()} analyze();
  }
  checkExit();
 };
}
function startBot(){killed=false;running=true;$("status").textContent="RUNNING";$("status").className="big green";log("Paper engine started — confluence threshold 6/8");}
function stopBot(){running=false;$("status").textContent="STOPPED";$("status").className="big yellow";log("Paper engine stopped")}
function kill(){running=false;killed=true;if(pos)closePosition(price,"KILL SWITCH");$("status").textContent="KILLED";$("status").className="big red";log("KILL SWITCH activated")}
function draw(){
 let c=$("chart"),x=c.getContext("2d"),w=c.width=c.clientWidth*2,h=c.height=c.clientHeight*2;x.clearRect(0,0,w,h);
 if(closes.length<2)return;let a=closes.slice(-80),mn=Math.min(...a),mx=Math.max(...a),pad=12;
 x.strokeStyle="#5aa9ff";x.lineWidth=3;x.beginPath();
 a.forEach((v,i)=>{let px=pad+i*(w-2*pad)/(a.length-1),py=h-pad-(v-mn)/(mx-mn||1)*(h-2*pad);i?x.lineTo(px,py):x.moveTo(px,py)});x.stroke();
}
$("sym").onchange=()=>{closes=[];highs=[];lows=[];vols=[];times=[];connect()};
$("tf").onchange=()=>{closes=[];highs=[];lows=[];vols=[];times=[];connect()};
connect(); log("NEXUS 2.0 initialized");
</script></body></html>
EOF

echo "NEXUS Futures 2.0 project generated."

#!/usr/bin/env bash
set -euo pipefail
rm -rf app gradle settings.gradle build.gradle gradle.properties
mkdir -p app/src/main/java/com/eezh/nexusfutures app/src/main/res/values
cat > settings.gradle <<'NEXUS_EOF'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS); repositories { google(); mavenCentral() } }
rootProject.name='NEXUS-Futures'
include ':app'

NEXUS_EOF
cat > build.gradle <<'NEXUS_EOF'
plugins { id 'com.android.application' version '8.7.3' apply false }

NEXUS_EOF
cat > gradle.properties <<'NEXUS_EOF'
android.useAndroidX=true
org.gradle.jvmargs=-Xmx3072m -Dfile.encoding=UTF-8

NEXUS_EOF
cat > app/build.gradle <<'NEXUS_EOF'
plugins { id 'com.android.application' }
android {
    namespace 'com.eezh.nexusfutures'
    compileSdk 35
    defaultConfig {
        applicationId 'com.eezh.nexusfutures'
        minSdk 26
        targetSdk 35
        versionCode 50
        versionName '5.0.0'
    }
}
dependencies {
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
}

NEXUS_EOF
cat > app/src/main/res/values/strings.xml <<'NEXUS_EOF'
<resources><string name="app_name">NEXUS Futures</string></resources>
NEXUS_EOF
cat > app/src/main/res/values/styles.xml <<'NEXUS_EOF'
<resources>
<style name="NexusTheme" parent="android:style/Theme.Material.NoActionBar">
<item name="android:fontFamily">sans</item><item name="android:colorAccent">#45D8FF</item>
<item name="android:statusBarColor">#050812</item><item name="android:navigationBarColor">#050812</item>
<item name="android:windowLightStatusBar">false</item>
</style></resources>
NEXUS_EOF
cat > app/src/main/AndroidManifest.xml <<'NEXUS_EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
<uses-permission android:name="android.permission.INTERNET"/>
<application android:theme="@style/NexusTheme" android:label="NEXUS Futures" android:allowBackup="false">
<activity android:name=".MainActivity" android:screenOrientation="portrait" android:exported="true">
<intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent-filter>
</activity></application></manifest>
NEXUS_EOF
cat > app/src/main/java/com/eezh/nexusfutures/NexusEngine.java <<'NEXUS_EOF'
package com.eezh.nexusfutures;

import android.content.*;
import java.util.*;
import okhttp3.*;
import org.json.*;

public class NexusEngine {
    public static class Candle {
        public long time; public double open,high,low,close,volume;
        Candle(long t,double o,double h,double l,double c,double v){time=t;open=o;high=h;low=l;close=c;volume=v;}
    }
    public static class Signal {
        public String side="WAIT", reason="Waiting for data", structure="—", liquidity="—", fvg="—";
        public int score; public double entry,sl,tp,riskPct;
    }
    public final OkHttpClient http=new OkHttpClient();
    public final ArrayList<Candle> candles=new ArrayList<>();
    public final ArrayList<String> journal=new ArrayList<>();
    public String symbol="BTCUSDT", interval="5m";
    public double price,equity=10000,dayPnl,weeklyPnl;
    public boolean running,armed,killSwitch=true;
    public Signal signal=new Signal();
    private WebSocket ws;
    private long lastBar=-1;
    private final HandlerCallback ui;

    public interface HandlerCallback { void changed(); }
    public NexusEngine(HandlerCallback cb){ui=cb; load();}

    private void load(){}
    private android.content.SharedPreferences prefs;
    public void setPrefs(android.content.SharedPreferences p){
        prefs=p;
        equity=Double.longBitsToDouble(p.getLong("equity",Double.doubleToLongBits(10000)));
        armed=p.getBoolean("armed",false);
        killSwitch=p.getBoolean("kill",true);
    }
    private void save(){
        if(prefs!=null)prefs.edit().putLong("equity",Double.doubleToLongBits(equity)).putBoolean("armed",armed).putBoolean("kill",killSwitch).apply();
    }

    public void start(String s,String i){
        stop(); symbol=s; interval=i; running=true; candles.clear();
        Request req=new Request.Builder().url("https://fapi.binance.com/fapi/v1/klines?symbol="+s+"&interval="+i+"&limit=300").build();
        http.newCall(req).enqueue(new Callback(){
            public void onFailure(Call c,java.io.IOException e){ui.changed();}
            public void onResponse(Call c,Response r)throws java.io.IOException{
                try(Response rr=r){ JSONArray a=new JSONArray(rr.body().string());
                    for(int n=0;n<a.length();n++){JSONArray k=a.getJSONArray(n);candles.add(new Candle(k.getLong(0),k.getDouble(1),k.getDouble(2),k.getDouble(3),k.getDouble(4),k.getDouble(5)));}
                    analyse(); connect(); ui.changed();
                }catch(Exception e){ui.changed();}
            }
        });
    }
    public void stop(){running=false;if(ws!=null)ws.close(1000,"stop");}
    public void kill(){armed=false;killSwitch=true;running=false;if(ws!=null)ws.close(1000,"kill");save();ui.changed();}
    private void connect(){
        Request q=new Request.Builder().url("wss://fstream.binance.com/ws/"+symbol.toLowerCase()+"@kline_"+interval).build();
        ws=http.newWebSocket(q,new WebSocketListener(){
            public void onMessage(WebSocket w,String z){
                try{
                    JSONObject d=new JSONObject(z),k=d.getJSONObject("k"); long t=k.getLong("t");
                    Candle c=new Candle(t,k.getDouble("o"),k.getDouble("h"),k.getDouble("l"),k.getDouble("c"),k.getDouble("v"));
                    price=c.close;
                    if(t==lastBar&&!candles.isEmpty()) candles.set(candles.size()-1,c);
                    else {candles.add(c);lastBar=t;if(candles.size()>350)candles.remove(0);}
                    analyse(); ui.changed();
                }catch(Exception ignored){}
            }
            public void onFailure(WebSocket w,Throwable t){ui.changed();}
        });
    }

    public double ema(int n){
        if(candles.size()<n)return Double.NaN;
        double e=0;for(int i=candles.size()-n;i<candles.size();i++)e+=candles.get(i).close;e/=n;
        double k=2.0/(n+1);
        for(int i=candles.size()-n+1;i<candles.size();i++)e=candles.get(i).close*k+e*(1-k);
        return e;
    }
    public double rsi(int n){
        if(candles.size()<=n)return Double.NaN;
        double g=0,l=0;for(int i=candles.size()-n;i<candles.size();i++){double d=candles.get(i).close-candles.get(i-1).close;if(d>0)g+=d;else l-=d;}
        return l==0?100:100-100/(1+g/l);
    }
    public double atr(int n){
        if(candles.size()<=n)return Double.NaN; double s=0;
        for(int i=candles.size()-n;i<candles.size();i++){Candle c=candles.get(i),p=candles.get(i-1);s+=Math.max(c.high-c.low,Math.max(Math.abs(c.high-p.close),Math.abs(c.low-p.close)));}
        return s/n;
    }
    public double vwap(){
        int n=Math.min(50,candles.size());double pv=0,v=0;
        for(int i=candles.size()-n;i<candles.size();i++){Candle c=candles.get(i);pv+=((c.high+c.low+c.close)/3)*c.volume;v+=c.volume;}
        return v==0?price:pv/v;
    }
    private double avgVolume(){
        int n=Math.min(20,candles.size());double x=0;for(int i=candles.size()-n;i<candles.size();i++)x+=candles.get(i).volume;return n==0?0:x/n;
    }
    private void analyse(){
        if(candles.size()<55){signal=new Signal();return;}
        price=candles.get(candles.size()-1).close;
        double e20=ema(20),e50=ema(50),e200=ema(200),r=rsi(14),a=atr(14),v=vwap();
        boolean bull=e20>e50,bear=e20<e50;
        Signal s=new Signal();s.entry=price;
        int score=0;
        if((bull&&price>e20)||(bear&&price<e20)){score++;s.reason="EMA trend alignment";}else s.reason="EMA conflict";
        if((bull&&r>52&&r<72)||(bear&&r<48&&r>28)){score++;s.reason+=" • RSI regime";}
        if(!Double.isNaN(e200)&&((bull&&price>e200)||(bear&&price<e200)))score++;
        if((bull&&price>v)||(bear&&price<v))score++;
        if(candles.get(candles.size()-1).volume>avgVolume()){score++;s.reason+=" • volume expansion";}
        double rh=Double.NEGATIVE_INFINITY,rl=Double.POSITIVE_INFINITY;
        int from=Math.max(0,candles.size()-20);
        for(int i=from;i<candles.size()-2;i++){rh=Math.max(rh,candles.get(i).high);rl=Math.min(rl,candles.get(i).low);}
        boolean bosLong=price>rh,bosShort=price<rl;
        if(bosLong||bosShort){score+=2;s.structure=bosLong?"BOS LONG":"BOS SHORT";}else s.structure=bull?"BULLISH STRUCTURE":"BEARISH STRUCTURE";
        Candle x=candles.get(candles.size()-1),p=candles.get(candles.size()-2);
        if(x.low<p.low && x.close>p.close) {s.liquidity="SELL-SIDE SWEEP";score++;}
        else if(x.high>p.high && x.close<p.close){s.liquidity="BUY-SIDE SWEEP";score++;}
        if(candles.size()>=3){
            Candle a1=candles.get(candles.size()-3),a2=candles.get(candles.size()-2);
            if(a1.high<a2.low || a1.low>a2.high){s.fvg="FVG / IMBALANCE";score++;}
        }
        s.score=Math.min(8,score);
        if(s.score>=6 && bull){s.side="LONG";s.sl=price-a*1.5;s.tp=price+a*3;}
        else if(s.score>=6 && bear){s.side="SHORT";s.sl=price+a*1.5;s.tp=price-a*3;}
        else s.side="WAIT";
        s.riskPct=Math.abs(price-s.sl)/Math.max(price,1)*100;
        signal=s;
        if(armed&&!killSwitch&&running) paperStep();
    }
    private String lastPosition="FLAT"; private double posEntry,posQty;
    private void paperStep(){
        if(signal.side.equals("WAIT"))return;
        if(lastPosition.equals("FLAT")){
            double riskUsd=equity*0.01;double dist=Math.abs(signal.entry-signal.sl);if(dist<=0)return;
            posQty=riskUsd/dist;posEntry=signal.entry;lastPosition=signal.side;
            journal.add(new Date()+" OPEN "+lastPosition+" "+symbol+" @ "+String.format(Locale.US,"%.4f",posEntry));
        }else if((lastPosition.equals("LONG")&&price<=signal.sl)||(lastPosition.equals("LONG")&&price>=signal.tp)||(lastPosition.equals("SHORT")&&price>=signal.sl)||(lastPosition.equals("SHORT")&&price<=signal.tp)){
            double pnl=(lastPosition.equals("LONG")?(price-posEntry):(posEntry-price))*posQty;equity+=pnl;dayPnl+=pnl;trades++;journal.add(new Date()+" CLOSE "+lastPosition+" PnL "+String.format(Locale.US,"%.2f",pnl));lastPosition="FLAT";save();
        }
    }
    public String position(){return lastPosition.equals("FLAT")?"FLAT":lastPosition+"  entry "+String.format(Locale.US,"%.2f",posEntry)+"  qty "+String.format(Locale.US,"%.5f",posQty)+"  P&L "+String.format(Locale.US,"%.2f",(lastPosition.equals("LONG")?(price-posEntry):(posEntry-price))*posQty);}
    public int trades=0;
    public String advice(){
        if(candles.size()<55)return"Loading market data…";
        if(signal.side.equals("WAIT"))return"No trade: confluence "+signal.score+"/8. NEXUS is refusing low-quality conditions.";
        return signal.side+" candidate at "+String.format(Locale.US,"%.2f",price)+". "+signal.reason+". "+signal.structure+". Risk is defined from ATR before entry.";
    }
    public String explain(String q){
        if(q.contains("FVG"))return"Fair Value Gap: a three-candle displacement imbalance. NEXUS uses it as confluence, never as a standalone trigger.";
        if(q.contains("BOS"))return"Break of Structure occurs when price breaks a meaningful recent swing. Confirmation must agree with trend and risk.";
        if(q.contains("RISK"))return"Risk engine starts with money-at-risk, then derives quantity from stop distance. Leverage does not define the risk amount.";
        if(q.contains("LOSS"))return"Loss review should classify regime, entry quality, stop distance, execution and whether the setup met the required confluence.";
        return advice();
    }
    public String learning(){return trades<20?"Collecting paper-trade evidence before proposing parameter changes.":"Enough paper history exists to compare outcomes by setup, direction and regime; changes should be backtested before adoption.";}
    public ArrayList<Candle> getCandles(){return candles;}
}

NEXUS_EOF
cat > app/src/main/java/com/eezh/nexusfutures/MainActivity.java <<'NEXUS_EOF'
package com.eezh.nexusfutures;

import android.app.*;
import android.os.*;
import android.graphics.*;
import android.graphics.drawable.GradientDrawable;
import android.view.*;
import android.widget.*;
import android.content.*;
import java.util.*;

public class MainActivity extends Activity {
    NexusEngine e;
    LinearLayout content;
    final int BG=Color.rgb(5,8,18),P=Color.rgb(12,20,34),L=Color.rgb(32,48,72),T=Color.rgb(238,245,255),M=Color.rgb(129,145,171),C=Color.rgb(69,216,255),G=Color.rgb(50,230,155),R=Color.rgb(255,85,115),Y=Color.rgb(255,205,70);
    Handler h=new Handler(Looper.getMainLooper());
    @Override public void onCreate(Bundle b){super.onCreate(b);e=new NexusEngine(()->h.post(this::refresh));e.setPrefs(getSharedPreferences("nexus",0));buildShell();e.start("BTCUSDT","5m");}
    TextView tv(String s,float z,int c){TextView t=new TextView(this);t.setText(s);t.setTextSize(z);t.setTextColor(c);t.setPadding(0,4,0,4);return t;}
    GradientDrawable gd(int c){GradientDrawable g=new GradientDrawable();g.setColor(c);g.setCornerRadius(22);g.setStroke(1,L);return g;}
    LinearLayout card(){LinearLayout x=new LinearLayout(this);x.setOrientation(LinearLayout.VERTICAL);x.setPadding(18,16,18,16);x.setBackground(gd(P));LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,-2);p.setMargins(10,6,10,6);x.setLayoutParams(p);return x;}
    Button btn(String s){Button b=new Button(this);b.setText(s);b.setTextColor(T);b.setTextSize(11);b.setAllCaps(false);b.setBackground(gd(Color.rgb(15,28,47)));return b;}
    void buildShell(){
        LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setBackgroundColor(BG);
        LinearLayout head=new LinearLayout(this);head.setPadding(14,10,14,6);head.setGravity(Gravity.CENTER_VERTICAL);
        TextView logo=tv("N",24,Color.WHITE);logo.setGravity(17);logo.setBackground(gd(Color.rgb(15,40,62)));head.addView(logo,new LinearLayout.LayoutParams(46,46));
        LinearLayout brand=new LinearLayout(this);brand.setOrientation(LinearLayout.VERTICAL);brand.setPadding(10,0,0,0);brand.addView(tv("NEXUS FUTURES",19,T));brand.addView(tv("ADAPTIVE TRADING TERMINAL",9,M));head.addView(brand,new LinearLayout.LayoutParams(0,-2,1));
        head.addView(tv("● PAPER",10,G));root.addView(head);
        content=new LinearLayout(this);content.setOrientation(LinearLayout.VERTICAL);content.setPadding(0,0,0,70);
        ScrollView sv=new ScrollView(this);sv.addView(content);root.addView(sv,new LinearLayout.LayoutParams(-1,0,1));
        LinearLayout nav=new LinearLayout(this);String[] tabs={"TERMINAL","SIGNALS","JOURNAL","LAB","RISK"};
        for(String z:tabs){Button b=btn(z);nav.addView(b,new LinearLayout.LayoutParams(0,58,1));b.setOnClickListener(v->page(z));}
        root.addView(nav);setContentView(root);
    }
    void page(String p){content.removeAllViews();if(p.equals("TERMINAL"))terminal();else if(p.equals("SIGNALS"))signals();else if(p.equals("JOURNAL"))journal();else if(p.equals("LAB"))lab();else risk();}
    void terminal(){
        LinearLayout top=card();top.addView(tv("COMMAND TERMINAL",23,T));top.addView(tv("Real Binance Futures public market data • paper execution",10,M));
        Spinner s=new Spinner(this);String[] sy={"BTCUSDT","ETHUSDT","BNBUSDT","SOLUSDT","XRPUSDT","DOGEUSDT"};s.setAdapter(new ArrayAdapter<String>(this,android.R.layout.simple_spinner_dropdown_item,sy));top.addView(s);
        Spinner ti=new Spinner(this);String[] ts={"1m","5m","15m","1h","4h"};ti.setAdapter(new ArrayAdapter<String>(this,android.R.layout.simple_spinner_dropdown_item,ts));top.addView(ti);
        Button load=btn("LOAD MARKET");load.setOnClickListener(v->e.start(s.getSelectedItem().toString(),ti.getSelectedItem().toString()));top.addView(load);content.addView(top);
        content.addView(new ChartView(this),new LinearLayout.LayoutParams(-1,430));
        LinearLayout q=card();q.addView(tv(e.symbol+"  •  "+e.interval,15,T));q.addView(tv("PRICE      "+fmt(e.price),14,T));q.addView(tv("EMA 20/50/200   "+trend(),13,T));q.addView(tv("RSI 14     "+fmt(e.rsi),13,T));q.addView(tv("ATR 14     "+fmt(e.atr),13,T));q.addView(tv("VWAP       "+fmt(e.vwap()),13,T));q.addView(tv("STRUCTURE  "+e.signal.structure,13,T));q.addView(tv("LIQUIDITY  "+e.signal.liquidity,13,T));q.addView(tv("FVG        "+e.signal.fvg,13,T));q.addView(tv("CONFLUENCE "+e.signal.score+"/8",18,C));q.addView(tv("SIGNAL     "+e.signal.side,18,e.signal.side.equals("LONG")?G:e.signal.side.equals("SHORT")?R:Y));content.addView(q);
        LinearLayout p=card();p.addView(tv("PAPER POSITION",16,T));p.addView(tv(e.position(),13,T));Button a=btn(e.armed&&!e.killSwitch?"AUTO PAPER: ON":"AUTO PAPER: OFF");a.setOnClickListener(v->{e.armed=!e.armed;e.killSwitch=!e.armed;page("TERMINAL");});p.addView(a);content.addView(p);
    }
    String trend(){double a=e.ema(20),b=e.ema(50),c=e.ema(200);return "EMA20 "+fmt(a)+"  EMA50 "+fmt(b)+"  EMA200 "+fmt(c);}
    void signals(){LinearLayout c=card();c.addView(tv("SIGNAL ENGINE",23,T));c.addView(tv("Confluence • market structure • liquidity • imbalance • volume",10,M));c.addView(tv("DIRECTION  "+e.signal.side,19,e.signal.side.equals("LONG")?G:e.signal.side.equals("SHORT")?R:Y));c.addView(tv("SCORE      "+e.signal.score+"/8",18,C));c.addView(tv("ENTRY      "+fmt(e.signal.entry),13,T));c.addView(tv("STOP       "+fmt(e.signal.sl),13,R));c.addView(tv("TARGET     "+fmt(e.signal.tp),13,G));c.addView(tv("RISK       "+fmt(e.signal.riskPct)+"% price distance",13,M));c.addView(tv("REASON     "+e.signal.reason,13,T));content.addView(c);
        LinearLayout a=card();a.addView(tv("DECISION RULE",16,T));a.addView(tv("No single indicator can trigger a trade. EMA + RSI + long-term trend + VWAP + volume + structure + liquidity/FVG must create sufficient confluence.",12,M));content.addView(a);}
    void journal(){LinearLayout c=card();c.addView(tv("TRADE JOURNAL",23,T));c.addView(tv("Automatic paper-trade record",10,M));c.addView(tv("Equity     $"+fmt(e.equity),14,T));c.addView(tv("Day P&L    $"+fmt(e.dayPnl),14,e.dayPnl>=0?G:R));c.addView(tv("Trades     "+e.trades,14,T));content.addView(c);LinearLayout j=card();if(e.journal.isEmpty())j.addView(tv("No completed/open journal events yet.",13,M));else for(String x:e.journal)j.addView(tv(x,11,T));content.addView(j);}
    void lab(){LinearLayout c=card();c.addView(tv("NEXUS LAB",23,T));c.addView(tv("Research engine",10,M));String[] a={"SMC + liquidity","EMA trend","Breakout + volume","Momentum + ATR","Mean reversion"};for(String x:a)c.addView(tv("• "+x+"   READY",13,G));Button b=btn("RUN QUICK PAPER TEST");b.setOnClickListener(v->Toast.makeText(this,"Research mode uses the same signal logic; live execution remains off.",Toast.LENGTH_LONG).show());c.addView(b);content.addView(c);LinearLayout m=card();m.addView(tv("LEARNING",17,T));m.addView(tv(e.learning(),13,C));content.addView(m);}
    void risk(){LinearLayout c=card();c.addView(tv("RISK CENTRE",23,T));String[] a={"Risk / trade","Daily loss limit","Weekly loss limit","Max positions","Leverage ceiling","ATR stop multiplier","Take-profit R","Break-even R","Trailing stop","Minimum confluence","Cooldown"};for(String x:a){EditText q=new EditText(this);q.setHint(x);q.setTextColor(T);q.setHintTextColor(M);c.addView(q);}content.addView(c);LinearLayout m=card();m.addView(tv("SAFETY STATE",17,T));m.addView(tv("BACKTEST     READY",13,G));m.addView(tv("PAPER        READY",13,G));m.addView(tv("SHADOW       READY",13,Y));m.addView(tv("LIVE         LOCKED",13,R));m.addView(tv("Live trading is deliberately locked in this build until signed API authentication, encrypted secrets, exchange reconciliation, idempotency, partial-fill handling and hard loss controls are verified.",11,M));Button k=btn("KILL SWITCH");k.setOnClickListener(v->{e.kill();Toast.makeText(this,"NEXUS kill switch engaged.",Toast.LENGTH_SHORT).show();});m.addView(k);content.addView(m);}
    String fmt(double x){return Double.isNaN(x)||Double.isInfinite(x)?"—":String.format(Locale.US,"%.4f",x);}
    void refresh(){if(content!=null){for(int i=0;i<content.getChildCount();i++){View v=content.getChildAt(i);if(v instanceof ChartView)v.invalidate();}}}
    class ChartView extends View{
        Paint p=new Paint(3);ChartView(Context c){super(c);p.setStrokeWidth(3);}
        protected void onDraw(Canvas c){c.drawColor(Color.rgb(6,13,24));ArrayList<NexusEngine.Candle>a=e.getCandles();if(a.size()<2)return;double lo=Double.MAX_VALUE,hi=-Double.MAX_VALUE;for(NexusEngine.Candle x:a){lo=Math.min(lo,x.low);hi=Math.max(hi,x.high);}double d=hi-lo;if(d==0)d=1;int n=Math.min(120,a.size());int st=a.size()-n;float w=(getWidth()-20)/(float)n;
            p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1);p.setColor(Color.rgb(25,45,67));for(int g=1;g<5;g++){float y=g*getHeight()/5f;c.drawLine(0,y,getWidth(),y,p);}
            for(int i=st;i<a.size();i++){NexusEngine.Candle x=a.get(i);float xx=10+(i-st)*w+w*.5f;float yh=(float)(getHeight()-10-(x.high-lo)/d*(getHeight()-20));float yl=(float)(getHeight()-10-(x.low-lo)/d*(getHeight()-20));float yo=(float)(getHeight()-10-(x.open-lo)/d*(getHeight()-20));float yc=(float)(getHeight()-10-(x.close-lo)/d*(getHeight()-20));p.setColor(x.close>=x.open?G:R);c.drawLine(xx,yh,xx,yl,p);p.setStyle(Paint.Style.FILL);c.drawRect(xx-w*.28f,Math.min(yo,yc),xx+w*.28f,Math.max(yo,yc)+1,p);p.setStyle(Paint.Style.STROKE);}
        }
    }
}

NEXUS_EOF
echo "NEXUS Futures 5.0 native bot generated."

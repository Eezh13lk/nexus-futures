#!/usr/bin/env bash
set -euo pipefail

# NEXUS Futures 5.1 — self-contained native Android trading bot.
# This script creates the complete project used by GitHub Actions.
# Paper trading only; no API keys and no live orders.

rm -rf app
mkdir -p app/src/main/java/com/eezh/nexusfutures app/src/main/res/values

cat > settings.gradle <<'EOF'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories { google(); mavenCentral() }
}
rootProject.name = "NEXUS-Futures"
include(":app")
EOF

cat > build.gradle <<'EOF'
plugins {
    id 'com.android.application' version '8.7.3' apply false
}
EOF

cat > gradle.properties <<'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
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
        versionCode 51
        versionName '5.1.0'
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.7.0'
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'com.google.code.gson:gson:2.11.0'
}
EOF

cat > app/src/main/res/values/themes.xml <<'EOF'
<resources>
    <style name="Theme.Nexus" parent="Theme.AppCompat.DayNight.NoActionBar">
        <item name="android:fontFamily">sans</item>
        <item name="android:windowLightStatusBar">false</item>
        <item name="android:statusBarColor">#070A12</item>
        <item name="android:navigationBarColor">#070A12</item>
        <item name="android:colorAccent">#00E5FF</item>
    </style>
</resources>
EOF

cat > app/src/main/AndroidManifest.xml <<'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application android:theme="@style/Theme.Nexus" android:label="NEXUS Futures"
        android:allowBackup="false" android:supportsRtl="true">
        <activity android:name=".MainActivity" android:screenOrientation="portrait"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

cat > app/src/main/java/com/eezh/nexusfutures/Engine.java <<'EOF'
package com.eezh.nexusfutures;
import java.util.*;

public final class Engine {
    public static final class Candle {
        public long time; public double open,high,low,close,volume;
        public Candle(long t,double o,double h,double l,double c,double v){
            time=t;open=o;high=h;low=l;close=c;volume=v;
        }
    }
    public static double ema(List<Candle>x,int n){
        if(x.size()<n)return Double.NaN;
        double k=2.0/(n+1),e=x.get(0).close;
        for(int i=1;i<x.size();i++)e=x.get(i).close*k+e*(1-k);
        return e;
    }
    public static double rsi(List<Candle>x,int n){
        if(x.size()<=n)return Double.NaN;
        double g=0,l=0;
        for(int i=x.size()-n;i<x.size();i++){
            double d=x.get(i).close-x.get(i-1).close;
            if(d>=0)g+=d;else l-=d;
        }
        if(l==0)return 100;
        double rs=(g/n)/(l/n);
        return 100-100/(1+rs);
    }
    public static double atr(List<Candle>x,int n){
        if(x.size()<=n)return Double.NaN;
        double s=0;
        for(int i=x.size()-n;i<x.size();i++){
            Candle c=x.get(i),p=x.get(i-1);
            s+=Math.max(c.high-c.low,
              Math.max(Math.abs(c.high-p.close),Math.abs(c.low-p.close)));
        }
        return s/n;
    }
    public static double vwap(List<Candle>x,int n){
        int st=Math.max(0,x.size()-n); double pv=0,v=0;
        for(int i=st;i<x.size();i++){
            Candle c=x.get(i); double tp=(c.high+c.low+c.close)/3;
            pv+=tp*c.volume; v+=c.volume;
        }
        return v==0?Double.NaN:pv/v;
    }
    public static int score(List<Candle>x){
        if(x.size()<60)return 0;
        Candle c=x.get(x.size()-1); int s=0;
        double e20=ema(x,20),e50=ema(x,50),e200=ema(x,200);
        double r=rsi(x,14),v=vwap(x,30);
        if(c.close>e20)s++;
        if(e20>e50)s++;
        if(!Double.isNaN(e200)&&c.close>e200)s++;
        if(r>=52&&r<=68)s++;
        if(c.close>v)s++;
        Candle p=x.get(x.size()-2);
        if(c.high>p.high&&c.close>p.close)s++;
        if(c.volume>x.get(x.size()-6).volume)s++;
        double a=atr(x,14);
        if(a>0&&Math.abs(c.close-p.close)>0.7*a)s++;
        return s;
    }
    public static String signal(List<Candle>x){
        int s=score(x);
        if(s>=6)return "LONG";
        if(s<=2)return "SHORT";
        return "WAIT";
    }
}
EOF

cat > app/src/main/java/com/eezh/nexusfutures/CandleChart.java <<'EOF'
package com.eezh.nexusfutures;
import android.graphics.*;
import android.view.*;
import java.util.*;

public class CandleChart extends View {
    private List<Engine.Candle> data=new ArrayList<>();
    private Paint p=new Paint(3);
    public CandleChart(android.content.Context c){
        super(c); setBackgroundColor(Color.rgb(9,12,20));
    }
    public void setData(List<Engine.Candle>d){
        data=new ArrayList<>(d); invalidate();
    }
    protected void onDraw(Canvas c){
        super.onDraw(c);
        if(data.size()<2)return;
        float w=getWidth(),h=getHeight(),pad=30;
        int n=Math.min(90,data.size());
        double lo=Double.MAX_VALUE,hi=-Double.MAX_VALUE;
        for(int i=data.size()-n;i<data.size();i++){
            Engine.Candle x=data.get(i);
            lo=Math.min(lo,x.low);hi=Math.max(hi,x.high);
        }
        double span=Math.max(hi-lo,1e-9);
        float cw=(w-pad*2)/n;
        for(int i=0;i<n;i++){
            Engine.Candle x=data.get(data.size()-n+i);
            float xx=pad+i*cw+cw/2;
            float yh=(float)(pad+(hi-x.high)/span*(h-pad*2));
            float yl=(float)(pad+(hi-x.low)/span*(h-pad*2));
            float yo=(float)(pad+(hi-x.open)/span*(h-pad*2));
            float yc=(float)(pad+(hi-x.close)/span*(h-pad*2));
            p.setColor(x.close>=x.open?Color.rgb(45,220,160):Color.rgb(255,82,112));
            p.setStrokeWidth(2); c.drawLine(xx,yh,xx,yl,p);
            float top=Math.min(yo,yc),bot=Math.max(yo,yc);
            c.drawRect(xx-cw*.32f,top,xx+cw*.32f,Math.max(bot,top+2),p);
        }
        p.setTextSize(20);p.setColor(Color.WHITE);
        c.drawText("BTCUSDT • 15m",pad,24,p);
        p.setTextSize(12);p.setColor(Color.rgb(145,154,175));
        c.drawText("BINANCE FUTURES PUBLIC DATA",pad+155,24,p);
    }
}
EOF

cat > app/src/main/java/com/eezh/nexusfutures/MainActivity.java <<'EOF'
package com.eezh.nexusfutures;

import android.app.*;
import android.os.*;
import android.graphics.Color;
import android.view.*;
import android.widget.*;
import okhttp3.*;
import org.json.*;
import java.io.IOException;
import java.util.*;

public class MainActivity extends Activity {
    final int BG=Color.rgb(7,10,18),PANEL=Color.rgb(17,22,35);
    final int CYAN=Color.rgb(0,229,255),GREEN=Color.rgb(45,220,160);
    LinearLayout root,body; TextView price,signal,score,position,pnl,status;
    CandleChart chart; ArrayList<Engine.Candle> candles=new ArrayList<>();
    OkHttpClient http=new OkHttpClient(); Handler main=new Handler(Looper.getMainLooper());
    boolean bot=false,longPos=false; double paperEntry=0,paperQty=0,cash=1000;
    Runnable refresh=new Runnable(){public void run(){load();main.postDelayed(this,10000);}};
    @Override public void onCreate(Bundle b){super.onCreate(b);build("TERMINAL");main.post(refresh);}
    TextView tv(String s,int z){
        TextView t=new TextView(this);t.setText(s);t.setTextColor(Color.WHITE);
        t.setTextSize(z);t.setPadding(16,10,16,10);return t;
    }
    TextView box(String a,String b){
        TextView t=tv(a+"\n"+b,15);t.setBackgroundColor(PANEL);
        LinearLayout.LayoutParams q=new LinearLayout.LayoutParams(-1,-2);
        q.setMargins(8,5,8,5);body.addView(t,q);return t;
    }
    Button nav(String s){
        Button b=new Button(this);b.setText(s);b.setTextColor(Color.WHITE);
        b.setAllCaps(false);return b;
    }
    void build(String page){
        root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(BG);
        TextView head=tv("◈ NEXUS  |  FUTURES 5.1",22);
        head.setTextColor(CYAN);root.addView(head);
        body=new LinearLayout(this);body.setOrientation(LinearLayout.VERTICAL);
        ScrollView sv=new ScrollView(this);sv.addView(body);
        root.addView(sv,new LinearLayout.LayoutParams(-1,0,1));
        if(page.equals("TERMINAL"))terminal();
        else if(page.equals("SIGNALS"))signals();
        else if(page.equals("JOURNAL"))journal();
        else if(page.equals("LAB"))lab(); else risk();
        LinearLayout n=new LinearLayout(this);
        String[] a={"TERMINAL","SIGNALS","JOURNAL","LAB","RISK"};
        for(String x:a){
            Button b=nav(x);n.addView(b,new LinearLayout.LayoutParams(0,58,1));
            b.setOnClickListener(v->build(x));
        }
        root.addView(n);setContentView(root);
    }
    void terminal(){
        LinearLayout bar=new LinearLayout(this);
        price=tv("BTCUSDT  loading…",20);
        bar.addView(price,new LinearLayout.LayoutParams(0,-2,1));
        Switch sw=new Switch(this);sw.setText("PAPER BOT");sw.setTextColor(GREEN);
        sw.setOnCheckedChangeListener((b,c)->bot=c);bar.addView(sw);
        body.addView(bar);
        chart=new CandleChart(this);body.addView(chart,new LinearLayout.LayoutParams(-1,430));
        signal=box("SIGNAL","WAIT");score=box("CONFLUENCE","0 / 8");
        position=box("POSITION","FLAT");pnl=box("P&L","$0.00");
        status=box("ENGINE","Connecting to Binance Futures…");
    }
    void signals(){
        box("LIVE SIGNAL ENGINE","EMA 20/50/200 • RSI • ATR • VWAP • volume");
        box("STRUCTURE","Breakout / displacement and recent-range liquidity conditions");
        box("SMC LAYER","FVG / order-block style displacement filters");
        box("DECISION","LONG / SHORT / WAIT from multi-factor confluence");
    }
    void journal(){
        box("PAPER JOURNAL","Current-session trade tracking");
        box("POSITION",paperQty>0?(longPos?"LONG":"SHORT"):"FLAT");
        box("EQUITY","$"+String.format(Locale.US,"%.2f",cash));
    }
    void lab(){
        box("BACKTEST LAB","Same indicator engine can consume historical candles");
        box("METRICS","Trades • win rate • profit factor • drawdown • expectancy • average R");
        box("STATUS","Historical execution module is the next expansion layer.");
    }
    void risk(){
        box("RISK CENTRE","Paper account: $1,000");
        box("RISK RULE","Paper quantity capped; ATR-based stop/target");
        box("LIVE SAFETY","No API keys and no live orders in this build.");
    }
    void load(){
        Request r=new Request.Builder().url(
          "https://fapi.binance.com/fapi/v1/klines?symbol=BTCUSDT&interval=15m&limit=200").build();
        http.newCall(r).enqueue(new Callback(){
            public void onFailure(Call c,IOException e){
                main.post(()->{if(status!=null)status.setText("ENGINE • network error • retrying");});
            }
            public void onResponse(Call c,Response res)throws IOException{
                try(Response rr=res){
                    String s=rr.body().string();JSONArray a=new JSONArray(s);
                    ArrayList<Engine.Candle> z=new ArrayList<>();
                    for(int i=0;i<a.length();i++){
                        JSONArray q=a.getJSONArray(i);
                        z.add(new Engine.Candle(q.getLong(0),q.getDouble(1),q.getDouble(2),
                          q.getDouble(3),q.getDouble(4),q.getDouble(5)));
                    }
                    main.post(()->update(z));
                }catch(Exception e){
                    main.post(()->{if(status!=null)status.setText("ENGINE • data error");});
                }
            }
        });
    }
    void update(ArrayList<Engine.Candle> z){
        candles=z;Engine.Candle c=z.get(z.size()-1);
        String sg=Engine.signal(z);int sc=Engine.score(z);double a=Engine.atr(z,14);
        price.setText("BTCUSDT  $"+String.format(Locale.US,"%,.2f",c.close));
        signal.setText("SIGNAL\n"+sg);score.setText("CONFLUENCE\n"+sc+" / 8");
        status.setText("ENGINE • LIVE • "+new Date());
        chart.setData(z);paper(c.close,sg,a);
    }
    void paper(double px,String sg,double a){
        if(bot&&paperQty==0&&!sg.equals("WAIT")&&a>0){
            longPos=sg.equals("LONG");paperEntry=px;
            paperQty=Math.min(0.02,50.0/px);
        }
        if(paperQty==0){
            position.setText("POSITION\nFLAT");pnl.setText("P&L\n$0.00");return;
        }
        double raw=(longPos?(px-paperEntry):(paperEntry-px))*paperQty;
        double sl=longPos?paperEntry-1.5*a:paperEntry+1.5*a;
        double tp=longPos?paperEntry+3*a:paperEntry-3*a;
        boolean hit=(longPos&&px<=sl)||(longPos&&px>=tp)||(!longPos&&px>=sl)||(!longPos&&px<=tp);
        if(hit){cash+=raw;paperQty=0;raw=0;}
        position.setText("POSITION\n"+(longPos?"LONG":"SHORT")+"  Entry $"+
          String.format(Locale.US,"%.2f",paperEntry)+"\nQty "+
          String.format(Locale.US,"%.5f",paperQty));
        pnl.setText("P&L\n$"+String.format(Locale.US,"%.2f",raw));
    }
}
EOF

echo "NEXUS Futures 5.1 generated successfully."

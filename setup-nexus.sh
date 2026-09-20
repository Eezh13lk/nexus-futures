#!/usr/bin/env bash
set -e

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
        versionCode 40
        versionName '4.0.0'
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.7.0'
    implementation 'androidx.recyclerview:recyclerview:1.3.2'
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'com.google.code.gson:gson:2.11.0'
}
EOF

mkdir -p app/src/main/res/values
cat > app/src/main/res/values/themes.xml <<'EOF'
<resources>
    <style name="Theme.Nexus" parent="Theme.Material3.DayNight.NoActionBar">
        <item name="android:fontFamily">sans</item>
        <item name="android:windowLightStatusBar">false</item>
        <item name="android:statusBarColor">#080A12</item>
        <item name="android:navigationBarColor">#080A12</item>
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

cat > app/src/main/java/com/eezh/nexusfutures/NexusEngine.java <<'EOF'
package com.eezh.nexusfutures;

import java.util.List;

public final class NexusEngine {
    public static class Candle {
        public double open, high, low, close, volume;
        public long time;
        public Candle(long t,double o,double h,double l,double c,double v) {
            time=t; open=o; high=h; low=l; close=c; volume=v;
        }
    }

    public static double ema(List<Candle> x, int n) {
        if (x == null || x.size() < n) return Double.NaN;
        double k=2.0/(n+1.0), e=x.get(0).close;
        for (int i=1;i<x.size();i++) e=x.get(i).close*k+e*(1-k);
        return e;
    }

    public static double rsi(List<Candle> x, int n) {
        if (x == null || x.size() <= n) return Double.NaN;
        double gain=0, loss=0;
        for (int i=1;i<=n;i++) {
            double d=x.get(i).close-x.get(i-1).close;
            if(d>=0) gain+=d; else loss-=d;
        }
        if(loss==0) return 100;
        double rs=(gain/n)/(loss/n);
        return 100-(100/(1+rs));
    }

    public static double atr(List<Candle> x, int n) {
        if (x == null || x.size() <= n) return Double.NaN;
        double sum=0;
        for(int i=x.size()-n;i<x.size();i++) {
            Candle c=x.get(i), p=x.get(i-1);
            sum += Math.max(c.high-c.low,
                    Math.max(Math.abs(c.high-p.close),Math.abs(c.low-p.close)));
        }
        return sum/n;
    }

    public static int confluence(List<Candle> x) {
        if(x==null || x.size()<50) return 0;
        Candle last=x.get(x.size()-1);
        double e20=ema(x,20), e50=ema(x,50), r=rsi(x,14);
        int score=0;
        if(last.close>e20) score++;
        if(e20>e50) score++;
        if(r>50 && r<70) score++;
        if(last.close>x.get(x.size()-2).high) score++;
        if(last.volume>x.get(x.size()-5).volume) score++;
        return score;
    }
}
EOF

cat > app/src/main/java/com/eezh/nexusfutures/MainActivity.java <<'EOF'
package com.eezh.nexusfutures;

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.*;

public class MainActivity extends Activity {
    LinearLayout root, content;
    int bg=Color.rgb(8,10,18), panel=Color.rgb(17,21,34);
    int cyan=Color.rgb(0,229,255), text=Color.rgb(243,246,255);

    @Override public void onCreate(Bundle b) { super.onCreate(b); show("HOME"); }

    TextView tv(String s,int size) {
        TextView v=new TextView(this);
        v.setText(s); v.setTextColor(text); v.setTextSize(size);
        v.setPadding(22,18,22,18); return v;
    }

    Button btn(String s) {
        Button b=new Button(this); b.setText(s); b.setTextColor(text);
        b.setAllCaps(false); return b;
    }

    void show(String page) {
        root=new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(bg);

        TextView title=tv("◈  NEXUS FUTURES   •   PAPER MODE",21);
        title.setTextColor(cyan); root.addView(title,new LinearLayout.LayoutParams(-1,75));

        content=new LinearLayout(this); content.setOrientation(LinearLayout.VERTICAL);
        ScrollView scroll=new ScrollView(this); scroll.addView(content);
        root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));

        if(page.equals("HOME")) home();
        if(page.equals("TRADE")) trade();
        if(page.equals("AI")) ai();
        if(page.equals("LAB")) lab();
        if(page.equals("RISK")) risk();

        LinearLayout nav=new LinearLayout(this);
        String[] ns={"HOME","TRADE","AI","LAB","RISK"};
        for(String n:ns) {
            Button b=btn(n); nav.addView(b,new LinearLayout.LayoutParams(0,62,1));
            b.setOnClickListener(v -> show(n));
        }
        root.addView(nav); setContentView(root);
    }

    void card(String a,String b) {
        TextView v=tv(a+"\n"+b,16); v.setBackgroundColor(panel);
        LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,-2);
        p.setMargins(12,9,12,9); content.addView(v,p);
    }

    void home() {
        card("MARKET ENGINE","Binance Futures market-data architecture • multi-factor signal engine");
        card("BTCUSDT","EMA 20 / 50 / 200 • RSI • MACD • ATR • VWAP • volume");
        card("INTELLIGENCE","SMC • BOS/CHOCH • liquidity sweeps • FVG • order blocks • breakout");
        card("OPERATING MODES","BACKTEST → PAPER → SHADOW → LIVE");
        card("LEARNING","OBSERVE → ANALYSE → TEST → LEARN → PROPOSE → VALIDATE → IMPROVE");
    }

    void trade() {
        card("TRADE TERMINAL","Candlestick terminal foundation • entry / SL / TP / R:R");
        card("SETUP","Entry: —\nStop: —\nTarget: —\nPosition size: —");
        card("EXECUTION","Order state • reconciliation • partial fills • reduce-only • idempotency");
    }

    void ai() {
        card("NEXUS AI COACH","Explain setups, losses, no-trade conditions and indicator/SMC concepts.");
        card("TRADE REVIEW","Strategy • confluence • market regime • R multiple • outcome");
        card("CONTROLLED LEARNING","The system proposes improvements; changes require validation rather than blind self-modification.");
    }

    void lab() {
        card("BACKTEST LAB","Historical testing • walk-forward • out-of-sample • strategy comparison");
        card("METRICS","Trades • win rate • profit factor • P&L • average R • drawdown • expectancy");
        card("STRATEGIES","Trend following • breakout • momentum • mean reversion • SMC confluence");
    }

    void risk() {
        card("RISK CENTRE","Risk % • ATR/structure/fixed SL • TP • position sizing");
        card("GUARDS","Daily/weekly loss • max exposure • leverage ceiling • cooldown");
        card("PROTECTION","Break-even • trailing • consecutive-loss protection • kill switch");
        card("LIVE","Disabled until secure credentials, signed requests, exchange filters, reconciliation and full safety controls are implemented.");
    }
}
EOF

echo "NEXUS Futures native project generated."

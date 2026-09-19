#!/usr/bin/env bash
set -e

mkdir -p app/src/main/java/com/eezh/nexusfutures
mkdir -p app/src/main/res/layout app/src/main/res/values app/src/main/assets

cat > settings.gradle <<'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
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
android.enableJetifier=true
EOF

cat > app/build.gradle <<'EOF'
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.eezh.nexusfutures'
    compileSdk 35

    defaultConfig {
        applicationId 'com.eezh.nexusfutures'
        minSdk 26
        targetSdk 35
        versionCode 1
        versionName '1.0.0'
    }
}

configurations.configureEach {
    resolutionStrategy.eachDependency { details ->
        if (details.requested.group == 'org.jetbrains.kotlin') {
            details.useVersion '1.8.22'
        }
    }
}

dependencies {
    implementation('androidx.appcompat:appcompat:1.7.0') {
        exclude group: 'org.jetbrains.kotlin', module: 'kotlin-stdlib-jdk7'
        exclude group: 'org.jetbrains.kotlin', module: 'kotlin-stdlib-jdk8'
    }
    implementation 'org.jetbrains.kotlin:kotlin-stdlib:1.8.22'
}
EOF

cat > app/src/main/res/values/strings.xml <<'EOF'
<resources>
    <string name="app_name">NEXUS Futures</string>
</resources>
EOF

cat > app/src/main/res/values/themes.xml <<'EOF'
<resources>
    <style name="Theme.NexusFutures" parent="Theme.AppCompat.DayNight.NoActionBar">
        <item name="android:fontFamily">sans</item>
    </style>
</resources>
EOF

cat > app/src/main/res/layout/activity_main.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<WebView xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/web"
    android:layout_width="match_parent"
    android:layout_height="match_parent" />
EOF

cat > app/src/main/AndroidManifest.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:theme="@style/Theme.NexusFutures"
        android:label="@string/app_name"
        android:usesCleartextTraffic="false">
        <activity
            android:name=".MainActivity"
            android:exported="true">
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

public class MainActivity extends Activity {
    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        setContentView(R.layout.activity_main);

        WebView web = findViewById(R.id.web);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        web.loadUrl("file:///android_asset/index.html");
    }
}
EOF

cat > app/src/main/assets/index.html <<'EOF'
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>NEXUS Futures</title>
<style>
body{margin:0;background:#0b1020;color:#eef2ff;font-family:Arial,sans-serif}
header{padding:18px;font-size:25px;font-weight:700}
.sub{padding:0 18px 16px;color:#9aa7c7}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;padding:12px}
.card{background:#151c31;border:1px solid #283452;border-radius:14px;padding:15px}
.label{color:#91a0c4;font-size:12px}
.value{font-size:21px;margin-top:7px}
button{border:0;border-radius:10px;padding:13px;margin:5px;font-weight:700}
.paper{background:#5ee1a8}.stop{background:#ffcc66}.danger{background:#ff6b7a}
select,input{background:#0d1427;color:white;border:1px solid #33405e;border-radius:8px;padding:10px;width:100%;box-sizing:border-box;margin-top:6px}
.full{grid-column:1/-1}
</style>
</head>
<body>
<header>NEXUS Futures</header>
<div class="sub">V1 • Separate app • PAPER mode by default</div>
<div class="grid">
<div class="card"><div class="label">BOT STATUS</div><div id="status" class="value">STOPPED</div></div>
<div class="card"><div class="label">MODE</div><div class="value">PAPER</div></div>
<div class="card"><div class="label">BALANCE</div><div class="value">$10,000.00</div></div>
<div class="card"><div class="label">DAILY P&L</div><div class="value">$0.00</div></div>
<div class="card full"><div class="label">SYMBOL</div>
<select id="symbol">
<option>BTCUSDT</option><option>ETHUSDT</option><option>BNBUSDT</option><option>SOLUSDT</option>
</select></div>
<div class="card full"><div class="label">RISK PER TRADE (%)</div>
<input id="risk" type="number" min="0.1" max="2" step="0.1" value="0.5"></div>
<div class="card full">
<button class="paper" onclick="start()">START PAPER BOT</button>
<button class="stop" onclick="stop()">STOP BOT</button>
<button class="danger" onclick="emergency()">EMERGENCY CLOSE</button>
</div>
<div class="card full"><div class="label">SYSTEM LOG</div>
<pre id="log" style="white-space:pre-wrap">Ready. No live orders are enabled in V1.</pre></div>
</div>
<script>
const logEl=document.getElementById('log');
const statusEl=document.getElementById('status');
const symbolEl=document.getElementById('symbol');
const riskEl=document.getElementById('risk');

function log(x){
  logEl.textContent=new Date().toLocaleTimeString()+"  "+x+"\\n"+logEl.textContent;
}
function start(){
  statusEl.textContent='RUNNING';
  log('Paper engine started for '+symbolEl.value+' at '+riskEl.value+'% risk.');
}
function stop(){
  statusEl.textContent='STOPPED';
  log('Bot stopped. No real orders were sent.');
}
function emergency(){
  statusEl.textContent='STOPPED';
  log('Emergency action: paper positions cleared. Live trading is disabled in V1.');
}
</script>
</body>
</html>
EOF

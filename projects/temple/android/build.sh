#!/bin/bash
# Temple — raw-toolchain APK build (same proven line as OctoLauncher 1.0.2).
set -e
P=~/workspace/church-apk/android
SDK=~/android-sdk
BT=$SDK/build-tools
AJAR=$SDK/platforms/android-36/android.jar
export JAVA_HOME=~/jdk17
export PATH=$JAVA_HOME/bin:$PATH
KOTLINC=~/kotlin/kotlinc/bin/kotlinc
STDLIB=~/kotlin/kotlinc/lib/kotlin-stdlib.jar
B=$P/build
KS=~/workspace/raveneye-apk/build/debug.keystore

# the one-file core rides inside as the app's only asset
cp ~/workspace/church-apk/prototype/index.html $P/app/src/main/assets/index.html

rm -rf $B
mkdir -p $B/gen $B/classes $B/dex

echo "== aapt2 compile"
$BT/aapt2 compile --dir $P/app/src/main/res -o $B/compiled_res.zip

echo "== aapt2 link"
$BT/aapt2 link -o $B/base.apk \
  -I $AJAR \
  --manifest $P/app/src/main/AndroidManifest.xml \
  --min-sdk-version 26 --target-sdk-version 36 \
  -A $P/app/src/main/assets \
  --java $B/gen \
  $B/compiled_res.zip

echo "== kotlinc"
$KOTLINC -jvm-target 1.8 -nowarn \
  -classpath $AJAR \
  -d $B/classes \
  $(find $P/app/src/main/java -name "*.kt")

echo "== d8"
$BT/d8 --lib $AJAR --min-api 26 --output $B/dex \
  $(find $B/classes -name "*.class") $STDLIB

echo "== package dex"
cp $B/base.apk $B/unsigned.apk
(cd $B/dex && zip -q ../unsigned.apk classes.dex)

echo "== zipalign"
$BT/zipalign -f 4 $B/unsigned.apk $B/aligned.apk

echo "== sign"
$BT/apksigner sign --ks $KS --ks-pass pass:android \
  --out $B/temple-1.0.apk $B/aligned.apk

echo "== verify"
$BT/apksigner verify --print-certs $B/temple-1.0.apk | head -4
ls -la $B/temple-1.0.apk

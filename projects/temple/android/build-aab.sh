#!/bin/bash
# Temple — App Bundle (.aab) build on the raw toolchain + bundletool.
# The upload key's password lives in upload-key-password.txt (600, never in this script).
set -e
P=~/workspace/church-apk/android
SDK=~/android-sdk
BT=$SDK/build-tools
AJAR=$SDK/platforms/android-36/android.jar
export JAVA_HOME=~/jdk17
export PATH=$JAVA_HOME/bin:$PATH
KOTLINC=~/kotlin/kotlinc/bin/kotlinc
STDLIB=~/kotlin/kotlinc/lib/kotlin-stdlib.jar
BUNDLETOOL=~/workspace/tools/bundletool/bundletool.jar
B=$P/build-aab
KS=$P/temple-upload.keystore
PWFILE=$P/upload-key-password.txt

cp ~/workspace/church-apk/prototype/index.html $P/app/src/main/assets/index.html

rm -rf $B
mkdir -p $B/gen $B/classes $B/dex $B/module

echo "== aapt2 compile"
$BT/aapt2 compile --dir $P/app/src/main/res -o $B/compiled_res.zip

echo "== aapt2 link (proto format for the bundle)"
$BT/aapt2 link -o $B/base-proto.apk \
  -I $AJAR \
  --manifest $P/app/src/main/AndroidManifest.xml \
  --min-sdk-version 26 --target-sdk-version 36 \
  --proto-format \
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
  $(find $B/classes -name "*.class") $STDLIB 2>/dev/null

echo "== assemble base module"
(cd $B/module && unzip -q -o ../base-proto.apk)
mkdir -p $B/module/manifest $B/module/dex
mv $B/module/AndroidManifest.xml $B/module/manifest/AndroidManifest.xml
cp $B/dex/classes.dex $B/module/dex/classes.dex
ls $B/module | grep -q "resources.pb" && ls $B/module/dex | grep -q "classes.dex" && ls $B/module/manifest | grep -q "AndroidManifest.xml"
(cd $B/module && zip -q -r ../base.zip .)

echo "== bundletool build-bundle"
java -jar $BUNDLETOOL build-bundle --modules=$B/base.zip --output=$B/temple-1.0.aab

echo "== upload key"
if [ ! -f "$KS" ]; then
  PW=$(openssl rand -base64 24 | tr -d '/+=\n' | head -c 20)
  printf '%s' "$PW" > $PWFILE && chmod 600 $PWFILE
  keytool -genkeypair -keystore $KS -alias temple-upload \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$PW" -keypass "$PW" \
    -dname "CN=Nathan Brown, OU=N8torious AI, O=N8torious AI, L=Akron, ST=Ohio, C=US" 2>/dev/null
  echo "upload keystore created"
fi
PW=$(cat $PWFILE)

echo "== sign the bundle (jarsigner — AABs are JAR-signed)"
jarsigner -keystore $KS -storepass "$PW" -keypass "$PW" \
  -signedjar $B/temple-1.0-signed.aab $B/temple-1.0.aab temple-upload
mv $B/temple-1.0-signed.aab $B/temple-1.0.aab

echo "== verify: bundletool validate"
java -jar $BUNDLETOOL validate --bundle=$B/temple-1.0.aab

echo "== verify: round-trip to a universal APK"
java -jar $BUNDLETOOL build-apks --bundle=$B/temple-1.0.aab \
  --output=$B/temple.apks --mode=universal \
  --ks=$KS --ks-pass=pass:"$PW" --ks-key-alias=temple-upload --key-pass=pass:"$PW"
mkdir -p $B/apks-out && (cd $B/apks-out && unzip -q -o ../temple.apks)
$BT/aapt dump badging $B/apks-out/universal.apk | head -3
unzip -l $B/apks-out/universal.apk | grep -E "classes.dex|assets/index.html"
jarsigner -verify $B/temple-1.0.aab > /dev/null && echo "AAB signature: VALID"
ls -la $B/temple-1.0.aab

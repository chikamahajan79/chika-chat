@echo off
setlocal

echo ===================================================
echo     Building and Signing Release APK for Chika
echo ===================================================

cd /d "%~dp0\..\app"

echo [1/4] Checking Flutter installation...
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter SDK not found in PATH.
    echo Please install Flutter and Android Studio SDK from: https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

echo [2/4] Generating Release Keystore if missing...
if not exist "android\app\upload-keystore.jks" (
    keytool -genkeypair -alias upload -keyalg RSA -keysize 2048 -validity 10000 -keystore android\app\upload-keystore.jks -storepass ChikaReleasePass2026 -keypass ChikaReleasePass2026 -dname "CN=Chetan, O=Chika, C=US, EMAIL=chetan@chetan.co"
    (
        echo storePassword=ChikaReleasePass2026
        echo keyPassword=ChikaReleasePass2026
        echo keyAlias=upload
        echo storeFile=upload-keystore.jks
    ) > android\key.properties
    echo Keystore created successfully!
)

echo [3/4] Fetching dependencies...
call flutter pub get

echo [4/4] Compiling signed Release APK and AAB...
call flutter build apk --release
call flutter build appbundle --release

echo ===================================================
echo BUILD COMPLETED!
echo Signed APK: app\build\app\outputs\flutter-apk\app-release.apk
echo Signed AAB: app\build\app\outputs\bundle\release\app-release.aab
echo ===================================================
pause

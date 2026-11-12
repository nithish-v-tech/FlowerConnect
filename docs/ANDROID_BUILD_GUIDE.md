# FlowerConnect Android APK Build Guide

This document provides instructions for compiling, testing, and generating Android APKs and App Bundles (AAB) for **FlowerConnect**.

---

## 1. Prerequisites

- Flutter SDK 3.24+ (Dart 3.5+)
- Android Studio / Android SDK (API Level 34 / Android 14 recommended)
- Java Development Kit (JDK 17)

Verify your environment:
```bash
flutter doctor
```

---

## 2. Generating a Debug APK

Debug APKs are ideal for testing directly on physical devices or emulators.

1. Navigate to the mobile directory:
   ```bash
   cd "e:\FLOWER CONNECT\mobile"
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Build the debug APK:
   ```bash
   flutter build apk --debug
   ```
4. Output file location:
   ```
   mobile/build/app/outputs/flutter-apk/app-debug.apk
   ```

---

## 3. Generating a Release APK

### Step 1: Create a Production Keystore
Generate a signing keystore (run in terminal):
```bash
keytool -genkey -v -keystore flowerconnect-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias flowerconnect
```

### Step 2: Configure `key.properties`
Create `mobile/android/key.properties`:
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=flowerconnect
storeFile=../flowerconnect-release.jks
```

### Step 3: Configure `android/app/build.gradle`
Ensure `build.gradle` references your signing configuration:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Step 4: Build Split-per-ABI or Fat Release APK
Build standard release APK:
```bash
flutter build apk --release
```

Build split APKs (smaller file size for arm64-v8a, armeabi-v7a):
```bash
flutter build apk --split-per-abi
```

Build Android App Bundle (for Google Play Store upload):
```bash
flutter build appbundle --release
```

Output file location:
```
mobile/build/app/outputs/flutter-apk/app-release.apk
mobile/build/app/outputs/bundle/release/app-release.aab
```

---

## 4. Installing Directly to Connected Device

With your Android device connected via USB with Developer Options & USB Debugging enabled:
```bash
cd mobile
flutter run --release
# or install APK via ADB:
adb install build/app/outputs/flutter-apk/app-release.apk
```


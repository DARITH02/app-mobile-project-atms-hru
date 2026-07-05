# HRU ATMS Android APK Release Guide

This guide explains how to build an Android APK for the HRU ATMS Flutter app.

Project path:

```powershell
D:\Coding\Mobile HRU\hru_atms
```

Android app id:

```text
com.hru.atms
```

## 1. Choose Build Type

Use a debug APK when you only want to test on your phone.

Use a release APK when you want to share the app with real users or upload it for distribution.

## 2. Build Debug APK

Debug APK does not need release signing.

```powershell
cd "D:\Coding\Mobile HRU\hru_atms"
flutter pub get
flutter build apk --debug
```

Output:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## 3. Prepare Release Signing

Release APK needs a signing key. Create it one time only.

```powershell
cd "D:\Coding\Mobile HRU\hru_atms\android"
keytool -genkey -v -keystore app-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias hru-atms
```

Use values like this:

```text
First and last name: HRU ATMS
Organizational unit: HRU
Organization: HRU
City: Phnom Penh
State: Phnom Penh
Country code: KH
```

Keep the password safe. You need the same key for future app updates.

## 4. Create key.properties

Create this file:

```text
android\key.properties
```

Use `android\key.properties.example` as the template:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=hru-atms
storeFile=app-release-key.jks
```

Do not commit this file. The project already ignores:

```text
android/key.properties
*.jks
```

## 5. Set Backend API URL

If your backend is local only, use your computer LAN IP:

```powershell
--dart-define=API_BASE_URL=http://192.168.18.2:8080/api
```

The phone must be on the same Wi-Fi as the backend computer.

For real public users, use a cloud HTTPS API:

```powershell
--dart-define=API_BASE_URL=https://your-domain.com/api
```

## 6. Build Release APK

Local Wi-Fi backend example:

```powershell
cd "D:\Coding\Mobile HRU\hru_atms"
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.18.2:8080/api
```

Cloud backend example:

```powershell
cd "D:\Coding\Mobile HRU\hru_atms"
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://your-domain.com/api
```

Output:

```text
build\app\outputs\flutter-apk\app-release.apk
```

## 7. Build App Bundle for Play Store

Google Play usually prefers AAB instead of APK.

```powershell
cd "D:\Coding\Mobile HRU\hru_atms"
flutter build appbundle --release --dart-define=API_BASE_URL=https://your-domain.com/api
```

Output:

```text
build\app\outputs\bundle\release\app-release.aab
```

## 8. Install APK on Phone

Connect Android phone with USB debugging enabled:

```powershell
flutter devices
flutter install
```

Or copy the APK to the phone and open it. Android may ask you to allow installing unknown apps.

## 9. Common Warnings

If you see this warning:

```text
Your app uses plugins that apply Kotlin Gradle Plugin: mobile_scanner
```

It is a warning for future Flutter/Gradle versions. If the build ends with:

```text
Built build\app\outputs\flutter-apk\app-release.apk
```

then the APK was built successfully.

## 10. Release Checklist

Before sharing the APK:

- `android\key.properties` exists.
- `android\app-release-key.jks` exists.
- Passwords are saved somewhere private.
- `API_BASE_URL` points to the correct backend.
- Phone can reach the backend URL.
- App id is `com.hru.atms`.
- Version in `pubspec.yaml` is updated before each public release.

Example version:

```yaml
version: 1.0.1+2
```

Android uses:

```text
1.0.1 = versionName
2 = versionCode
```

Increase `versionCode` for every release.

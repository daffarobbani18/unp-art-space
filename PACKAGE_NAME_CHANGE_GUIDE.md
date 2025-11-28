# 📦 Package Name Change Guide

## Overview

This guide will help you change the Android package name from `com.example.project1` to `com.campus.artspace`.

> ⚠️ **WARNING**: This is a critical operation. Make sure to backup your project and test thoroughly after changes.

---

## 🎯 What Will Be Changed

- ✅ Android package identifier (`applicationId`)
- ✅ Kotlin/Java package structure and folder hierarchy
- ✅ AndroidManifest.xml package declarations
- ✅ Supabase Authentication settings
- ✅ Deep linking configurations (if applicable)

---

## 📋 Step-by-Step Instructions

### 1️⃣ Update Android Build Configuration

**File:** `android/app/build.gradle.kts`

Find the `applicationId` line and change it:

```kotlin
android {
    namespace = "com.campus.artspace"  // Change this
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.campus.artspace"  // Change this
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInteger()
        versionName = flutterVersionName
    }
    // ...
}
```

**Changes:**
- Line ~6: `namespace = "com.campus.artspace"`
- Line ~11: `applicationId = "com.campus.artspace"`

---

### 2️⃣ Update AndroidManifest.xml

**File:** `android/app/src/main/AndroidManifest.xml`

Change the `package` attribute (if present) at the top:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.campus.artspace">
    
    <!-- No other changes needed here -->
    <application
        android:label="Campus Art Space"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ... -->
    </application>
</manifest>
```

---

### 3️⃣ Rename Kotlin/Java Package Structure

**Current Structure:**
```
android/app/src/main/kotlin/com/example/project1/MainActivity.kt
```

**New Structure:**
```
android/app/src/main/kotlin/com/campus/artspace/MainActivity.kt
```

#### Steps to Rename:

1. **Navigate to the kotlin folder:**
   ```powershell
   cd android\app\src\main\kotlin
   ```

2. **Create new folder structure:**
   ```powershell
   New-Item -ItemType Directory -Path "com\campus\artspace" -Force
   ```

3. **Move MainActivity.kt to new location:**
   ```powershell
   Move-Item -Path "com\example\project1\MainActivity.kt" -Destination "com\campus\artspace\MainActivity.kt"
   ```

4. **Delete old folder structure:**
   ```powershell
   Remove-Item -Path "com\example" -Recurse -Force
   ```

5. **Update MainActivity.kt package declaration:**

   **File:** `android/app/src/main/kotlin/com/campus/artspace/MainActivity.kt`

   ```kotlin
   package com.campus.artspace  // Change this line

   import io.flutter.embedding.android.FlutterActivity

   class MainActivity: FlutterActivity() {
       // No other changes needed
   }
   ```

---

### 4️⃣ Clean Build Artifacts

After making these changes, clean all build artifacts:

```powershell
# Navigate to project root
cd d:\Mobile\unp-art-space-mobile

# Clean Flutter build
flutter clean

# Clean Android build
cd android
.\gradlew clean

# Return to project root
cd ..

# Get dependencies
flutter pub get
```

---

### 5️⃣ Test the Build

Build the app to verify everything works:

```powershell
# Build debug APK to test
flutter build apk --debug

# Or run directly on device/emulator
flutter run
```

**Expected Output:**
```
✓ Built build\app\outputs\flutter-apk\app-debug.apk
```

If you see errors, check the error messages carefully and verify all package names are correct.

---

## 🔐 Supabase Reconfiguration

After changing the package name, you need to update Supabase Authentication settings.

### 6️⃣ Update Supabase Dashboard Settings

1. **Login to Supabase Dashboard:**
   - Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
   - Select your project: `vepmvxiddwmpetxfdwjn`

2. **Navigate to Authentication Settings:**
   - Click **Authentication** in the left sidebar
   - Click **URL Configuration** tab

3. **Update Redirect URLs (if using OAuth):**
   
   If you have deep linking or OAuth configured, update these URLs:
   
   **Old URLs to Remove:**
   ```
   com.example.project1://callback
   com.example.project1://login-callback
   ```
   
   **New URLs to Add:**
   ```
   com.campus.artspace://callback
   com.campus.artspace://login-callback
   ```

4. **Update Site URL (if needed):**
   - Usually this is your web app URL
   - Only change if you're using package-specific configurations

5. **Check Deep Link Configuration:**
   - Go to **Project Settings** → **API**
   - Verify that no package-specific configurations exist
   - If they do, update them to use `com.campus.artspace`

---

## 🧪 Testing Checklist

After completing all changes, test these critical features:

### ✅ Authentication Flow
- [ ] User can register with email/password
- [ ] Email verification works
- [ ] User can login successfully
- [ ] User can logout and login again
- [ ] Password reset flow works (if implemented)

### ✅ File Upload
- [ ] Image upload works (Supabase Storage)
- [ ] Video upload works
- [ ] Files are accessible after upload

### ✅ Deep Links (if applicable)
- [ ] Deep links open the app correctly
- [ ] Deep links navigate to correct screens

### ✅ App Installation
- [ ] App installs successfully on device
- [ ] App icon displays correctly
- [ ] App name shows as "Campus Art Space"
- [ ] No conflicts with old package (old version uninstalled)

---

## ⚠️ Common Issues & Solutions

### Issue 1: "Duplicate class" or "Conflict" errors

**Solution:** Clean build artifacts completely
```powershell
flutter clean
cd android
.\gradlew clean
cd ..
flutter pub get
```

### Issue 2: MainActivity.kt not found

**Solution:** Verify the file is in the correct location:
```
android/app/src/main/kotlin/com/campus/artspace/MainActivity.kt
```

And the package declaration matches:
```kotlin
package com.campus.artspace
```

### Issue 3: Login not working after package change

**Solution:** 
1. Clear app data on device
2. Uninstall old app version
3. Verify Supabase redirect URLs are updated
4. Rebuild and reinstall app

### Issue 4: "Application not installed" error

**Solution:**
1. Uninstall any existing version of the app with old package name
2. Restart your device/emulator
3. Rebuild and reinstall

---

## 🔄 Rollback Plan (If Something Goes Wrong)

If you encounter critical issues and need to rollback:

1. **Revert Git Changes:**
   ```powershell
   git checkout android/app/build.gradle.kts
   git checkout android/app/src/main/AndroidManifest.xml
   git checkout android/app/src/main/kotlin
   ```

2. **Restore Old Package Structure:**
   - Manually rename folders back to `com/example/project1`
   - Update `MainActivity.kt` package declaration back to `com.example.project1`

3. **Clean and Rebuild:**
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 📝 Notes for iOS (Future)

If you want to change the iOS bundle identifier in the future:

1. Open `ios/Runner.xcodeproj` in Xcode
2. Select "Runner" target
3. In "General" tab, change "Bundle Identifier" to `com.campus.artspace`
4. Update `Info.plist` if needed

---

## ✅ Final Verification

After completing all steps, verify:

- [ ] ✅ README.md updated (already done)
- [ ] ✅ App builds successfully
- [ ] ✅ App installs on device
- [ ] ✅ Login/Registration works
- [ ] ✅ File uploads work
- [ ] ✅ No Supabase authentication errors
- [ ] ✅ All features tested and working
- [ ] ✅ Git changes committed

---

## 🚀 Commit Your Changes

Once everything is tested and working:

```powershell
# Stage all changes
git add -A

# Commit with descriptive message
git commit -m "refactor: change Android package name from com.example.project1 to com.campus.artspace

- Updated applicationId in build.gradle.kts
- Renamed Kotlin package structure
- Updated AndroidManifest.xml package declaration
- Updated MainActivity.kt package
- Updated Supabase authentication configuration
- Tested all authentication and file upload flows"

# Push to both remotes
git push origin main
git push azure main
```

---

## 📞 Need Help?

If you encounter issues not covered in this guide:

1. Check Flutter documentation: [https://docs.flutter.dev](https://docs.flutter.dev)
2. Check Android package rename guides
3. Review Supabase authentication documentation
4. Create an issue on GitHub if needed

---

<div align="center">

**Good luck with your package name change! 🎉**

</div>

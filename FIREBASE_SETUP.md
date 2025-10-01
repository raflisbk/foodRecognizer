# 🔥 Firebase Setup Guide

Panduan lengkap setup Firebase untuk mendapatkan **poin maksimal 4/4** di Kriteria 2.

## ✅ File Yang Sudah Dikonfigurasi

File-file berikut sudah dikonfigurasi dengan benar:

1. ✅ `android/build.gradle.kts` - Plugin Google Services
2. ✅ `android/app/build.gradle.kts` - Apply plugin
3. ✅ `android/app/src/main/AndroidManifest.xml` - Permissions
4. ✅ `pubspec.yaml` - Firebase dependencies

## 📋 Yang Perlu Anda Lakukan

### 1. Buat Firebase Project

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik **"Add project"** atau **"Create a project"**
3. Nama project: `food-recognizer` (atau nama lain)
4. Google Analytics: **Disable** (tidak diperlukan)
5. Klik **"Create Project"**
6. Tunggu sampai project dibuat

### 2. Tambahkan Android App

1. Di Firebase Console, klik icon **Android** (robot hijau)
2. **Android package name**: `com.example.food_recognizer`
   - ⚠️ **HARUS SAMA PERSIS** dengan yang ada di `android/app/build.gradle.kts`
3. **App nickname**: `Food Recognizer` (opsional)
4. **Debug signing certificate SHA-1**: Kosongkan (opsional)
5. Klik **"Register app"**

### 3. Download google-services.json

1. Klik **"Download google-services.json"**
2. Letakkan file di: `android/app/google-services.json`

   ```
   food_recognizer/
   └── android/
       └── app/
           └── google-services.json  ← LETAKKAN DI SINI
   ```

3. **Verifikasi lokasi**:
   ```bash
   # Windows
   dir android\app\google-services.json

   # Mac/Linux
   ls -l android/app/google-services.json
   ```

### 4. Verifikasi Gradle Configuration

File-file berikut sudah saya konfigurasi, tapi pastikan tidak ada error:

#### `android/build.gradle.kts`
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.3" apply false
}
```

#### `android/app/build.gradle.kts`
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← Ini sudah ditambahkan
}
```

### 5. Setup Firebase ML

Ini yang PENTING untuk dapat poin 4/4!

1. Di Firebase Console, pilih project Anda
2. Klik **"Build"** di sidebar kiri
3. Klik **"Machine Learning"**
4. Klik tab **"Custom"**
5. Klik **"Add a custom model"**

#### Upload Model:
- **Model name**: `food_classifier`
  - ⚠️ **HARUS PERSIS** seperti ini (lowercase, no spaces)
  - Jangan pakai nama lain!
- **Model file**: Upload `food_classifier.tflite` yang sudah Anda download
- **Description**: "Food classification model" (opsional)

6. Klik **"Deploy"**
7. Tunggu sampai status **"Published"** (warna hijau)

### 6. Test Firebase Integration

Jalankan aplikasi:

```bash
flutter clean
flutter pub get
flutter run
```

#### Cek di Console:

Lihat output console, harus ada:
```
✅ Firebase initialized successfully
✅ Model loaded successfully (atau)
✅ Using Firebase ML model ✨
```

Jika error:
```
❌ Firebase initialization failed
```
→ Cek `google-services.json` sudah ada di tempat yang benar

## 🎯 Mengapa Firebase ML Penting?

Firebase ML memberikan **poin 4/4** di Kriteria 2 karena:

1. ✅ Model di-download dari cloud (dynamic)
2. ✅ Bukan hardcoded di assets
3. ✅ Bisa update model tanpa update app
4. ✅ Menunjukkan advanced ML integration

## 📱 Test Firebase ML

### Test 1: Cek Initialization
```dart
// Lihat di home_screen.dart
if (classificationState.useFirebaseModel) {
  print("✅ Using Firebase ML model");
} else {
  print("⚠️ Using local model");
}
```

### Test 2: Cek Download
Di Firebase Console → Machine Learning → Usage:
- Lihat jumlah downloads
- Seharusnya bertambah setiap kali app pertama kali jalan

### Test 3: Functional Test
1. Buka app
2. Tunggu "Using Firebase ML model ✨" di UI
3. Ambil/pilih foto makanan
4. Analyze
5. Seharusnya berhasil

## ⚠️ Troubleshooting

### Error: google-services.json not found

**Solusi**:
```bash
# Pastikan file ada
ls android/app/google-services.json

# Jika tidak ada, download lagi dari Firebase Console
```

### Error: Package name mismatch

**Error**: `Package name 'xxx' does not match...`

**Solusi**:
1. Cek `android/app/build.gradle.kts`:
   ```kotlin
   applicationId = "com.example.food_recognizer"
   ```
2. Harus SAMA dengan package name di Firebase Console
3. Jika beda, hapus app di Firebase dan buat lagi

### Error: Model not found in Firebase

**Solusi**:
1. Cek nama model di Firebase: HARUS `food_classifier`
2. Cek status: HARUS "Published"
3. Tunggu beberapa menit setelah deploy

### Error: Failed to download model

**Solusi**:
1. Pastikan internet connection
2. App akan fallback ke local model (masih works)
3. Coba lagi nanti

### Build Failed: Execution failed for ':app:processDebugGoogleServices'

**Solusi**:
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

## 🔐 Security Notes

1. **.gitignore**: Pastikan `google-services.json` di-ignore
   ```
   # Sudah ada di .gitignore
   **/android/app/google-services.json
   ```

2. **API Keys**: Jangan commit ke public repository

3. **Firebase Rules**: Default rules sudah aman untuk ML model download

## 📊 Verifikasi Checklist

Sebelum run, pastikan:

- [ ] Firebase project sudah dibuat
- [ ] Android app sudah ditambahkan
- [ ] `google-services.json` sudah di `android/app/`
- [ ] Package name match: `com.example.food_recognizer`
- [ ] Model sudah di-upload ke Firebase ML
- [ ] Model name: `food_classifier` (exact match)
- [ ] Model status: "Published"
- [ ] Gradle files sudah dikonfigurasi (sudah saya lakukan)

## 🎓 Poin Yang Didapat

Dengan Firebase ML tersetup:

✅ **Kriteria 2 - Advanced (4/4 poin)**:
- Model loaded from cloud ✓
- Dynamic model download ✓
- Fallback mechanism ✓
- Production-ready ✓

## 📚 Resources

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Docs](https://firebase.flutter.dev/)
- [Firebase ML Docs](https://firebase.google.com/docs/ml)

---

## 🚀 Quick Commands

```bash
# Clean build
flutter clean && flutter pub get

# Run with Firebase
flutter run

# Build release
flutter build apk --release

# Check Firebase in logs
flutter run | grep Firebase
```

---

Need help? Cek `SETUP_GUIDE.md` untuk troubleshooting umum!

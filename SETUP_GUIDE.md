# 📖 Setup Guide - Food Recognizer App

Panduan lengkap untuk setup aplikasi Food Recognizer.

## 📋 Prerequisites

- Flutter SDK 3.9.2 atau lebih baru
- Android Studio / VS Code dengan Flutter plugin
- Android device/emulator dengan API level 21+
- iOS device/simulator (untuk iOS)
- Koneksi internet

## 🚀 Quick Start

### 1. Clone dan Install Dependencies

```bash
cd food_recognizer
flutter pub get
```

### 2. Download Model TensorFlow Lite

**PENTING**: Model harus didownload sebelum menjalankan aplikasi!

1. Download model dari: [food_classifier.tflite](https://github.com/Dicoding/a663-machine-learning-terapan/raw/main/Proyek_Akhir/food_classifier.tflite)

2. Letakkan file di:
   ```
   food_recognizer/
   └── assets/
       └── models/
           └── food_classifier.tflite
   ```

3. Verifikasi file sudah ada:
   ```bash
   # Windows
   dir assets\models\food_classifier.tflite

   # Linux/Mac
   ls -l assets/models/food_classifier.tflite
   ```

### 3. Setup Gemini API Key

1. Dapatkan API key gratis dari: https://makersuite.google.com/app/apikey

2. Buka file: `lib/constants/api_constants.dart`

3. Ganti baris ini:
   ```dart
   static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
   ```

   Menjadi:
   ```dart
   static const String geminiApiKey = 'AIza...'; // API key Anda
   ```

### 4. Setup Firebase (Optional - untuk poin maksimal)

Firebase diperlukan untuk mendapat poin 4/4 di Kriteria 2.

#### 4.1 Buat Firebase Project

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik "Add Project"
3. Nama project: `food-recognizer` (atau nama lain)
4. Nonaktifkan Google Analytics (optional)
5. Klik "Create Project"

#### 4.2 Setup untuk Android

1. Di Firebase Console, klik icon Android
2. Package name: `com.example.food_recognizer`
3. App nickname: `Food Recognizer`
4. Klik "Register app"
5. Download `google-services.json`
6. Letakkan file di: `android/app/google-services.json`

7. Edit `android/build.gradle.kts`:
   ```kotlin
   buildscript {
       dependencies {
           classpath("com.google.gms:google-services:4.4.0")
       }
   }
   ```

8. Edit `android/app/build.gradle.kts`, tambahkan di paling bawah:
   ```kotlin
   apply(plugin = "com.google.gms.google-services")
   ```

#### 4.3 Setup untuk iOS (Optional)

1. Di Firebase Console, klik icon iOS
2. Bundle ID: `com.example.foodRecognizer`
3. Download `GoogleService-Info.plist`
4. Letakkan di: `ios/Runner/GoogleService-Info.plist`
5. Jalankan:
   ```bash
   cd ios
   pod install
   cd ..
   ```

#### 4.4 Upload Model ke Firebase ML

1. Di Firebase Console, pilih project Anda
2. Klik "Machine Learning" di sidebar
3. Klik "Custom" tab
4. Klik "Add a custom model"
5. Model name: `food_classifier` (HARUS SAMA!)
6. Upload file: `food_classifier.tflite`
7. Klik "Deploy"

**PENTING**:
- Model name HARUS `food_classifier` (sesuai dengan `api_constants.dart`)
- Tunggu hingga status "Published"

### 5. Run Aplikasi

```bash
flutter run
```

Atau pilih device di VS Code/Android Studio dan tekan F5.

## 🔍 Verifikasi Setup

### Checklist Setup

- [ ] Dependencies terinstall (`flutter pub get` sukses)
- [ ] File `assets/models/food_classifier.tflite` ada
- [ ] File `assets/labels/labels.txt` ada
- [ ] Gemini API key sudah diisi
- [ ] Android permissions sudah ditambahkan
- [ ] Firebase sudah setup (optional)
- [ ] App bisa build tanpa error

### Test Fitur

1. **Test Image Picker**:
   - Buka app
   - Tap "Choose from Gallery"
   - Pilih gambar
   - Seharusnya muncul preview gambar

2. **Test Camera**:
   - Tap "Take a Photo"
   - Izinkan akses kamera
   - Ambil foto
   - Seharusnya muncul preview

3. **Test Crop**:
   - Setelah pilih/ambil foto
   - Tap icon crop di app bar
   - Crop gambar
   - Seharusnya gambar ter-update

4. **Test Classification**:
   - Tap "Analyze Food"
   - Tunggu proses (2-5 detik)
   - Seharusnya muncul hasil prediksi

5. **Test Camera Stream**:
   - Dari home, tap "Live Camera Detection"
   - Arahkan kamera ke makanan
   - Seharusnya real-time mendeteksi

6. **Test MealDB API**:
   - Setelah analyze food
   - Scroll ke bawah
   - Seharusnya muncul resep terkait

7. **Test Gemini API**:
   - Setelah analyze food
   - Lihat section "Nutritional Information"
   - Seharusnya muncul kalori, protein, dll

## ⚠️ Troubleshooting

### Model tidak ditemukan

**Error**: `Unable to load asset: assets/models/food_classifier.tflite`

**Solusi**:
```bash
# Pastikan file ada
ls assets/models/food_classifier.tflite

# Jika tidak ada, download lagi
# Pastikan nama file PERSIS: food_classifier.tflite (lowercase)
```

### Firebase initialization failed

**Error**: `FirebaseException: No Firebase App '[DEFAULT]' has been created`

**Solusi**:
- Pastikan `google-services.json` (Android) atau `GoogleService-Info.plist` (iOS) ada
- Clean dan rebuild:
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```

### Gemini API error

**Error**: `API key not valid`

**Solusi**:
- Cek API key di https://makersuite.google.com/app/apikey
- Generate key baru jika perlu
- Pastikan tidak ada spasi di depan/belakang key
- Update file `api_constants.dart`

### Camera permission denied

**Error**: `Camera permission denied`

**Solusi Android**:
- Buka Settings → Apps → Food Recognizer → Permissions
- Izinkan Camera
- Restart app

**Solusi iOS**:
- Pastikan `Info.plist` sudah ada NSCameraUsageDescription
- Uninstall app
- Install ulang

### TensorFlow Lite error

**Error**: `Failed to load model`

**Solusi**:
1. Cek ukuran file model (harus ~15-20 MB)
2. Download ulang model jika corrupt
3. Pastikan format file .tflite (bukan .zip atau .h5)

### Out of memory

**Error**: `OutOfMemoryError`

**Solusi**:
- Gunakan device dengan RAM lebih besar
- Tutup aplikasi lain
- Restart device

### Gradle sync failed (Android)

**Error**: `Could not resolve com.google.gms:google-services`

**Solusi**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

## 📱 Platform-Specific Notes

### Android

**Minimum SDK**: 21 (Android 5.0 Lollipop)

**Dependencies**:
- Google Services
- Firebase
- Camera2 API

**Build**:
```bash
flutter build apk --release
```

### iOS

**Minimum iOS**: 11.0

**Dependencies**:
- CocoaPods
- Firebase iOS SDK

**Build**:
```bash
flutter build ios --release
```

## 🔐 Security Notes

1. **API Keys**:
   - JANGAN commit API keys ke Git
   - Gunakan environment variables untuk production
   - Rotate keys secara berkala

2. **Permissions**:
   - Request permissions di runtime
   - Jelaskan kenapa perlu permission
   - Handle permission denied gracefully

## 📊 Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test integration_test/
```

### Manual Testing

Gunakan checklist di atas untuk testing manual.

## 🎯 Submission Checklist

Sebelum submit, pastikan:

- [ ] Semua kriteria terpenuhi (12/12 poin)
- [ ] Model ML sudah include atau ada instruksi download
- [ ] Firebase sudah setup (google-services.json ada)
- [ ] API keys sudah diisi atau ada instruksi
- [ ] App bisa build tanpa error
- [ ] Semua fitur sudah di-test
- [ ] README.md jelas dan lengkap
- [ ] Screenshot/video demo tersedia

## 📞 Support

Jika masih ada masalah:

1. Cek error message di console
2. Baca dokumentasi Flutter: https://flutter.dev/docs
3. Cek issue di repository
4. Tanya di forum Dicoding

## 🎓 Learning Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [TensorFlow Lite Flutter](https://www.tensorflow.org/lite/guide/flutter)
- [Firebase Flutter](https://firebase.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)

---

Good luck! 🚀

# Testing & Monitoring - Food Recognizer App

## 📋 Ringkasan Testing yang Ditambahkan

### 1. **Unit Tests untuk Services** (2 file)

#### `test/services/image_classification_service_test.dart`
Testing untuk service klasifikasi gambar dengan TensorFlow Lite:
- ✅ **initialize** - Memastikan model berhasil diinisialisasi
- ✅ **initialize with Firebase model** - Testing dengan model dari Firebase ML
- ✅ **classifyImage with invalid data** - Handle gambar invalid
- ✅ **classifyImage with valid data** - Prediksi berhasil dengan data valid
- ✅ **error handling** - Menangani berbagai jenis error
- ✅ **dispose** - Cleanup resources dengan benar

**Total: 8 test cases**

#### `test/services/firebase_ml_service_test.dart`
Testing untuk Firebase ML Model Downloader:
- ✅ **downloadModel** - Download model dari Firebase
- ✅ **handle missing Firebase** - Fallback jika Firebase tidak ada
- ✅ **network error handling** - Handle error jaringan
- ✅ **timeout handling** - Handle timeout

**Total: 4 test cases**

---

### 2. **Unit Tests untuk Providers** (2 file)

#### `test/providers/classification_provider_test.dart`
Testing state management untuk klasifikasi dengan Riverpod:
- ✅ **initial state** - State awal provider benar
- ✅ **initialize loading** - Loading state saat inisialisasi
- ✅ **initialize success** - Model berhasil dimuat
- ✅ **initialize with Firebase model** - Menggunakan Firebase model
- ✅ **initialize error** - Handle error inisialisasi
- ✅ **classifyImage loading** - Loading state saat klasifikasi
- ✅ **classifyImage success** - Prediksi berhasil dengan FoodPrediction
- ✅ **classifyImage null result** - Handle hasil null
- ✅ **classifyImage error** - Handle error klasifikasi
- ✅ **clearPrediction** - Clear state prediksi
- ✅ **clearError** - Clear state error

**Total: 12 test cases** (with Firebase mock setup)

#### `test/providers/camera_provider_test.dart`
Testing state management untuk kamera dan image picker:
- ✅ **initial state** - State awal provider benar
- ✅ **initialize camera success** - Kamera berhasil diinisialisasi
- ✅ **initialize camera failure** - Handle kamera gagal
- ✅ **initialize error** - Handle error inisialisasi
- ✅ **takePicture success** - Foto berhasil diambil
- ✅ **takePicture null result** - Handle user cancel
- ✅ **takePicture error** - Handle error pengambilan foto
- ✅ **toggleFlash** - Toggle flash on/off
- ✅ **switchCamera** - Switch antara front/back camera
- ✅ **clearImage** - Clear captured image
- ✅ **clearError** - Clear error state

**Total: 11 test cases**

---

### 3. **Widget Tests untuk UI** (1 file)

#### `test/widgets/home_screen_test.dart`
Testing UI components dari HomeScreen:
- ✅ **display app title** - Title "Food Recognizer" ditampilkan
- ✅ **display logo icon** - Icon restaurant ditampilkan
- ✅ **display welcome text** - Text "Selamat Datang" ditampilkan
- ✅ **display instruction text** - Instruksi untuk user ditampilkan
- ✅ **camera button exists** - Tombol kamera tersedia
- ✅ **gallery button exists** - Tombol galeri tersedia
- ✅ **loading state** - UI loading saat inisialisasi
- ✅ **error state** - UI error ditampilkan dengan benar
- ✅ **correct theme colors** - Material Design 3 colors benar
- ✅ **camera button tappable** - Tombol kamera dapat ditekan
- ✅ **gallery button tappable** - Tombol galeri dapat ditekan

**Total: 10 test cases**

---

## 📊 Total Testing Coverage

| Kategori | Jumlah File | Jumlah Test Cases |
|----------|-------------|-------------------|
| Service Tests | 2 | 12 |
| Provider Tests | 2 | 23 |
| Widget Tests | 1 | 10 |
| **TOTAL** | **5** | **45 test cases** |

---

## 🔥 Firebase Monitoring yang Ditambahkan

### 1. **Firebase Crashlytics** (`lib/main.dart:18-24`)
Automatic crash reporting untuk monitoring error di production:
```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

**Fungsi:**
- ✅ Otomatis melacak crash dan error fatal
- ✅ Mengirim stack trace ke Firebase Console
- ✅ Monitoring real-time error di production

---

### 2. **Firebase Analytics Events** (4 event types)

#### Event 1: `model_initialized` (`classification_provider.dart:98-104`)
Tracking saat model AI berhasil dimuat:
```dart
await _analytics.logEvent(
  name: 'model_initialized',
  parameters: {
    'model_source': useFirebaseModel ? 'firebase' : 'local',
    'model_path': modelPath ?? 'local_asset',
  },
);
```

**Parameter:**
- `model_source`: firebase / local
- `model_path`: path file model

---

#### Event 2: `food_classified` (`classification_provider.dart:169-176`)
Tracking saat makanan berhasil dikenali:
```dart
await _analytics.logEvent(
  name: 'food_classified',
  parameters: {
    'food_label': prediction.label,
    'confidence': (prediction.confidence * 100).toStringAsFixed(2),
    'high_confidence': prediction.confidence >= 0.8,
  },
);
```

**Parameter:**
- `food_label`: Nama makanan yang terdeteksi
- `confidence`: Tingkat keyakinan (0-100%)
- `high_confidence`: true jika confidence >= 80%

---

#### Event 3: `image_selected` (`camera_provider.dart:176-182, 275-281`)
Tracking saat user memilih gambar dari galeri atau kamera:
```dart
await _analytics.logEvent(
  name: 'image_selected',
  parameters: {
    'source': 'gallery', // atau 'camera'
    'file_size_kb': (fileSize / 1024).toStringAsFixed(2),
  },
);
```

**Parameter:**
- `source`: gallery / camera
- `file_size_kb`: Ukuran file dalam KB

---

#### Event 4: `image_cropped` (`camera_provider.dart:347-350`)
Tracking saat user melakukan crop gambar:
```dart
await _analytics.logEvent(
  name: 'image_cropped',
  parameters: {'success': true},
);
```

**Parameter:**
- `success`: true (berhasil crop)

---

## 🚀 Cara Menjalankan Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/services/image_classification_service_test.dart
```

### Run Tests dengan Coverage
```bash
flutter test --coverage
```

### Generate Coverage Report (HTML)
```bash
genhtml coverage/lcov.info -o coverage/html
```

---

## 📦 Dependencies Testing

Package yang ditambahkan untuk testing:

### Dev Dependencies (`pubspec.yaml`)
```yaml
dev_dependencies:
  mockito: ^5.5.1           # Mocking untuk unit tests
  build_runner: ^2.8.0      # Code generation untuk mocks
```

### Production Dependencies
```yaml
dependencies:
  firebase_crashlytics: ^4.3.10    # Crash reporting
  firebase_analytics: ^11.6.0      # User behavior tracking
```

---

## 🎯 Manfaat Testing & Monitoring

### Testing Benefits:
1. ✅ **Confidence** - Yakin kode berfungsi dengan benar
2. ✅ **Regression Prevention** - Mencegah bug lama muncul kembali
3. ✅ **Documentation** - Test sebagai dokumentasi cara kerja kode
4. ✅ **Refactoring Safety** - Aman untuk refactor kode
5. ✅ **Bug Detection** - Menemukan bug lebih awal

### Monitoring Benefits:
1. ✅ **Production Insights** - Mengetahui cara user menggunakan app
2. ✅ **Error Tracking** - Deteksi error di production secara real-time
3. ✅ **Performance Metrics** - Tracking performa aplikasi
4. ✅ **User Behavior** - Memahami pattern penggunaan
5. ✅ **Data-Driven Decisions** - Keputusan berdasarkan data

---

## 📝 Catatan Penting

### Testing:
- Semua test menggunakan **mockito** untuk mocking dependencies
- Provider tests menggunakan **Firebase mock** untuk menghindari error Firebase di test environment
- Widget tests menggunakan **Material Design 3** theme
- Test coverage mencakup **happy path** dan **error scenarios**

### Monitoring:
- Firebase Crashlytics akan otomatis mengirim crash report
- Firebase Analytics akan otomatis tracking events
- Semua analytics events memiliki parameters untuk analisis mendalam
- Data dapat dilihat di **Firebase Console** dashboard

---

## 🔍 Next Steps (Optional)

Untuk improve testing lebih lanjut, bisa ditambahkan:

1. **Integration Tests** - Test end-to-end flow
2. **Golden Tests** - Visual regression testing
3. **Performance Tests** - Benchmark performa
4. **Accessibility Tests** - Testing untuk accessibility
5. **Code Coverage Target** - Minimal 80% coverage

---

**🎉 Testing & Monitoring sudah complete dan siap digunakan!**

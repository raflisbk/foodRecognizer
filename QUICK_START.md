# ⚡ Quick Start Guide

## 🚀 3 Langkah untuk Menjalankan Aplikasi

### 1️⃣ Install Dependencies
```bash
flutter pub get
```

### 2️⃣ Download Model (WAJIB!)
Download dari: https://github.com/Dicoding/a663-machine-learning-terapan/raw/main/Proyek_Akhir/food_classifier.tflite

Letakkan di: `assets/models/food_classifier.tflite`

### 3️⃣ Setup Gemini API Key
1. Dapatkan key gratis: https://makersuite.google.com/app/apikey
2. Edit `lib/constants/api_constants.dart`
3. Ganti `YOUR_GEMINI_API_KEY_HERE` dengan key Anda

### ▶️ Run!
```bash
flutter run
```

---

## 📋 Checklist Minimum (untuk app bisa jalan)

- [ ] Dependencies installed (`flutter pub get`)
- [ ] Model downloaded ke `assets/models/food_classifier.tflite`
- [ ] Gemini API key diisi
- [ ] Android permissions sudah ada (sudah ditambahkan)

## 🎯 Untuk Poin Maksimal (4/4)

Setup Firebase ML (optional tapi direkomendasikan):
1. Buat project di Firebase Console
2. Download `google-services.json` (Android)
3. Upload model ke Firebase ML
4. Lihat `SETUP_GUIDE.md` untuk detail

---

## 📱 Test App

1. **Quick Test**:
   - Tap "Choose from Gallery"
   - Pilih gambar makanan
   - Tap "Analyze Food"
   - Lihat hasil

2. **Full Test**:
   - Test gallery picker ✓
   - Test camera ✓
   - Test crop ✓
   - Test analyze ✓
   - Test live camera ✓
   - Lihat nutrition info ✓
   - Lihat recipes ✓

---

## ⚠️ Troubleshooting Cepat

**Model not found?**
→ Download dan letakkan di `assets/models/food_classifier.tflite`

**Gemini API error?**
→ Cek API key di `lib/constants/api_constants.dart`

**Build error?**
→ Run: `flutter clean && flutter pub get && flutter run`

**Permission denied?**
→ Izinkan camera di settings HP

---

## 📚 Dokumentasi Lengkap

- **README.md**: Overview & fitur
- **SETUP_GUIDE.md**: Setup detail step-by-step
- **FITUR_LENGKAP.md**: Penjelasan teknis & kriteria

---

## 🎯 Target Penilaian

✅ Kriteria 1: 4/4 (Camera stream)
✅ Kriteria 2: 4/4 (Firebase ML + Isolate)
✅ Kriteria 3: 4/4 (MealDB + Gemini API)

**Total: 12/12 poin** 🎉

---

Need help? Baca `SETUP_GUIDE.md` untuk troubleshooting lengkap!

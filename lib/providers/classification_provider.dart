import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/food_prediction.dart';
import '../services/image_classification_service.dart';
import '../services/firebase_ml_service.dart';

final classificationServiceProvider = Provider<ImageClassificationService>((ref) {
  return ImageClassificationService();
});

final firebaseMLServiceProvider = Provider<FirebaseMLService>((ref) {
  return FirebaseMLService();
});

final classificationProvider =
    StateNotifierProvider<ClassificationNotifier, ClassificationState>((ref) {
  return ClassificationNotifier(
    ref.read(classificationServiceProvider),
    ref.read(firebaseMLServiceProvider),
  );
});

class ClassificationState {
  final bool isInitialized;
  final bool isLoading;
  final FoodPrediction? prediction;
  final String? error;
  final bool useFirebaseModel;
  final String? firebaseModelPath;

  ClassificationState({
    this.isInitialized = false,
    this.isLoading = false,
    this.prediction,
    this.error,
    this.useFirebaseModel = false,
    this.firebaseModelPath,
  });

  ClassificationState copyWith({
    bool? isInitialized,
    bool? isLoading,
    FoodPrediction? prediction,
    String? error,
    bool? useFirebaseModel,
    String? firebaseModelPath,
    bool clearPrediction = false,
  }) {
    return ClassificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      prediction: clearPrediction ? null : (prediction ?? this.prediction),
      error: error,
      useFirebaseModel: useFirebaseModel ?? this.useFirebaseModel,
      firebaseModelPath: firebaseModelPath ?? this.firebaseModelPath,
    );
  }
}

class ClassificationNotifier extends StateNotifier<ClassificationState> {
  final ImageClassificationService _classificationService;
  final FirebaseMLService _firebaseMLService;
  final Logger _logger = Logger();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  ClassificationNotifier(
    this._classificationService,
    this._firebaseMLService,
  ) : super(ClassificationState());

  Future<void> initialize({bool useFirebaseModel = true}) async {
    try {
      state = state.copyWith(isLoading: true);

      String? modelPath;

      if (useFirebaseModel) {
        _logger.i('Attempting to download model from Firebase ML');
        modelPath = await _firebaseMLService.downloadModel();

        if (modelPath != null) {
          state = state.copyWith(
            useFirebaseModel: true,
            firebaseModelPath: modelPath,
          );
        } else {
          _logger.w('Firebase model download failed, using local model');
        }
      }

      await _classificationService.initialize(modelPath: modelPath);

      // Log analytics event for model initialization
      await _analytics.logEvent(
        name: 'model_initialized',
        parameters: {
          'model_source': useFirebaseModel ? 'firebase' : 'local',
          'model_path': modelPath ?? 'local_asset',
        },
      );

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
      );
    } on FileSystemException catch (fileError) {
      _logger.e('File system error: $fileError');
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal mengakses file model AI. Pastikan aplikasi memiliki izin penyimpanan yang cukup.',
      );
    } on PlatformException catch (platformError) {
      _logger.e('Platform error: $platformError');
      state = state.copyWith(
        isLoading: false,
        error: 'Kesalahan sistem: ${platformError.message ?? "Unknown"}. Silakan restart aplikasi.',
      );
    } catch (e) {
      _logger.e('Error initializing classification: $e');
      String errorMessage;
      if (e.toString().contains('OutOfMemory')) {
        errorMessage = 'Memori perangkat tidak cukup. Tutup beberapa aplikasi lain dan coba lagi.';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Gagal mengunduh model AI. Periksa koneksi internet Anda.';
      } else if (e.toString().contains('Permission')) {
        errorMessage = 'Aplikasi tidak memiliki izin yang diperlukan. Periksa pengaturan izin.';
      } else {
        errorMessage = 'Gagal memuat model AI. Silakan restart aplikasi atau hubungi developer.';
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  Future<void> classifyImage(File imageFile) async {
    try {
      state = state.copyWith(isLoading: true, clearPrediction: true);

      // Verify file exists
      if (!await imageFile.exists()) {
        state = state.copyWith(
          isLoading: false,
          error: 'File gambar tidak ditemukan. Silakan pilih gambar lagi.',
        );
        return;
      }

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        state = state.copyWith(
          isLoading: false,
          error: 'File gambar kosong atau rusak. Silakan pilih gambar lain.',
        );
        return;
      }

      final imageBytes = await imageFile.readAsBytes();
      final prediction = await _classificationService.classifyImage(imageBytes);

      if (prediction != null) {
        // Log analytics event for successful classification
        await _analytics.logEvent(
          name: 'food_classified',
          parameters: {
            'food_label': prediction.label,
            'confidence': (prediction.confidence * 100).toStringAsFixed(2),
            'high_confidence': prediction.confidence >= 0.8,
          },
        );

        state = state.copyWith(
          prediction: prediction,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Tidak dapat mengenali makanan pada gambar. Pastikan gambar berisi makanan yang jelas '
                 'dan coba lagi dengan pencahayaan yang lebih baik.',
        );
      }
    } on FileSystemException catch (e) {
      _logger.e('File system error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal membaca file gambar. Silakan coba lagi.',
      );
    } on FormatException catch (e) {
      _logger.e('Format error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Format gambar tidak didukung. Gunakan format JPG, PNG, atau WEBP.',
      );
    } catch (e) {
      _logger.e('Error classifying image: $e');
      String errorMessage;
      if (e.toString().contains('OutOfMemory')) {
        errorMessage = 'Memori tidak cukup. Coba gunakan gambar dengan ukuran lebih kecil.';
      } else if (e.toString().contains('Interpreter')) {
        errorMessage = 'Model AI belum siap. Tunggu sebentar dan coba lagi.';
      } else {
        errorMessage = 'Gagal menganalisis gambar. Silakan coba lagi atau gunakan gambar lain.';
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  Future<void> classifyImageBytes(Uint8List imageBytes) async {
    try {
      state = state.copyWith(isLoading: true, clearPrediction: true);

      final prediction = await _classificationService.classifyImage(imageBytes);

      if (prediction != null) {
        state = state.copyWith(
          prediction: prediction,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to classify image',
        );
      }
    } catch (e) {
      _logger.e('Error classifying image bytes: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearPrediction() {
    state = state.copyWith(clearPrediction: true);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _classificationService.dispose();
    super.dispose();
  }
}

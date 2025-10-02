import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../constants/api_constants.dart';
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
        _logger.i('[ClassificationProvider] Attempting to download model from Firebase ML');
        modelPath = await _firebaseMLService.downloadModel();

        if (modelPath != null) {
          _logger.i('[ClassificationProvider] SUCCESS: Cloud model downloaded from Firebase ML');
          _logger.i('[ClassificationProvider] Model source: Firebase ML (Cloud)');
          _logger.i('[ClassificationProvider] Model path: $modelPath');
          state = state.copyWith(
            useFirebaseModel: true,
            firebaseModelPath: modelPath,
          );
        } else {
          _logger.w('[ClassificationProvider] WARNING: Firebase model download failed');
          _logger.i('[ClassificationProvider] Fallback: Using local on-device model');
        }
      } else {
        _logger.i('[ClassificationProvider] Model source: Local on-device model');
        _logger.i('[ClassificationProvider] Using bundled asset model');
      }

      await _classificationService.initialize(modelPath: modelPath);

      // Log analytics event for model initialization
      await _analytics.logEvent(
        name: 'model_initialized',
        parameters: {
          'model_source': useFirebaseModel && modelPath != null ? 'firebase' : 'local',
          'model_path': modelPath ?? 'local_asset',
        },
      );

      final String modelSource = (useFirebaseModel && modelPath != null) ? 'Firebase ML (Cloud)' : 'Local on-device';
      _logger.i('[ClassificationProvider] Model initialization completed');
      _logger.i('[ClassificationProvider] Active model: $modelSource');
      _logger.i('[ClassificationProvider] Food recognition system ready');

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
      );
    } on FileSystemException catch (fileError) {
      _logger.e('File system error: $fileError');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to access AI model file. Ensure app has sufficient storage permissions.',
      );
    } on PlatformException catch (platformError) {
      _logger.e('Platform error: $platformError');
      state = state.copyWith(
        isLoading: false,
        error: 'System error: ${platformError.message ?? "Unknown"}. Please restart the app.',
      );
    } catch (e) {
      _logger.e('Error initializing classification: $e');
      String errorMessage;
      if (e.toString().contains('OutOfMemory')) {
        errorMessage = 'Device memory insufficient. Close some apps and try again.';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Failed to download AI model. Check your internet connection.';
      } else if (e.toString().contains('Permission')) {
        errorMessage = 'App lacks required permissions. Check permission settings.';
      } else {
        errorMessage = 'Failed to load AI model. Please restart app or contact developer.';
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
          error: 'Image file not found. Please select image again.',
        );
        return;
      }

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        state = state.copyWith(
          isLoading: false,
          error: 'Image file is empty or corrupted. Please select another image.',
        );
        return;
      }

      final imageBytes = await imageFile.readAsBytes();
      final prediction = await _classificationService.classifyImage(imageBytes);

      if (prediction != null) {
        // Check if this is a low confidence prediction (negative confidence)
        if (prediction.confidence < 0) {
          final actualConfidence = -prediction.confidence; // Convert back to positive
          final confidencePercent = (actualConfidence * 100).toStringAsFixed(1);

          _logger.w('[ClassificationProvider] Low confidence detection: ${prediction.label} ($confidencePercent%)');

          state = state.copyWith(
            isLoading: false,
            error: 'Unable to confidently identify the food in this image.\n\n'
                   'The model detected "${prediction.label}" but with only $confidencePercent% confidence '
                   '(minimum required: ${(ApiConstants.confidenceThreshold * 100).toStringAsFixed(0)}%).\n\n'
                   'Tips for better recognition:\n'
                   '• Ensure the food is clearly visible\n'
                   '• Use good lighting conditions\n'
                   '• Take a closer, focused shot\n'
                   '• Make sure the food fills most of the frame',
          );
          return;
        }

        // Log analytics event for successful classification
        await _analytics.logEvent(
          name: 'food_classified',
          parameters: {
            'food_label': prediction.label,
            'confidence': (prediction.confidence * 100).toStringAsFixed(2),
            'high_confidence': prediction.confidence >= 0.8 ? 1 : 0,
          },
        );

        state = state.copyWith(
          prediction: prediction,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to recognize any food in this image.\n\n'
                 'Please ensure:\n'
                 '• The image contains food items\n'
                 '• The food is clearly visible\n'
                 '• Lighting is adequate\n'
                 '• The image is not blurry or too dark\n\n'
                 'Try taking a new photo with better conditions.',
        );
      }
    } on FileSystemException catch (e) {
      _logger.e('File system error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to read image file. Please try again.',
      );
    } on FormatException catch (e) {
      _logger.e('Format error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Image format not supported. Use JPG, PNG, or WEBP format.',
      );
    } catch (e) {
      _logger.e('Error classifying image: $e');
      String errorMessage;
      if (e.toString().contains('OutOfMemory')) {
        errorMessage = 'Insufficient memory. Try using a smaller image.';
      } else if (e.toString().contains('Interpreter')) {
        errorMessage = 'AI model not ready. Wait a moment and try again.';
      } else {
        errorMessage = 'Failed to analyze image. Please try again or use another image.';
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
        // Check if this is a low confidence prediction (negative confidence)
        if (prediction.confidence < 0) {
          final actualConfidence = -prediction.confidence;
          final confidencePercent = (actualConfidence * 100).toStringAsFixed(1);

          _logger.w('[ClassificationProvider] Low confidence in live stream: ${prediction.label} ($confidencePercent%)');

          // For live detection, we just skip low confidence without showing error
          // This prevents constant error messages during streaming
          state = state.copyWith(
            isLoading: false,
            clearPrediction: true, // Clear any previous prediction
          );
          return;
        }

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

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../models/food_prediction.dart';

class ImageClassificationService {
  static final Logger _logger = Logger();
  Interpreter? _interpreter;
  List<String> _labels = [];

  // Singleton pattern
  static final ImageClassificationService _instance =
      ImageClassificationService._internal();
  factory ImageClassificationService() => _instance;
  ImageClassificationService._internal();

  Future<void> initialize({String? modelPath}) async {
    try {
      debugPrint('[FoodRecognizer] Memuat label makanan...');

      // Load labels
      final labelsData = await rootBundle.loadString('assets/labels/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      debugPrint('[FoodRecognizer] Berhasil memuat ${_labels.length} jenis makanan');

      // Load model
      debugPrint('[FoodRecognizer] Memuat model AI...');
      if (modelPath != null) {
        // Load from Firebase ML downloaded model (path is a String)
        final modelFile = File(modelPath);
        _interpreter = await Interpreter.fromFile(modelFile);
        debugPrint('[FoodRecognizer] Model AI dari cloud berhasil dimuat');
      } else {
        // Load from assets
        _interpreter = await Interpreter.fromAsset('assets/models/${ApiConstants.modelFileName}');
        debugPrint('[FoodRecognizer] Model AI lokal berhasil dimuat');
      }

      debugPrint('[FoodRecognizer] Sistem pengenalan makanan siap digunakan');
    } catch (e) {
      debugPrint('[FoodRecognizer] Gagal memuat sistem: $e');
      rethrow;
    }
  }

  Future<FoodPrediction?> classifyImage(Uint8List imageBytes) async {
    if (_interpreter == null) {
      debugPrint('[FoodRecognizer] Model AI belum siap, silakan tunggu sebentar');
      return null;
    }

    try {
      debugPrint('[FoodRecognizer] Menganalisis gambar...');

      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('[FoodRecognizer] Gagal membaca gambar');
        return null;
      }

      // Preprocess image
      final inputImage = _preprocessImage(image);

      // Prepare output
      final output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

      // Run inference
      _interpreter!.run(inputImage, output);

      // Get results
      final predictions = output[0] as List<double>;

      // Find best prediction
      double maxConfidence = 0;
      int maxIndex = 0;

      for (int i = 0; i < predictions.length; i++) {
        if (predictions[i] > maxConfidence) {
          maxConfidence = predictions[i];
          maxIndex = i;
        }
      }

      if (maxConfidence < ApiConstants.confidenceThreshold) {
        debugPrint('[FoodRecognizer] Tingkat kepercayaan terlalu rendah: ${(maxConfidence * 100).toStringAsFixed(1)}%');
        return null;
      }

      final prediction = FoodPrediction(
        label: _labels[maxIndex],
        confidence: maxConfidence,
        timestamp: DateTime.now(),
      );

      debugPrint('[FoodRecognizer] Terdeteksi: ${_labels[maxIndex]} (${(maxConfidence * 100).toStringAsFixed(1)}%)');
      return prediction;
    } catch (e) {
      debugPrint('[FoodRecognizer] Gagal menganalisis gambar: $e');
      return null;
    }
  }


  static List<List<List<List<int>>>> _preprocessImage(img.Image image) {
    // Resize to model input size
    final resized = img.copyResize(
      image,
      width: ApiConstants.inputSize,
      height: ApiConstants.inputSize,
    );

    // Convert to uint8 array (0-255 range, no normalization)
    final input = List.generate(
      1,
      (index) => List.generate(
        ApiConstants.inputSize,
        (y) => List.generate(
          ApiConstants.inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
            ];
          },
        ),
      ),
    );

    return input;
  }

  Future<FoodPrediction?> classifyImageFromPath(String imagePath) async {
    try {
      final imageBytes = await rootBundle.load(imagePath);
      return classifyImage(imageBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('[FoodRecognizer] Gagal memuat gambar: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

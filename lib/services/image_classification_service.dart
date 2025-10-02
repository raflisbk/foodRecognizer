import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../constants/api_constants.dart';
import '../models/food_prediction.dart';

class ImageClassificationService {
  Interpreter? _interpreter;
  List<String> _labels = [];

  // Singleton pattern
  static final ImageClassificationService _instance =
      ImageClassificationService._internal();
  factory ImageClassificationService() => _instance;
  ImageClassificationService._internal();

  Future<void> initialize({String? modelPath}) async {
    try {
      debugPrint('[FoodRecognizer] Loading food labels...');

      // Load labels
      final labelsData = await rootBundle.loadString('assets/labels/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      debugPrint('[FoodRecognizer] Successfully loaded ${_labels.length} food types');

      // Load model
      debugPrint('[FoodRecognizer] Loading AI model...');
      if (modelPath != null) {
        // Load from Firebase ML downloaded model (path is a String)
        final modelFile = File(modelPath);
        // ignore: await_only_futures
        _interpreter = await Interpreter.fromFile(modelFile);
        debugPrint('[FoodRecognizer] Cloud AI model loaded successfully');
      } else {
        // Load from assets
        // ignore: await_only_futures
        _interpreter = await Interpreter.fromAsset('assets/models/${ApiConstants.modelFileName}');
        debugPrint('[FoodRecognizer] Local AI model loaded successfully');
      }

      debugPrint('[FoodRecognizer] Food recognition system ready');
    } catch (e) {
      debugPrint('[FoodRecognizer] Failed to load system: $e');
      rethrow;
    }
  }

  Future<FoodPrediction?> classifyImage(Uint8List imageBytes) async {
    if (_interpreter == null) {
      debugPrint('[FoodRecognizer] AI model not ready, please wait');
      return null;
    }

    try {
      debugPrint('[FoodRecognizer] Analyzing image...');

      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('[FoodRecognizer] Failed to read image');
        return null;
      }

      // Preprocess image
      final inputImage = _preprocessImage(image);

      // Get output shape and quantization parameters from model
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      final numClasses = outputShape[1];

      // Check if model is quantized by checking quantization parameters
      final quantizationParams = outputTensor.params;
      final isQuantized = quantizationParams.scale != 0.0;

      // Prepare output buffer based on model type
      dynamic output;
      if (isQuantized) {
        // For quantized models, use uint8 buffer
        output = List.filled(1 * numClasses, 0).reshape([1, numClasses]);
      } else {
        // For float models, use double buffer
        output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);
      }

      // Run inference
      _interpreter!.run(inputImage, output);

      // Get results and dequantize if needed
      List<double> predictions;
      if (isQuantized) {
        // Dequantize: output = (quantized_value - zero_point) * scale
        // For this model: scale = 0.00390625, zero_point = 0
        final scale = quantizationParams.scale;
        final zeroPoint = quantizationParams.zeroPoint;

        final quantizedOutput = output[0] as List<int>;
        predictions = quantizedOutput.map((q) => (q - zeroPoint) * scale).toList();
      } else {
        predictions = output[0] as List<double>;
      }

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
        final confidencePercent = (maxConfidence * 100).toStringAsFixed(1);
        debugPrint('[FoodRecognizer] Confidence level too low: $confidencePercent%');
        debugPrint('[FoodRecognizer] Threshold: ${(ApiConstants.confidenceThreshold * 100).toStringAsFixed(0)}%');

        // Return prediction with special low confidence flag
        // We'll use a negative confidence to signal low confidence to the provider
        final prediction = FoodPrediction(
          label: _labels.length > maxIndex ? _labels[maxIndex] : 'Unknown',
          confidence: -maxConfidence, // Negative to signal low confidence
          timestamp: DateTime.now(),
        );
        return prediction;
      }

      // Check if maxIndex is within labels bounds
      if (maxIndex >= _labels.length) {
        debugPrint('[FoodRecognizer] Prediction index ($maxIndex) exceeds label count (${_labels.length})');
        debugPrint('[FoodRecognizer] Using "Unknown Food" label for out-of-range index');
        final prediction = FoodPrediction(
          label: 'Unknown Food (Class $maxIndex)',
          confidence: maxConfidence,
          timestamp: DateTime.now(),
        );
        return prediction;
      }

      final prediction = FoodPrediction(
        label: _labels[maxIndex],
        confidence: maxConfidence,
        timestamp: DateTime.now(),
      );

      debugPrint('[FoodRecognizer] Detected: ${_labels[maxIndex]} (${(maxConfidence * 100).toStringAsFixed(1)}%)');
      return prediction;
    } catch (e) {
      debugPrint('[FoodRecognizer] Failed to analyze image: $e');
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

    // Convert to int array with uint8 values (0-255 range, no normalization)
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
      debugPrint('[FoodRecognizer] Failed to load image: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

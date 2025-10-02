import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../constants/api_constants.dart';
import '../models/food_prediction.dart';

// Data class untuk mengirim data ke isolate
class _IsolateInferenceData {
  final Uint8List imageBytes;
  final String modelPath;
  final bool isAssetModel;
  final List<String> labels;
  final SendPort sendPort;

  _IsolateInferenceData({
    required this.imageBytes,
    required this.modelPath,
    required this.isAssetModel,
    required this.labels,
    required this.sendPort,
  });
}

class ImageClassificationService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  String? _currentModelPath;
  bool _isAssetModel = true;

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
        _currentModelPath = modelPath;
        _isAssetModel = false;
        debugPrint('[FoodRecognizer] Cloud AI model loaded successfully');
      } else {
        // Load from assets
        // ignore: await_only_futures
        _interpreter = await Interpreter.fromAsset('assets/models/${ApiConstants.modelFileName}');
        _currentModelPath = 'assets/models/${ApiConstants.modelFileName}';
        _isAssetModel = true;
        debugPrint('[FoodRecognizer] Local AI model loaded successfully');
      }

      debugPrint('[FoodRecognizer] Food recognition system ready');
    } catch (e) {
      debugPrint('[FoodRecognizer] Failed to load system: $e');
      rethrow;
    }
  }

  Future<FoodPrediction?> classifyImage(Uint8List imageBytes) async {
    if (_interpreter == null || _currentModelPath == null) {
      debugPrint('[FoodRecognizer] AI model not ready, please wait');
      return null;
    }

    try {
      debugPrint('[FoodRecognizer] Starting image analysis in background thread...');

      // Buat ReceivePort untuk komunikasi dengan isolate
      final receivePort = ReceivePort();

      // Spawn isolate untuk menjalankan inferensi di background
      await Isolate.spawn(
        _runInferenceInIsolate,
        _IsolateInferenceData(
          imageBytes: imageBytes,
          modelPath: _currentModelPath!,
          isAssetModel: _isAssetModel,
          labels: _labels,
          sendPort: receivePort.sendPort,
        ),
      );

      // Tunggu hasil dari isolate
      final result = await receivePort.first;

      if (result is FoodPrediction) {
        debugPrint('[FoodRecognizer] Background analysis completed successfully');
        return result;
      } else if (result is String) {
        debugPrint('[FoodRecognizer] Background analysis failed: $result');
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('[FoodRecognizer] Failed to analyze image: $e');
      return null;
    }
  }

  // Static method untuk dijalankan di isolate
  static Future<void> _runInferenceInIsolate(_IsolateInferenceData data) async {
    try {
      // Load interpreter di isolate
      Interpreter interpreter;
      if (data.isAssetModel) {
        // ignore: await_only_futures
        interpreter = await Interpreter.fromAsset(data.modelPath);
      } else {
        final modelFile = File(data.modelPath);
        // ignore: await_only_futures
        interpreter = await Interpreter.fromFile(modelFile);
      }

      // Decode image
      img.Image? image = img.decodeImage(data.imageBytes);
      if (image == null) {
        data.sendPort.send('Failed to decode image');
        return;
      }

      // Preprocess image
      final inputImage = _preprocessImage(image);

      // Get output shape and quantization parameters from model
      final outputTensor = interpreter.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      final numClasses = outputShape[1];

      // Check if model is quantized
      final quantizationParams = outputTensor.params;
      final isQuantized = quantizationParams.scale != 0.0;

      // Prepare output buffer based on model type
      dynamic output;
      if (isQuantized) {
        output = List.filled(1 * numClasses, 0).reshape([1, numClasses]);
      } else {
        output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);
      }

      // Run inference
      interpreter.run(inputImage, output);

      // Get results and dequantize if needed
      List<double> predictions;
      if (isQuantized) {
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

      // Close interpreter
      interpreter.close();

      // Check confidence threshold
      if (maxConfidence < ApiConstants.confidenceThreshold) {
        final prediction = FoodPrediction(
          label: data.labels.length > maxIndex ? data.labels[maxIndex] : 'Unknown',
          confidence: -maxConfidence, // Negative to signal low confidence
          timestamp: DateTime.now(),
        );
        data.sendPort.send(prediction);
        return;
      }

      // Check if maxIndex is within labels bounds
      if (maxIndex >= data.labels.length) {
        final prediction = FoodPrediction(
          label: 'Unknown Food (Class $maxIndex)',
          confidence: maxConfidence,
          timestamp: DateTime.now(),
        );
        data.sendPort.send(prediction);
        return;
      }

      final prediction = FoodPrediction(
        label: data.labels[maxIndex],
        confidence: maxConfidence,
        timestamp: DateTime.now(),
      );

      data.sendPort.send(prediction);
    } catch (e) {
      data.sendPort.send('Error in isolate: $e');
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

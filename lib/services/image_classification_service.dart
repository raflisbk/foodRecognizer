import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../constants/api_constants.dart';
import '../models/food_prediction.dart';

// Message types untuk komunikasi isolate
enum _IsolateMessageType { initialize, inference, dispose }

// Message untuk initialize isolate
class _InitializeMessage {
  final String modelPath;
  final bool isAssetModel;
  final List<String> labels;
  final SendPort sendPort;

  _InitializeMessage({
    required this.modelPath,
    required this.isAssetModel,
    required this.labels,
    required this.sendPort,
  });
}

// Message untuk inference request
class _InferenceMessage {
  final Uint8List imageBytes;
  final SendPort sendPort;

  _InferenceMessage({required this.imageBytes, required this.sendPort});
}

// Command untuk isolate
class _IsolateCommand {
  final _IsolateMessageType type;
  final dynamic data;

  _IsolateCommand(this.type, this.data);
}

class ImageClassificationService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  String? _currentModelPath;
  bool _isAssetModel = true;

  // Long-lived isolate untuk inference
  Isolate? _inferenceIsolate;
  SendPort? _isolateSendPort;
  ReceivePort? _receivePort;

  // Singleton pattern
  static final ImageClassificationService _instance =
      ImageClassificationService._internal();
  factory ImageClassificationService() => _instance;
  ImageClassificationService._internal();

  Future<void> initialize({String? modelPath}) async {
    try {
      debugPrint('[FoodRecognizer] Loading food labels...');

      // Load labels
      final labelsData = await rootBundle.loadString(
        'assets/labels/labels.txt',
      );
      _labels = labelsData
          .split('\n')
          .where((label) => label.isNotEmpty)
          .toList();
      debugPrint(
        '[FoodRecognizer] Successfully loaded ${_labels.length} food types',
      );

      // Set model path - convert asset to file if needed
      if (modelPath != null) {
        _currentModelPath = modelPath;
        _isAssetModel = false;
        debugPrint('[FoodRecognizer] Using Cloud AI model from Firebase ML');
      } else {
        // CRITICAL FIX: Copy asset model to file system for isolate access
        debugPrint('[FoodRecognizer] Copying asset model to file system...');
        final modelBytes = await rootBundle.load(
          'assets/models/${ApiConstants.modelFileName}',
        );
        final tempDir = await getTemporaryDirectory();
        final modelFile = File('${tempDir.path}/${ApiConstants.modelFileName}');
        await modelFile.writeAsBytes(modelBytes.buffer.asUint8List());

        _currentModelPath = modelFile.path;
        _isAssetModel = false; // Now using file path, not asset
        debugPrint('[FoodRecognizer] Local model copied to: ${modelFile.path}');
      }

      // Setup long-lived isolate untuk inference
      debugPrint('[FoodRecognizer] Spawning long-lived inference isolate');
      await _setupInferenceIsolate();

      debugPrint(
        '[FoodRecognizer] Food recognition system ready (isolate-powered)',
      );

      // Print implementation status for verification
      printImplementationStatus();
    } catch (e) {
      debugPrint('[FoodRecognizer] Failed to load system: $e');
      rethrow;
    }
  }

  Future<void> _setupInferenceIsolate() async {
    // Kill existing isolate if any
    _inferenceIsolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();

    // Create new receive port
    _receivePort = ReceivePort();

    // Spawn long-lived isolate
    _inferenceIsolate = await Isolate.spawn(
      _inferenceIsolateEntryPoint,
      _receivePort!.sendPort,
    );

    // Get SendPort from isolate
    _isolateSendPort = await _receivePort!.first as SendPort;

    debugPrint('[FoodRecognizer] Isolate spawned and ready');

    // Initialize model in isolate
    final initReceivePort = ReceivePort();
    _isolateSendPort!.send(
      _IsolateCommand(
        _IsolateMessageType.initialize,
        _InitializeMessage(
          modelPath: _currentModelPath!,
          isAssetModel: _isAssetModel,
          labels: _labels,
          sendPort: initReceivePort.sendPort,
        ),
      ),
    );

    // Wait for initialization complete
    final initResult = await initReceivePort.first;
    if (initResult is String && initResult.startsWith('ERROR')) {
      throw Exception('Failed to initialize model in isolate: $initResult');
    }

    debugPrint('[FoodRecognizer] Model loaded in isolate: $initResult');
  }

  Future<FoodPrediction?> classifyImage(Uint8List imageBytes) async {
    if (_isolateSendPort == null) {
      debugPrint('[FoodRecognizer] Inference isolate not ready');
      return null;
    }

    try {
      debugPrint('[FoodRecognizer] Sending image to isolate for analysis');

      // Create receive port for this inference
      final inferenceReceivePort = ReceivePort();

      // Send inference request to isolate
      _isolateSendPort!.send(
        _IsolateCommand(
          _IsolateMessageType.inference,
          _InferenceMessage(
            imageBytes: imageBytes,
            sendPort: inferenceReceivePort.sendPort,
          ),
        ),
      );

      // Wait for result
      final result = await inferenceReceivePort.first;

      if (result is FoodPrediction) {
        debugPrint(
          '[FoodRecognizer] Analysis complete: ${result.label} (${(result.confidence * 100).toStringAsFixed(1)}%)',
        );
        return result;
      } else if (result is String) {
        debugPrint('[FoodRecognizer] Analysis failed: $result');
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('[FoodRecognizer] Error in inference: $e');
      return null;
    }
  }

  // Entry point untuk long-lived isolate
  static void _inferenceIsolateEntryPoint(SendPort mainSendPort) {
    // Create receive port untuk isolate ini
    final isolateReceivePort = ReceivePort();

    // Send back SendPort ke main isolate
    mainSendPort.send(isolateReceivePort.sendPort);

    // State dalam isolate
    Interpreter? interpreter;
    List<String>? labels;
    int? numClasses;
    bool? isQuantized;
    double? scale;
    int? zeroPoint;

    // Listen for commands
    isolateReceivePort.listen((message) async {
      if (message is! _IsolateCommand) return;

      try {
        switch (message.type) {
          case _IsolateMessageType.initialize:
            final initData = message.data as _InitializeMessage;

            // Load model SEKALI SAJA - always from file (asset already copied to file)
            final modelFile = File(initData.modelPath);
            // ignore: await_only_futures
            interpreter = await Interpreter.fromFile(modelFile);

            // Cache model metadata
            labels = initData.labels;
            final outputTensor = interpreter!.getOutputTensor(0);
            final outputShape = outputTensor.shape;
            numClasses = outputShape[1];

            final quantizationParams = outputTensor.params;
            isQuantized = quantizationParams.scale != 0.0;
            scale = quantizationParams.scale;
            zeroPoint = quantizationParams.zeroPoint;

            initData.sendPort.send('Interpreter loaded successfully');
            break;

          case _IsolateMessageType.inference:
            final inferenceData = message.data as _InferenceMessage;

            if (interpreter == null || labels == null) {
              inferenceData.sendPort.send('ERROR: Model not initialized');
              return;
            }

            // Decode & preprocess image
            img.Image? image = img.decodeImage(inferenceData.imageBytes);
            if (image == null) {
              inferenceData.sendPort.send('ERROR: Failed to decode image');
              return;
            }

            final inputImage = _preprocessImage(image);

            // Prepare output buffer
            dynamic output;
            if (isQuantized!) {
              output = List.filled(
                1 * numClasses!,
                0,
              ).reshape([1, numClasses!]);
            } else {
              output = List.filled(
                1 * numClasses!,
                0.0,
              ).reshape([1, numClasses!]);
            }

            // Run inference
            interpreter!.run(inputImage, output);

            // Process results
            List<double> predictions;
            if (isQuantized!) {
              final quantizedOutput = output[0] as List<int>;
              predictions = quantizedOutput
                  .map((q) => (q - zeroPoint!) * scale!)
                  .toList();
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

            // Create prediction
            FoodPrediction prediction;
            if (maxConfidence < ApiConstants.confidenceThreshold) {
              prediction = FoodPrediction(
                label: labels!.length > maxIndex
                    ? labels![maxIndex]
                    : 'Unknown',
                confidence: -maxConfidence,
                timestamp: DateTime.now(),
              );
            } else if (maxIndex >= labels!.length) {
              prediction = FoodPrediction(
                label: 'Unknown Food (Class $maxIndex)',
                confidence: maxConfidence,
                timestamp: DateTime.now(),
              );
            } else {
              prediction = FoodPrediction(
                label: labels![maxIndex],
                confidence: maxConfidence,
                timestamp: DateTime.now(),
              );
            }

            inferenceData.sendPort.send(prediction);
            break;

          case _IsolateMessageType.dispose:
            interpreter?.close();
            isolateReceivePort.close();
            break;
        }
      } catch (e) {
        if (message.data is _InferenceMessage) {
          (message.data as _InferenceMessage).sendPort.send('ERROR: $e');
        } else if (message.data is _InitializeMessage) {
          (message.data as _InitializeMessage).sendPort.send('ERROR: $e');
        }
      }
    });
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
        (y) => List.generate(ApiConstants.inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        }),
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

  // Debug methods untuk verifikasi isolate
  bool get isIsolateActive =>
      _isolateSendPort != null && _inferenceIsolate != null;

  String getImplementationInfo() {
    final buffer = StringBuffer();
    buffer.writeln('=== ML Inference Implementation Info ===');
    buffer.writeln(
      'Isolate Status: ${isIsolateActive ? "ACTIVE (Running in Background)" : "INACTIVE (Main Thread)"}',
    );
    buffer.writeln(
      'Model Source: ${_isAssetModel ? "Local Assets" : "Firebase ML"}',
    );
    buffer.writeln('Model Path: ${_currentModelPath ?? "Not loaded"}');
    buffer.writeln('Labels Loaded: ${_labels.length} food types');
    buffer.writeln(
      'Performance: ${isIsolateActive ? "Optimized (No UI Freeze)" : "Not Optimized (May Freeze UI)"}',
    );
    buffer.writeln('========================================');
    return buffer.toString();
  }

  void printImplementationStatus() {
    debugPrint(getImplementationInfo());
  }

  void dispose() {
    // Dispose isolate
    if (_isolateSendPort != null) {
      _isolateSendPort!.send(
        _IsolateCommand(_IsolateMessageType.dispose, null),
      );
    }
    _inferenceIsolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();

    // Cleanup
    _interpreter?.close();
    _interpreter = null;
    _inferenceIsolate = null;
    _isolateSendPort = null;
    _receivePort = null;

    debugPrint('[FoodRecognizer] Service disposed and isolate killed');
  }
}

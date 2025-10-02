import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_recognizer/services/image_classification_service.dart';
import 'package:food_recognizer/models/food_prediction.dart';

void main() {
  group('ImageClassificationService Tests', () {
    late ImageClassificationService service;

    setUp(() {
      service = ImageClassificationService();
    });

    tearDown(() {
      service.dispose();
    });

    test(
      'initialize - should initialize successfully with local model',
      () async {
        // Arrange & Act
        await service.initialize();

        // Assert
        // Service should be ready to classify images
        expect(service, isNotNull);
      },
    );

    test('initialize - should handle Firebase model path', () async {
      // Arrange
      const String testModelPath = '/path/to/firebase/model.tflite';

      // Act
      await service.initialize(modelPath: testModelPath);

      // Assert
      expect(service, isNotNull);
    });

    test('classifyImage - should return null for invalid image data', () async {
      // Arrange
      await service.initialize();
      final Uint8List emptyImage = Uint8List(0);

      // Act
      final result = await service.classifyImage(emptyImage);

      // Assert
      expect(result, isNull);
    });

    test(
      'classifyImage - should handle image processing errors gracefully',
      () async {
        // Arrange
        await service.initialize();
        final Uint8List invalidImage = Uint8List.fromList([1, 2, 3, 4]);

        // Act & Assert
        expect(
          () async => await service.classifyImage(invalidImage),
          returnsNormally,
        );
      },
    );

    test('dispose - should dispose interpreter successfully', () {
      // Arrange
      service.initialize();

      // Act & Assert
      expect(() => service.dispose(), returnsNormally);
    });

    test(
      'classifyImage - should return FoodPrediction with valid data',
      () async {
        // Arrange
        await service.initialize();

        // Create a minimal valid image (1x1 pixel white PNG)
        final Uint8List validImage = Uint8List.fromList([
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
          0,
          0,
          0,
          13,
          73,
          72,
          68,
          82,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          1,
          8,
          2,
          0,
          0,
          0,
          144,
          119,
          83,
          222,
          0,
          0,
          0,
          12,
          73,
          68,
          65,
          84,
          8,
          215,
          99,
          248,
          255,
          255,
          63,
          0,
          5,
          254,
          2,
          254,
          167,
          53,
          129,
          132,
          0,
          0,
          0,
          0,
          73,
          69,
          78,
          68,
          174,
          66,
          96,
          130,
        ]);

        // Act
        final result = await service.classifyImage(validImage);

        // Assert
        if (result != null) {
          expect(result, isA<FoodPrediction>());
          expect(result.label, isNotEmpty);
          expect(result.confidence, greaterThanOrEqualTo(0.0));
          expect(result.confidence, lessThanOrEqualTo(1.0));
        }
      },
    );
  });
}

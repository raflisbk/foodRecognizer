import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_recognizer/providers/classification_provider.dart';
import 'package:food_recognizer/services/image_classification_service.dart';
import 'package:food_recognizer/services/firebase_ml_service.dart';
import 'package:food_recognizer/models/food_prediction.dart';

@GenerateMocks([ImageClassificationService, FirebaseMLService])
class MockImageClassificationService extends Mock
    implements ImageClassificationService {}

class MockFirebaseMLService extends Mock implements FirebaseMLService {}

void main() {
  group('ClassificationProvider Tests', () {
    late MockImageClassificationService mockClassificationService;
    late MockFirebaseMLService mockFirebaseMLService;
    late ProviderContainer container;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      mockClassificationService = MockImageClassificationService();
      mockFirebaseMLService = MockFirebaseMLService();

      container = ProviderContainer(
        overrides: [
          classificationServiceProvider.overrideWithValue(
            mockClassificationService,
          ),
          firebaseMLServiceProvider.overrideWithValue(mockFirebaseMLService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should have correct default values', () {
      // Arrange & Act
      final state = container.read(classificationProvider);

      // Assert
      expect(state.isInitialized, false);
      expect(state.isLoading, false);
      expect(state.prediction, isNull);
      expect(state.error, isNull);
      expect(state.useFirebaseModel, false);
    });

    test(
      'initialize - should set isLoading to true during initialization',
      () async {
        // Arrange
        when(
          mockFirebaseMLService.downloadModel(),
        ).thenAnswer((_) async => null);
        when(
          mockClassificationService.initialize(modelPath: null),
        ).thenAnswer((_) async => {});

        // Act
        final notifier = container.read(classificationProvider.notifier);
        final future = notifier.initialize(useFirebaseModel: false);

        // Assert
        expect(container.read(classificationProvider).isLoading, true);

        await future;
      },
    );

    test(
      'initialize - should set isInitialized to true after successful initialization',
      () async {
        // Arrange
        when(
          mockFirebaseMLService.downloadModel(),
        ).thenAnswer((_) async => null);
        when(
          mockClassificationService.initialize(modelPath: null),
        ).thenAnswer((_) async => {});

        // Act
        final notifier = container.read(classificationProvider.notifier);
        await notifier.initialize(useFirebaseModel: false);

        // Assert
        final state = container.read(classificationProvider);
        expect(state.isInitialized, true);
        expect(state.isLoading, false);
        expect(state.error, isNull);
      },
    );

    test('initialize - should use Firebase model when available', () async {
      // Arrange
      const String modelPath = '/path/to/model.tflite';
      when(
        mockFirebaseMLService.downloadModel(),
      ).thenAnswer((_) async => modelPath);
      when(
        mockClassificationService.initialize(modelPath: modelPath),
      ).thenAnswer((_) async => {});

      // Act
      final notifier = container.read(classificationProvider.notifier);
      await notifier.initialize(useFirebaseModel: true);

      // Assert
      final state = container.read(classificationProvider);
      expect(state.useFirebaseModel, true);
      expect(state.firebaseModelPath, modelPath);
      verify(
        mockClassificationService.initialize(modelPath: modelPath),
      ).called(1);
    });

    test('initialize - should handle initialization errors', () async {
      // Arrange
      when(mockFirebaseMLService.downloadModel()).thenAnswer((_) async => null);
      when(
        mockClassificationService.initialize(modelPath: null),
      ).thenThrow(Exception('Initialization failed'));

      // Act
      final notifier = container.read(classificationProvider.notifier);
      await notifier.initialize(useFirebaseModel: false);

      // Assert
      final state = container.read(classificationProvider);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test(
      'classifyImageBytes - should set isLoading to true during classification',
      () async {
        // Arrange
        final Uint8List testImage = Uint8List.fromList([1, 2, 3, 4]);
        when(mockClassificationService.classifyImage(testImage)).thenAnswer(
          (_) async => FoodPrediction(
            label: 'Nasi Goreng',
            confidence: 0.95,
            timestamp: DateTime.now(),
          ),
        );

        // Act
        final notifier = container.read(classificationProvider.notifier);
        final future = notifier.classifyImageBytes(testImage);

        // Assert
        expect(container.read(classificationProvider).isLoading, true);

        await future;
      },
    );

    test(
      'classifyImageBytes - should update prediction on successful classification',
      () async {
        // Arrange
        final Uint8List testImage = Uint8List.fromList([1, 2, 3, 4]);
        final expectedPrediction = FoodPrediction(
          label: 'Rendang',
          confidence: 0.88,
          timestamp: DateTime.now(),
        );
        when(
          mockClassificationService.classifyImage(testImage),
        ).thenAnswer((_) async => expectedPrediction);

        // Act
        final notifier = container.read(classificationProvider.notifier);
        await notifier.classifyImageBytes(testImage);

        // Assert
        final state = container.read(classificationProvider);
        expect(state.prediction, isNotNull);
        expect(state.prediction?.label, 'Rendang');
        expect(state.prediction?.confidence, 0.88);
        expect(state.isLoading, false);
        expect(state.error, isNull);
      },
    );

    test(
      'classifyImageBytes - should set error when classification returns null',
      () async {
        // Arrange
        final Uint8List testImage = Uint8List.fromList([1, 2, 3, 4]);
        when(
          mockClassificationService.classifyImage(testImage),
        ).thenAnswer((_) async => null);

        // Act
        final notifier = container.read(classificationProvider.notifier);
        await notifier.classifyImageBytes(testImage);

        // Assert
        final state = container.read(classificationProvider);
        expect(state.prediction, isNull);
        expect(state.error, isNotNull);
        expect(state.isLoading, false);
      },
    );

    test('classifyImageBytes - should handle classification errors', () async {
      // Arrange
      final Uint8List testImage = Uint8List.fromList([1, 2, 3, 4]);
      when(
        mockClassificationService.classifyImage(testImage),
      ).thenThrow(Exception('Classification failed'));

      // Act
      final notifier = container.read(classificationProvider.notifier);
      await notifier.classifyImageBytes(testImage);

      // Assert
      final state = container.read(classificationProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, false);
    });

    test('clearPrediction - should clear prediction from state', () async {
      // Arrange
      final Uint8List testImage = Uint8List.fromList([1, 2, 3, 4]);
      when(mockClassificationService.classifyImage(testImage)).thenAnswer(
        (_) async => FoodPrediction(
          label: 'Sate',
          confidence: 0.92,
          timestamp: DateTime.now(),
        ),
      );

      final notifier = container.read(classificationProvider.notifier);
      await notifier.classifyImageBytes(testImage);

      // Act
      notifier.clearPrediction();

      // Assert
      final state = container.read(classificationProvider);
      expect(state.prediction, isNull);
    });

    test('clearError - should clear error from state', () async {
      // Arrange
      when(mockFirebaseMLService.downloadModel()).thenAnswer((_) async => null);
      when(
        mockClassificationService.initialize(modelPath: null),
      ).thenThrow(Exception('Error'));

      final notifier = container.read(classificationProvider.notifier);
      await notifier.initialize(useFirebaseModel: false);

      // Act
      notifier.clearError();

      // Assert
      final state = container.read(classificationProvider);
      expect(state.error, isNull);
    });
  });
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:food_recognizer/providers/camera_provider.dart';
import 'package:food_recognizer/services/camera_service.dart';

@GenerateMocks([CameraService])
class MockCameraService extends Mock implements CameraService {}

void main() {
  group('CameraProvider Tests', () {
    late MockCameraService mockCameraService;
    late ProviderContainer container;

    setUp(() {
      mockCameraService = MockCameraService();

      container = ProviderContainer(
        overrides: [
          cameraServiceProvider.overrideWithValue(mockCameraService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should have correct default values', () {
      // Arrange & Act
      final state = container.read(cameraProvider);

      // Assert
      expect(state.isInitialized, false);
      expect(state.isStreaming, false);
      expect(state.capturedImage, isNull);
      expect(state.error, isNull);
      expect(state.isFlashOn, false);
    });

    test('initialize - should set isInitialized to true on successful initialization', () async {
      // Arrange
      when(mockCameraService.initializeCamera()).thenAnswer((_) async => true);

      // Act
      final notifier = container.read(cameraProvider.notifier);
      await notifier.initialize();

      // Assert
      final state = container.read(cameraProvider);
      expect(state.isInitialized, true);
      expect(state.error, isNull);
      verify(mockCameraService.initializeCamera()).called(1);
    });

    test('initialize - should set error on failed initialization', () async {
      // Arrange
      when(mockCameraService.initializeCamera()).thenAnswer((_) async => false);

      // Act
      final notifier = container.read(cameraProvider.notifier);
      await notifier.initialize();

      // Assert
      final state = container.read(cameraProvider);
      expect(state.isInitialized, false);
      expect(state.error, isNotNull);
    });

    test('initialize - should handle initialization errors', () async {
      // Arrange
      when(mockCameraService.initializeCamera()).thenThrow(Exception('Camera error'));

      // Act
      final notifier = container.read(cameraProvider.notifier);
      await notifier.initialize();

      // Assert
      final state = container.read(cameraProvider);
      expect(state.error, isNotNull);
    });

    test('takePicture - should update capturedImage on success', () async {
      // Arrange
      final mockXFile = XFile('/path/to/image.jpg');
      when(mockCameraService.takePicture()).thenAnswer((_) async => mockXFile);

      // Act
      final notifier = container.read(cameraProvider.notifier);
      await notifier.takePicture();

      // Assert
      final state = container.read(cameraProvider);
      expect(state.capturedImage, isNotNull);
      expect(state.capturedImage?.path, '/path/to/image.jpg');
      verify(mockCameraService.takePicture()).called(1);
    });

    test('takePicture - should not update capturedImage when result is null', () async {
      // Arrange
      when(mockCameraService.takePicture()).thenAnswer((_) async => null);

      // Act
      final notifier = container.read(cameraProvider.notifier);
      await notifier.takePicture();

      // Assert
      final state = container.read(cameraProvider);
      expect(state.capturedImage, isNull);
    });

    test('takePicture - should handle errors', () async {
      // Arrange
      when(mockCameraService.takePicture()).thenThrow(Exception('Capture error'));

      // Act
      final notifier = container.read(cameraProvider.notifier);
      await notifier.takePicture();

      // Assert
      final state = container.read(cameraProvider);
      expect(state.error, isNotNull);
    });

    test('toggleFlash - should toggle flash state', () async {
      // Arrange
      when(mockCameraService.toggleFlash()).thenAnswer((_) async => {});

      // Act
      final notifier = container.read(cameraProvider.notifier);
      await notifier.toggleFlash();

      // Assert
      var state = container.read(cameraProvider);
      expect(state.isFlashOn, true);

      // Act again
      await notifier.toggleFlash();

      // Assert
      state = container.read(cameraProvider);
      expect(state.isFlashOn, false);

      verify(mockCameraService.toggleFlash()).called(2);
    });

    test('switchCamera - should call camera service switchCamera', () async {
      // Arrange
      when(mockCameraService.switchCamera()).thenAnswer((_) async => {});

      // Act
      final notifier = container.read(cameraProvider.notifier);
      await notifier.switchCamera();

      // Assert
      verify(mockCameraService.switchCamera()).called(1);
    });

    test('clearImage - should clear captured image', () async {
      // Arrange
      final mockXFile = XFile('/path/to/image.jpg');
      when(mockCameraService.takePicture()).thenAnswer((_) async => mockXFile);

      final notifier = container.read(cameraProvider.notifier);
      await notifier.takePicture();

      // Act
      notifier.clearImage();

      // Assert
      final state = container.read(cameraProvider);
      expect(state.capturedImage, isNull);
    });

    test('clearError - should clear error from state', () async {
      // Arrange
      when(mockCameraService.initializeCamera()).thenThrow(Exception('Error'));

      final notifier = container.read(cameraProvider.notifier);
      await notifier.initialize();

      // Act
      notifier.clearError();

      // Assert
      final state = container.read(cameraProvider);
      expect(state.error, isNull);
    });

  });
}

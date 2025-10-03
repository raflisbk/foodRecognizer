import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

class CameraService {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;

  // Singleton pattern
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  List<CameraDescription> get cameras => _cameras;
  CameraController? get controller => _controller;

  Future<void> initializeCameras() async {
    try {
      debugPrint('[CameraService] Initializing cameras...');
      _cameras = await availableCameras();
      debugPrint('[CameraService] Found ${_cameras.length} cameras');
    } catch (e) {
      debugPrint('[CameraService] ERROR: Failed to get cameras - $e');
    }
  }

  Future<bool> initializeCamera({
    CameraDescription? camera,
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    try {
      debugPrint('[CameraService] Initializing camera...');
      if (_cameras.isEmpty) {
        await initializeCameras();
      }

      if (_cameras.isEmpty) {
        debugPrint('[CameraService] ERROR: No cameras available');
        return false;
      }

      final selectedCamera = camera ?? _cameras.first;
      debugPrint(
        '[CameraService] Using camera: ${selectedCamera.name} (${selectedCamera.lensDirection})',
      );

      _controller = CameraController(
        selectedCamera,
        resolution,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      debugPrint('[CameraService] Camera initialized successfully');
      return true;
    } catch (e) {
      debugPrint('[CameraService] ERROR: Failed to initialize camera - $e');
      return false;
    }
  }

  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('[CameraService] ERROR: Camera not initialized');
      return null;
    }

    try {
      debugPrint('[CameraService] Taking picture...');
      final image = await _controller!.takePicture();
      debugPrint('[CameraService] Picture taken successfully: ${image.path}');
      return image;
    } catch (e) {
      debugPrint('[CameraService] ERROR: Failed to take picture - $e');
      return null;
    }
  }

  Future<void> startImageStream(Function(CameraImage) onImage) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('[CameraService] ERROR: Camera not initialized');
      return;
    }

    try {
      debugPrint('[CameraService] Starting image stream...');
      await _controller!.startImageStream(onImage);
      debugPrint('[CameraService] Image stream started successfully');
    } catch (e) {
      debugPrint('[CameraService] ERROR: Failed to start image stream - $e');
    }
  }

  Future<void> stopImageStream() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('[CameraService] Controller not initialized, nothing to stop');
      return;
    }

    try {
      if (_controller!.value.isStreamingImages) {
        debugPrint('[CameraService] Stopping image stream...');

        // Stop the stream with timeout to prevent hanging
        await _controller!.stopImageStream().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint(
              '[CameraService] WARNING: Stop image stream timed out after 2s',
            );
          },
        );

        debugPrint('[CameraService] Image stream stopped successfully');

        // Give the camera a moment to clean up buffers
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        debugPrint('[CameraService] Image stream was not running');
      }
    } catch (e) {
      debugPrint('[CameraService] ERROR: Failed to stop image stream - $e');
      // Continue anyway to allow dispose to proceed
    }
  }

  Future<void> dispose() async {
    debugPrint('[CameraService] Disposing camera service...');
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
    debugPrint('[CameraService] Camera service disposed successfully');
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('[CameraService] Cannot toggle flash: Camera not initialized');
      return;
    }

    try {
      final currentFlashMode = _controller!.value.flashMode;
      final newFlashMode = currentFlashMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;

      await _controller!.setFlashMode(newFlashMode);
      debugPrint('[CameraService] Flash mode changed to: $newFlashMode');
    } catch (e) {
      debugPrint('[CameraService] ERROR: Failed to toggle flash - $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) {
      debugPrint('[CameraService] Cannot switch: No other camera available');
      return;
    }

    try {
      debugPrint('[CameraService] Switching camera...');
      final currentCamera = _controller?.description;
      final newCamera = _cameras.firstWhere(
        (camera) => camera != currentCamera,
        orElse: () => _cameras.first,
      );

      await dispose();
      await initializeCamera(camera: newCamera);
      debugPrint('[CameraService] Camera switched successfully');
    } catch (e) {
      debugPrint('[CameraService] ERROR: Failed to switch camera - $e');
    }
  }
}

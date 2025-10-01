import 'package:camera/camera.dart';
import 'package:logger/logger.dart';

class CameraService {
  static final Logger _logger = Logger();
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
      _cameras = await availableCameras();
      _logger.i('Found ${_cameras.length} cameras');
    } catch (e) {
      _logger.e('Error getting cameras: $e');
    }
  }

  Future<bool> initializeCamera({
    CameraDescription? camera,
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    try {
      if (_cameras.isEmpty) {
        await initializeCameras();
      }

      if (_cameras.isEmpty) {
        _logger.e('No cameras available');
        return false;
      }

      final selectedCamera = camera ?? _cameras.first;

      _controller = CameraController(
        selectedCamera,
        resolution,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _logger.i('Camera initialized successfully');
      return true;
    } catch (e) {
      _logger.e('Error initializing camera: $e');
      return false;
    }
  }

  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      _logger.e('Camera not initialized');
      return null;
    }

    try {
      final image = await _controller!.takePicture();
      _logger.i('Picture taken: ${image.path}');
      return image;
    } catch (e) {
      _logger.e('Error taking picture: $e');
      return null;
    }
  }

  Future<void> startImageStream(
    Function(CameraImage) onImage,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      _logger.e('Camera not initialized');
      return;
    }

    try {
      await _controller!.startImageStream(onImage);
      _logger.i('Image stream started');
    } catch (e) {
      _logger.e('Error starting image stream: $e');
    }
  }

  Future<void> stopImageStream() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
        _logger.i('Image stream stopped');
      }
    } catch (e) {
      _logger.e('Error stopping image stream: $e');
    }
  }

  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
    _logger.i('Camera service disposed');
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final currentFlashMode = _controller!.value.flashMode;
      final newFlashMode = currentFlashMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;

      await _controller!.setFlashMode(newFlashMode);
      _logger.i('Flash mode changed to: $newFlashMode');
    } catch (e) {
      _logger.e('Error toggling flash: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) {
      _logger.w('No other camera available');
      return;
    }

    try {
      final currentCamera = _controller?.description;
      final newCamera = _cameras.firstWhere(
        (camera) => camera != currentCamera,
        orElse: () => _cameras.first,
      );

      await dispose();
      await initializeCamera(camera: newCamera);
    } catch (e) {
      _logger.e('Error switching camera: $e');
    }
  }
}

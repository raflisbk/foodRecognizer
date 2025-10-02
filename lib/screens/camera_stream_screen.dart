import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image/image.dart' as img;
import '../constants/app_theme.dart';
import '../providers/camera_provider.dart';
import '../providers/classification_provider.dart';

class CameraStreamScreen extends ConsumerStatefulWidget {
  const CameraStreamScreen({super.key});

  @override
  ConsumerState<CameraStreamScreen> createState() => _CameraStreamScreenState();
}

class _CameraStreamScreenState extends ConsumerState<CameraStreamScreen> {
  bool _isProcessing = false;
  bool _isDisposed = false; // Flag to prevent processing after dispose
  String? _currentLabel;
  double? _currentConfidence;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await ref.read(cameraProvider.notifier).initialize();
    if (mounted && ref.read(cameraProvider).isInitialized) {
      _startStreaming();
    }
  }

  void _startStreaming() {
    ref.read(cameraProvider.notifier).startStreaming(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    // CRITICAL: Early exit if disposed - prevents buffer leak
    if (_isDisposed || _isProcessing || !mounted) {
      return;
    }

    // Use try-catch to safely set state
    try {
      if (_isDisposed || !mounted) return;

      setState(() {
        _isProcessing = true;
      });
    } catch (e) {
      // State might be disposed, exit immediately
      return;
    }

    try {
      // Check if disposed before heavy processing
      if (_isDisposed || !mounted) return;

      // Convert CameraImage to Uint8List
      final bytes = _convertCameraImage(cameraImage);

      // Check again after conversion (could take time)
      if (_isDisposed || !mounted) return;

      if (bytes != null) {
        // Classify image
        await ref
            .read(classificationProvider.notifier)
            .classifyImageBytes(bytes);

        // Check if disposed after async classification
        if (_isDisposed || !mounted) return;

        final prediction = ref.read(classificationProvider).prediction;
        if (prediction != null && !_isDisposed && mounted) {
          try {
            setState(() {
              _currentLabel = prediction.label;
              _currentConfidence = prediction.confidence;
            });
          } catch (e) {
            // Widget might be disposed, ignore
          }
        }
      }
    } catch (e) {
      // Handle error silently, but log it
      debugPrint('[CameraStream] Error processing image: $e');
    } finally {
      // Add delay before next frame, but only if not disposed
      if (!_isDisposed && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Reset processing flag only if not disposed
      if (!_isDisposed && mounted) {
        try {
          setState(() {
            _isProcessing = false;
          });
        } catch (e) {
          // Widget disposed, ignore
        }
      }
    }
  }

  Uint8List? _convertCameraImage(CameraImage cameraImage) {
    try {
      final int width = cameraImage.width;
      final int height = cameraImage.height;

      // Convert YUV to RGB
      final img.Image image = img.Image(width: width, height: height);

      final int uvRowStride = cameraImage.planes[1].bytesPerRow;
      final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int uvIndex =
              uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yp = cameraImage.planes[0].bytes[index];
          final up = cameraImage.planes[1].bytes[uvIndex];
          final vp = cameraImage.planes[2].bytes[uvIndex];

          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
              .round()
              .clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

          image.setPixelRgb(x, y, r, g, b);
        }
      }

      return Uint8List.fromList(img.encodeJpg(image));
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    debugPrint('[CameraStream] Disposing screen - stopping all processes');

    // CRITICAL: Set disposed flag FIRST to stop all processing immediately
    // This prevents any queued camera frames from being processed
    _isDisposed = true;

    // Reset processing flags
    _isProcessing = false;
    _currentLabel = null;
    _currentConfidence = null;

    // Stop camera stream
    // Any frames already in the queue will see _isDisposed = true and exit early
    try {
      ref.read(cameraProvider.notifier).stopStreaming();
    } catch (e) {
      debugPrint('[CameraStream] Error stopping stream: $e');
    }

    debugPrint('[CameraStream] All processes stopped, screen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraProvider);
    final cameraService = ref.read(cameraServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (cameraService.controller != null &&
              cameraService.controller!.value.isInitialized)
            Positioned.fill(child: CameraPreview(cameraService.controller!))
          else
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),

          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      FadeInLeft(
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Spacer(),
                      FadeInRight(
                        child: IconButton(
                          icon: Icon(
                            cameraState.isFlashOn
                                ? Icons.flash_on
                                : Icons.flash_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            ref.read(cameraProvider.notifier).toggleFlash();
                          },
                        ),
                      ),
                      FadeInRight(
                        delay: const Duration(milliseconds: 100),
                        child: IconButton(
                          icon: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            ref.read(cameraProvider.notifier).switchCamera();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Detection result
                if (_currentLabel != null && _currentConfidence != null)
                  FadeInUp(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.9),
                            AppTheme.secondaryColor.withValues(alpha: 0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Detected:',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentLabel!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text(
                                'Confidence:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: _currentConfidence,
                                    backgroundColor: Colors.white24,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(_currentConfidence! * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Positioned(
              top: 100,
              right: 20,
              child: FadeIn(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Processing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

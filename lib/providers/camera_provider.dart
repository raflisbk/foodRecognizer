import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/camera_service.dart';
import '../screens/crop_screen.dart';

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((
  ref,
) {
  return CameraNotifier(ref.read(cameraServiceProvider));
});

class CameraState {
  final bool isInitialized;
  final bool isStreaming;
  final File? capturedImage;
  final String? error;
  final bool isFlashOn;

  CameraState({
    this.isInitialized = false,
    this.isStreaming = false,
    this.capturedImage,
    this.error,
    this.isFlashOn = false,
  });

  CameraState copyWith({
    bool? isInitialized,
    bool? isStreaming,
    File? capturedImage,
    String? error,
    bool? isFlashOn,
    bool clearImage = false,
  }) {
    return CameraState(
      isInitialized: isInitialized ?? this.isInitialized,
      isStreaming: isStreaming ?? this.isStreaming,
      capturedImage: clearImage ? null : (capturedImage ?? this.capturedImage),
      error: error,
      isFlashOn: isFlashOn ?? this.isFlashOn,
    );
  }
}

class CameraNotifier extends StateNotifier<CameraState> {
  final CameraService _cameraService;
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  CameraNotifier(this._cameraService) : super(CameraState());

  Future<void> initialize() async {
    try {
      final success = await _cameraService.initializeCamera();
      state = state.copyWith(
        isInitialized: success,
        error: success ? null : 'Failed to initialize camera',
      );
    } catch (e) {
      debugPrint('[CameraProvider] ERROR: Failed to initialize camera - $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> takePicture() async {
    try {
      final image = await _cameraService.takePicture();
      if (image != null) {
        state = state.copyWith(capturedImage: File(image.path));
      }
    } catch (e) {
      debugPrint('[CameraProvider] ERROR: Failed to take picture - $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      // Request permission based on Android version
      Permission permission;

      // For Android 13+ (API 33+), use photos permission
      // For Android 12 and below, use storage permission
      if (Platform.isAndroid) {
        try {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          if (androidInfo.version.sdkInt >= 33) {
            permission = Permission.photos;
          } else {
            permission = Permission.storage;
          }
        } catch (e) {
          debugPrint('[FoodRecognizer] Error getting device info: $e');
          state = state.copyWith(
            error: 'Failed to check Android version. Please try again.',
          );
          return;
        }
      } else {
        permission = Permission.photos;
      }

      final status = await permission.request();

      if (status.isDenied) {
        state = state.copyWith(
          error:
              'Permission denied. App needs gallery access to select photos. '
              'Please allow access when prompted.',
        );
        debugPrint('[FoodRecognizer] Permission denied');
        return;
      }

      if (status.isPermanentlyDenied) {
        state = state.copyWith(
          error:
              'Gallery permission permanently denied. Open Settings > Apps > NutriSnap > '
              'Permissions > Photos, then enable gallery access.',
        );
        debugPrint('[FoodRecognizer] Permission permanently denied');
        return;
      }

      if (status.isRestricted) {
        state = state.copyWith(
          error:
              'Gallery access restricted by system. Check parental control settings or '
              'device restrictions.',
        );
        debugPrint('[FoodRecognizer] Permission restricted');
        return;
      }

      if (status.isLimited) {
        debugPrint('[FoodRecognizer] Permission limited, but can proceed');
      }

      debugPrint('[FoodRecognizer] Permission granted, opening gallery...');

      try {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );

        if (image != null) {
          debugPrint('[FoodRecognizer] Image selected: ${image.path}');

          // Verify file exists and readable
          final file = File(image.path);
          if (!await file.exists()) {
            state = state.copyWith(
              error: 'Image file not found. Please select another image.',
            );
            return;
          }

          final fileSize = await file.length();
          if (fileSize == 0) {
            state = state.copyWith(
              error:
                  'Image file is empty or corrupted. Please select another image.',
            );
            return;
          }

          if (fileSize > 10 * 1024 * 1024) {
            state = state.copyWith(
              error:
                  'Image size too large (max 10MB). Please select a smaller image.',
            );
            return;
          }

          // Log analytics event for gallery selection
          await _analytics.logEvent(
            name: 'image_selected',
            parameters: {
              'source': 'gallery',
              'file_size_kb': (fileSize / 1024).toStringAsFixed(2),
            },
          );

          state = state.copyWith(capturedImage: file);
        } else {
          debugPrint('[FoodRecognizer] User canceled image selection');
          // Clear any previous errors when user cancels
          state = state.copyWith(error: null);
        }
      } catch (pickerError) {
        debugPrint('[FoodRecognizer] Error opening gallery: $pickerError');
        if (pickerError.toString().contains('photo_access_denied')) {
          state = state.copyWith(
            error:
                'Gallery access denied by system. Check app permission settings.',
          );
        } else if (pickerError.toString().contains('No Activity found')) {
          state = state.copyWith(
            error:
                'Gallery app not found. Ensure device has a gallery app installed.',
          );
        } else {
          state = state.copyWith(
            error:
                'Failed to open gallery. Error: ${pickerError.toString().substring(0, 50)}...',
          );
        }
      }
    } on PlatformException catch (platformError) {
      debugPrint('[FoodRecognizer] Platform error: $platformError');
      state = state.copyWith(
        error:
            'System error occurred: ${platformError.message ?? "Unknown error"}. '
            'Please restart the app.',
      );
    } catch (e) {
      debugPrint('[FoodRecognizer] Unexpected error: $e');
      state = state.copyWith(
        error:
            'Unexpected error occurred. Please try again or restart the app.',
      );
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final status = await Permission.camera.request();

      if (status.isDenied) {
        state = state.copyWith(
          error:
              'Permission denied. App needs camera access to take photos. '
              'Please allow access when prompted.',
        );
        debugPrint('[FoodRecognizer] Camera permission denied');
        return;
      }

      if (status.isPermanentlyDenied) {
        state = state.copyWith(
          error:
              'Camera permission permanently denied. Open Settings > Apps > NutriSnap > '
              'Permissions > Camera, then enable camera access.',
        );
        debugPrint('[FoodRecognizer] Camera permission permanently denied');
        return;
      }

      if (status.isRestricted) {
        state = state.copyWith(
          error:
              'Camera access restricted by system. Check parental control settings or '
              'device restrictions.',
        );
        debugPrint('[FoodRecognizer] Camera permission restricted');
        return;
      }

      debugPrint(
        '[FoodRecognizer] Camera permission granted, opening camera...',
      );

      try {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          preferredCameraDevice: CameraDevice.rear,
        );

        if (image != null) {
          debugPrint(
            '[FoodRecognizer] Photo captured successfully: ${image.path}',
          );

          // Verify file
          final file = File(image.path);
          if (!await file.exists()) {
            state = state.copyWith(
              error: 'Photo file not found. Please try again.',
            );
            return;
          }

          final fileSize = await file.length();
          if (fileSize == 0) {
            state = state.copyWith(
              error: 'Photo file is empty or failed to save. Please try again.',
            );
            return;
          }

          // Log analytics event for camera capture
          await _analytics.logEvent(
            name: 'image_selected',
            parameters: {
              'source': 'camera',
              'file_size_kb': (fileSize / 1024).toStringAsFixed(2),
            },
          );

          state = state.copyWith(capturedImage: file);
        } else {
          debugPrint('[FoodRecognizer] User canceled photo capture');
          // Clear any previous errors when user cancels
          state = state.copyWith(error: null);
        }
      } catch (cameraError) {
        debugPrint('[FoodRecognizer] Error using camera: $cameraError');
        if (cameraError.toString().contains('camera_access_denied')) {
          state = state.copyWith(
            error:
                'Camera access denied by system. Check app permission settings.',
          );
        } else if (cameraError.toString().contains('No Activity found')) {
          state = state.copyWith(
            error:
                'Camera app not found. Ensure device has a camera app installed.',
          );
        } else if (cameraError.toString().contains('already in use')) {
          state = state.copyWith(
            error:
                'Camera is being used by another app. Close that app and try again.',
          );
        } else {
          state = state.copyWith(
            error: 'Failed to open camera. Please try again or restart device.',
          );
        }
      }
    } on PlatformException catch (platformError) {
      debugPrint('[FoodRecognizer] Platform error: $platformError');
      state = state.copyWith(
        error:
            'System error occurred: ${platformError.message ?? "Unknown error"}. '
            'Please restart the app.',
      );
    } catch (e) {
      debugPrint('[FoodRecognizer] Unexpected error: $e');
      state = state.copyWith(
        error:
            'Unexpected error occurred. Please try again or restart the app.',
      );
    }
  }

  Future<File?> cropImage(BuildContext context) async {
    if (state.capturedImage == null) {
      debugPrint('[CameraProvider] No captured image to crop');
      return null;
    }

    try {
      final originalPath = state.capturedImage!.path;
      debugPrint('[CameraProvider] Opening crop editor for: $originalPath');

      // Navigate ke CropScreen untuk crop image dengan SafeArea yang proper
      final croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => CropScreen(imageFile: state.capturedImage!),
        ),
      );

      debugPrint('[CameraProvider] Returned from crop screen');

      if (croppedFile != null) {
        final croppedPath = croppedFile.path;
        final isDifferent = croppedPath != originalPath;

        debugPrint('[CameraProvider] Original: $originalPath');
        debugPrint('[CameraProvider] Cropped:  $croppedPath');
        debugPrint('[CameraProvider] Is different: $isDifferent');

        if (isDifferent) {
          debugPrint('[CameraProvider] Image cropped successfully');

          // Log analytics event for image cropping (wrapped in try-catch to prevent blocking)
          try {
            await _analytics.logEvent(
              name: 'image_cropped',
              parameters: {
                'success':
                    1, // Firebase Analytics requires num or String, not bool
                'file_size_kb': (await croppedFile.length() / 1024)
                    .toStringAsFixed(2),
              },
            );
          } catch (analyticsError) {
            debugPrint(
              '[CameraProvider] Analytics logging failed (non-critical): $analyticsError',
            );
          }
        } else {
          debugPrint('[CameraProvider] Same image returned (no crop applied)');
        }

        // CRITICAL: Force update state dengan clearImage dulu untuk trigger rebuild
        debugPrint('[CameraProvider] Updating state with cropped image');
        state = state.copyWith(clearImage: true); // Clear dulu
        await Future.delayed(Duration(milliseconds: 50)); // Small delay
        state = state.copyWith(capturedImage: croppedFile); // Set baru

        debugPrint('[CameraProvider] State updated successfully');
        return croppedFile;
      } else {
        debugPrint('[CameraProvider] Crop canceled, keeping original');
        return state.capturedImage;
      }
    } catch (e) {
      debugPrint('[CameraProvider] Error in crop flow: $e');
      return state.capturedImage;
    }
  }

  Future<void> startStreaming(Function(CameraImage) onImage) async {
    try {
      await _cameraService.startImageStream(onImage);
      state = state.copyWith(isStreaming: true);
    } catch (e) {
      debugPrint('[CameraProvider] ERROR: Failed to start image stream - $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopStreaming() async {
    try {
      debugPrint('[CameraProvider] Stopping camera stream...');
      await _cameraService.stopImageStream();
      state = state.copyWith(isStreaming: false);
      debugPrint('[CameraProvider] Camera stream stopped successfully');
    } catch (e) {
      debugPrint('[CameraProvider] ERROR: Failed to stop image stream - $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleFlash() async {
    await _cameraService.toggleFlash();
    state = state.copyWith(isFlashOn: !state.isFlashOn);
  }

  Future<void> switchCamera() async {
    await _cameraService.switchCamera();
  }

  void clearImage() {
    state = state.copyWith(clearImage: true);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}

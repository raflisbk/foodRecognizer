import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/camera_service.dart';

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((ref) {
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
  final Logger _logger = Logger();
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
      _logger.e('Error initializing camera: $e');
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
      _logger.e('Error taking picture: $e');
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
          state = state.copyWith(error: 'Gagal memeriksa versi Android. Silakan coba lagi.');
          return;
        }
      } else {
        permission = Permission.photos;
      }

      final status = await permission.request();

      if (status.isDenied) {
        state = state.copyWith(
          error: 'Izin ditolak. Aplikasi memerlukan akses galeri untuk memilih foto. '
                 'Silakan izinkan akses saat diminta.'
        );
        debugPrint('[FoodRecognizer] Permission denied');
        return;
      }

      if (status.isPermanentlyDenied) {
        state = state.copyWith(
          error: 'Izin galeri ditolak permanen. Buka Pengaturan > Aplikasi > Food Recognizer > '
                 'Izin > Foto, lalu aktifkan akses galeri.'
        );
        debugPrint('[FoodRecognizer] Permission permanently denied');
        return;
      }

      if (status.isRestricted) {
        state = state.copyWith(
          error: 'Akses galeri dibatasi oleh sistem. Periksa pengaturan parental control atau '
                 'pembatasan perangkat Anda.'
        );
        debugPrint('[FoodRecognizer] Permission restricted');
        return;
      }

      if (status.isLimited) {
        debugPrint('[FoodRecognizer] Permission limited, but can proceed');
      }

      debugPrint('[FoodRecognizer] Permission granted, membuka galeri...');

      try {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );

        if (image != null) {
          debugPrint('[FoodRecognizer] Gambar dipilih: ${image.path}');

          // Verify file exists and readable
          final file = File(image.path);
          if (!await file.exists()) {
            state = state.copyWith(error: 'File gambar tidak ditemukan. Silakan pilih gambar lain.');
            return;
          }

          final fileSize = await file.length();
          if (fileSize == 0) {
            state = state.copyWith(error: 'File gambar kosong atau rusak. Silakan pilih gambar lain.');
            return;
          }

          if (fileSize > 10 * 1024 * 1024) {
            state = state.copyWith(error: 'Ukuran gambar terlalu besar (maks 10MB). Silakan pilih gambar yang lebih kecil.');
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
          debugPrint('[FoodRecognizer] User membatalkan pemilihan gambar');
        }
      } catch (pickerError) {
        debugPrint('[FoodRecognizer] Error saat membuka galeri: $pickerError');
        if (pickerError.toString().contains('photo_access_denied')) {
          state = state.copyWith(
            error: 'Akses galeri ditolak oleh sistem. Periksa pengaturan izin aplikasi.'
          );
        } else if (pickerError.toString().contains('No Activity found')) {
          state = state.copyWith(
            error: 'Aplikasi galeri tidak ditemukan. Pastikan perangkat memiliki aplikasi galeri.'
          );
        } else {
          state = state.copyWith(
            error: 'Gagal membuka galeri. Error: ${pickerError.toString().substring(0, 50)}...'
          );
        }
      }
    } on PlatformException catch (platformError) {
      debugPrint('[FoodRecognizer] Platform error: $platformError');
      state = state.copyWith(
        error: 'Terjadi kesalahan sistem: ${platformError.message ?? "Unknown error"}. '
               'Silakan restart aplikasi.'
      );
    } catch (e) {
      debugPrint('[FoodRecognizer] Unexpected error: $e');
      state = state.copyWith(
        error: 'Terjadi kesalahan tidak terduga. Silakan coba lagi atau restart aplikasi.'
      );
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final status = await Permission.camera.request();

      if (status.isDenied) {
        state = state.copyWith(
          error: 'Izin ditolak. Aplikasi memerlukan akses kamera untuk mengambil foto. '
                 'Silakan izinkan akses saat diminta.'
        );
        debugPrint('[FoodRecognizer] Camera permission denied');
        return;
      }

      if (status.isPermanentlyDenied) {
        state = state.copyWith(
          error: 'Izin kamera ditolak permanen. Buka Pengaturan > Aplikasi > Food Recognizer > '
                 'Izin > Kamera, lalu aktifkan akses kamera.'
        );
        debugPrint('[FoodRecognizer] Camera permission permanently denied');
        return;
      }

      if (status.isRestricted) {
        state = state.copyWith(
          error: 'Akses kamera dibatasi oleh sistem. Periksa pengaturan parental control atau '
                 'pembatasan perangkat Anda.'
        );
        debugPrint('[FoodRecognizer] Camera permission restricted');
        return;
      }

      debugPrint('[FoodRecognizer] Camera permission granted, membuka kamera...');

      try {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          preferredCameraDevice: CameraDevice.rear,
        );

        if (image != null) {
          debugPrint('[FoodRecognizer] Foto berhasil diambil: ${image.path}');

          // Verify file
          final file = File(image.path);
          if (!await file.exists()) {
            state = state.copyWith(error: 'File foto tidak ditemukan. Silakan coba lagi.');
            return;
          }

          final fileSize = await file.length();
          if (fileSize == 0) {
            state = state.copyWith(error: 'File foto kosong atau gagal disimpan. Silakan coba lagi.');
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
          debugPrint('[FoodRecognizer] User membatalkan pengambilan foto');
        }
      } catch (cameraError) {
        debugPrint('[FoodRecognizer] Error saat menggunakan kamera: $cameraError');
        if (cameraError.toString().contains('camera_access_denied')) {
          state = state.copyWith(
            error: 'Akses kamera ditolak oleh sistem. Periksa pengaturan izin aplikasi.'
          );
        } else if (cameraError.toString().contains('No Activity found')) {
          state = state.copyWith(
            error: 'Aplikasi kamera tidak ditemukan. Pastikan perangkat memiliki aplikasi kamera.'
          );
        } else if (cameraError.toString().contains('already in use')) {
          state = state.copyWith(
            error: 'Kamera sedang digunakan aplikasi lain. Tutup aplikasi tersebut dan coba lagi.'
          );
        } else {
          state = state.copyWith(
            error: 'Gagal membuka kamera. Silakan coba lagi atau restart perangkat.'
          );
        }
      }
    } on PlatformException catch (platformError) {
      debugPrint('[FoodRecognizer] Platform error: $platformError');
      state = state.copyWith(
        error: 'Terjadi kesalahan sistem: ${platformError.message ?? "Unknown error"}. '
               'Silakan restart aplikasi.'
      );
    } catch (e) {
      debugPrint('[FoodRecognizer] Unexpected error: $e');
      state = state.copyWith(
        error: 'Terjadi kesalahan tidak terduga. Silakan coba lagi atau restart aplikasi.'
      );
    }
  }

  Future<void> cropImage() async {
    if (state.capturedImage == null) return;

    try {
      debugPrint('[FoodRecognizer] Membuka editor crop gambar...');
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: state.capturedImage!.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Gambar',
            toolbarColor: Color(0xFFFF6B6B),
            toolbarWidgetColor: Color(0xFFFFFFFF),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Edit Gambar',
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (croppedFile != null) {
        debugPrint('[FoodRecognizer] Gambar berhasil di-crop');

        // Log analytics event for image cropping
        await _analytics.logEvent(
          name: 'image_cropped',
          parameters: {'success': true},
        );

        state = state.copyWith(capturedImage: File(croppedFile.path));
      } else {
        debugPrint('[FoodRecognizer] Crop dibatalkan, menggunakan gambar asli');
      }
    } catch (e) {
      debugPrint('[FoodRecognizer] Gagal memotong gambar, lanjutkan dengan gambar asli');
      // Tidak perlu set error, biarkan user lanjut tanpa crop
    }
  }

  Future<void> startStreaming(Function(CameraImage) onImage) async {
    try {
      await _cameraService.startImageStream(onImage);
      state = state.copyWith(isStreaming: true);
    } catch (e) {
      _logger.e('Error starting stream: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopStreaming() async {
    try {
      await _cameraService.stopImageStream();
      state = state.copyWith(isStreaming: false);
    } catch (e) {
      _logger.e('Error stopping stream: $e');
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

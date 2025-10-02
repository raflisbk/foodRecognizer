import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import '../constants/app_theme.dart';

class CropScreen extends StatefulWidget {
  final File imageFile;

  const CropScreen({super.key, required this.imageFile});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  bool _isProcessing = false;
  bool _hasStartedCrop = false; // Flag untuk mencegah multiple crop calls

  @override
  void initState() {
    super.initState();
    // Set status bar color saat masuk crop screen
    // PENTING: Set statusBarColor ke warna yang sama dengan toolbar crop
    // dan pastikan tidak transparan agar toolbar tidak tertutup
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppTheme.primaryColor, // Solid color, tidak transparan
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Set ElevationOverlay untuk memastikan status bar tidak overlay
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    // Langsung panggil crop di initState, sekali saja
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasStartedCrop) {
        _hasStartedCrop = true;
        _cropImage();
      }
    });
  }

  @override
  void dispose() {
    // Kembalikan status bar ke setting semula saat keluar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  Future<void> _cropImage() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppTheme.primaryColor,
            toolbarWidgetColor: Colors.white,
            statusBarLight: false,
            activeControlsWidgetColor: AppTheme.primaryColor,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            cropFrameColor: AppTheme.primaryColor,
            cropGridColor: Colors.white,
            backgroundColor: Colors.black,
            dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
            cropFrameStrokeWidth: 3,
            cropGridStrokeWidth: 1,
            showCropGrid: true,
            // PENTING: Setting ini untuk mengatasi masalah toolbar tertutup status bar
            // Gunakan immersive mode agar toolbar tidak bentrok dengan system UI
            // Setting androidX compat untuk edge-to-edge
          ),
          IOSUiSettings(
            title: 'Crop Image',
            minimumAspectRatio: 1.0,
            hidesNavigationBar: false,
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
          ),
        ],
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (croppedFile != null) {
          debugPrint('[CropScreen] Crop successful');
          debugPrint('[CropScreen] Original path: ${widget.imageFile.path}');
          debugPrint('[CropScreen] Cropped path: ${croppedFile.path}');

          // Return cropped image
          final resultFile = File(croppedFile.path);
          debugPrint('[CropScreen] Returning cropped file to caller');
          Navigator.pop(context, resultFile);
        } else {
          debugPrint('[CropScreen] User cancelled crop, returning original');
          Navigator.pop(context, widget.imageFile);
        }
      }
    } catch (e) {
      debugPrint('[CropScreen] Error cropping image: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        Navigator.pop(context, widget.imageFile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar dengan SafeArea dan padding yang jelas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tombol Cancel
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isProcessing
                          ? null
                          : () => Navigator.pop(context, widget.imageFile),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.close, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Title
                  const Text(
                    'Crop Image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Tombol Done (placeholder untuk balance)
                  Opacity(
                    opacity: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, size: 24),
                          SizedBox(width: 8),
                          Text('Done', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Image Preview
            Expanded(
              child: Center(
                child: _isProcessing
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Opening crop editor...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      )
                    : Image.file(widget.imageFile, fit: BoxFit.contain),
              ),
            ),

            // Bottom info
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Crop tool will open automatically',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

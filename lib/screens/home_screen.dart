import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../constants/app_theme.dart';
import '../providers/camera_provider.dart';
import '../providers/classification_provider.dart';
import 'camera_screen.dart';
import 'camera_stream_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize classification service with Firebase ML
      ref.read(classificationProvider.notifier).initialize(useFirebaseModel: true);
    });
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Oops!'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classificationState = ref.watch(classificationProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.surfaceGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Food Recognizer',
                        style: AppTheme.headlineLarge.copyWith(
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kenali makanan Anda dengan AI',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Status indicator
              if (classificationState.isLoading)
                FadeIn(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.secondaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            classificationState.useFirebaseModel
                                ? 'Mengunduh model AI dari cloud...'
                                : 'Memuat model AI...',
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (classificationState.isInitialized)
                FadeIn(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.successContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.successColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.successColor,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            classificationState.useFirebaseModel
                                ? 'Siap! Menggunakan model AI terbaru'
                                : 'Siap! Model AI sudah dimuat',
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (classificationState.error != null)
                FadeIn(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.errorColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: AppTheme.errorColor,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Ada kendala: ${classificationState.error}',
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Gallery button
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: _ModernActionButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Pilih dari Galeri',
                        isPrimary: true,
                        onTap: () async {
                          _showLoadingDialog(context, 'Membuka galeri...');
                          await ref.read(cameraProvider.notifier).pickImageFromGallery();
                          if (mounted) {
                            Navigator.pop(context); // Close loading
                            if (ref.read(cameraProvider).capturedImage != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CameraScreen(),
                                ),
                              );
                            } else if (ref.read(cameraProvider).error != null) {
                              _showErrorDialog(context, ref.read(cameraProvider).error!);
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Camera button
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: _ModernActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Ambil Foto',
                        isPrimary: false,
                        onTap: () async {
                          _showLoadingDialog(context, 'Membuka kamera...');
                          await ref.read(cameraProvider.notifier).pickImageFromCamera();
                          if (mounted) {
                            Navigator.pop(context); // Close loading
                            if (ref.read(cameraProvider).capturedImage != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CameraScreen(),
                                ),
                              );
                            } else if (ref.read(cameraProvider).error != null) {
                              _showErrorDialog(context, ref.read(cameraProvider).error!);
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Live camera button
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: _ModernActionButton(
                        icon: Icons.videocam_rounded,
                        label: 'Deteksi Langsung',
                        isTertiary: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CameraStreamScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isTertiary;

  const _ModernActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isTertiary = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color foregroundColor;
    final Color shadowColor;

    if (isPrimary) {
      backgroundColor = AppTheme.primaryContainer;
      foregroundColor = AppTheme.onPrimaryContainer;
      shadowColor = AppTheme.primaryColor;
    } else if (isTertiary) {
      backgroundColor = AppTheme.tertiaryContainer;
      foregroundColor = AppTheme.onTertiaryContainer;
      shadowColor = AppTheme.tertiaryColor;
    } else {
      backgroundColor = AppTheme.secondaryContainer;
      foregroundColor = AppTheme.onSecondaryContainer;
      shadowColor = AppTheme.secondaryColor;
    }

    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTheme.titleLarge.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    debugPrint('[HomeScreen] HomeScreen loaded - initializing ML model');
    // Use Future.microtask to defer initialization until after widget tree is built
    Future.microtask(() async {
      try {
        await ref
            .read(classificationProvider.notifier)
            .initialize(useFirebaseModel: true);
        debugPrint('[HomeScreen] ML model initialization complete');
      } catch (e) {
        debugPrint('[HomeScreen] ML model initialization failed: $e');
      }
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
              const CircularProgressIndicator(color: AppTheme.primaryColor),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.surfaceGradient),
        child: Stack(
          children: [
            // Decorative background graphics
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.08),
                      AppTheme.secondaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.secondaryColor.withValues(alpha: 0.06),
                      AppTheme.primaryColor.withValues(alpha: 0.04),
                    ],
                  ),
                ),
              ),
            ),
            // Additional decorative circles
            Positioned(
              top: 350,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.05),
                      AppTheme.secondaryColor.withValues(alpha: 0.03),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              right: 80,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.secondaryColor.withValues(alpha: 0.07),
                      AppTheme.primaryColor.withValues(alpha: 0.04),
                    ],
                  ),
                ),
              ),
            ),
            // Food and nutrition icons
            Positioned(
              top: 180,
              left: 35,
              child: Icon(
                Icons.restaurant_menu,
                size: 50,
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
            ),
            Positioned(
              top: 320,
              right: 45,
              child: Icon(
                Icons.set_meal,
                size: 45,
                color: AppTheme.secondaryColor.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              top: 500,
              left: 50,
              child: Icon(
                Icons.lunch_dining,
                size: 42,
                color: AppTheme.primaryColor.withValues(alpha: 0.09),
              ),
            ),
            Positioned(
              bottom: 320,
              right: 40,
              child: Icon(
                Icons.local_dining,
                size: 38,
                color: AppTheme.secondaryColor.withValues(alpha: 0.11),
              ),
            ),
            Positioned(
              bottom: 180,
              left: 45,
              child: Icon(
                Icons.fastfood,
                size: 40,
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              bottom: 420,
              right: 55,
              child: Icon(
                Icons.eco,
                size: 48,
                color: AppTheme.primaryColor.withValues(alpha: 0.09),
              ),
            ),
            Positioned(
              top: 600,
              right: 70,
              child: Icon(
                Icons.kitchen,
                size: 36,
                color: AppTheme.secondaryColor.withValues(alpha: 0.07),
              ),
            ),
            Positioned(
              bottom: 520,
              left: 60,
              child: Icon(
                Icons.emoji_food_beverage,
                size: 44,
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
            ),
            // Main content
            SafeArea(
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
                            width: 180,
                            height: 180,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/animations/splash_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Recognize your food with AI',
                            style: AppTheme.headlineMedium.copyWith(
                              color: AppTheme.onSurface,
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
                            label: 'Choose from Gallery',
                            isPrimary: true,
                            onTap: () async {
                              if (!context.mounted) return;
                              _showLoadingDialog(context, 'Opening gallery...');
                              await ref
                                  .read(cameraProvider.notifier)
                                  .pickImageFromGallery();
                              if (!context.mounted) return;
                              Navigator.pop(context); // Close loading
                              if (ref.read(cameraProvider).capturedImage !=
                                  null) {
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CameraScreen(),
                                  ),
                                );
                              } else if (ref.read(cameraProvider).error !=
                                  null) {
                                if (!context.mounted) return;
                                _showErrorDialog(
                                  context,
                                  ref.read(cameraProvider).error!,
                                );
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
                            label: 'Take Photo',
                            isPrimary: false,
                            onTap: () async {
                              if (!context.mounted) return;
                              _showLoadingDialog(context, 'Opening camera...');
                              await ref
                                  .read(cameraProvider.notifier)
                                  .pickImageFromCamera();
                              if (!context.mounted) return;
                              Navigator.pop(context); // Close loading
                              if (ref.read(cameraProvider).capturedImage !=
                                  null) {
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CameraScreen(),
                                  ),
                                );
                              } else if (ref.read(cameraProvider).error !=
                                  null) {
                                if (!context.mounted) return;
                                _showErrorDialog(
                                  context,
                                  ref.read(cameraProvider).error!,
                                );
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
                            label: 'Live Detection',
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
          ],
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
            color: shadowColor.withValues(alpha: 0.2),
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

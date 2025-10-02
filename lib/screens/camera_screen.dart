import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../constants/app_theme.dart';
import '../providers/camera_provider.dart';
import '../providers/classification_provider.dart';
import 'prediction_screen.dart';

class CameraScreen extends ConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraProvider);
    final classificationState = ref.watch(classificationProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            ref.read(cameraProvider.notifier).clearImage();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (cameraState.capturedImage != null)
            IconButton(
              icon: const Icon(Icons.crop, color: Colors.white),
              onPressed: () async {
                await ref.read(cameraProvider.notifier).cropImage(context);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Image preview
          Expanded(
            child: cameraState.capturedImage != null
                ? FadeIn(
                    duration: const Duration(milliseconds: 300),
                    child: Hero(
                      tag: 'food_image',
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.file(
                            cameraState.capturedImage!,
                            key: ValueKey(cameraState.capturedImage!.path),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('[CameraScreen] Error loading image: $error');
                              return const Center(
                                child: Icon(Icons.error, color: Colors.red, size: 48),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show analyzing indicator only during inference (not during model loading)
                  if (classificationState.isLoading && classificationState.isInitialized)
                    FadeIn(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Analyzing food...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                  // Show model loading indicator only when model is not ready
                  if (!classificationState.isInitialized)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Loading AI model...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Show buttons when model is ready (even if currently analyzing)
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (cameraState.capturedImage != null &&
                                   classificationState.isInitialized &&
                                   !classificationState.isLoading)
                            ? () async {
                                await ref
                                    .read(classificationProvider.notifier)
                                    .classifyImage(cameraState.capturedImage!);

                                if (context.mounted &&
                                    ref.read(classificationProvider).prediction != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PredictionScreen(
                                        imageFile: cameraState.capturedImage!,
                                        prediction: ref
                                            .read(classificationProvider)
                                            .prediction!,
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: classificationState.isLoading && classificationState.isInitialized
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.analytics),
                                  SizedBox(width: 12),
                                  Text(
                                    'Analyze Food',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: () {
                        ref.read(cameraProvider.notifier).clearImage();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Take Another Photo',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

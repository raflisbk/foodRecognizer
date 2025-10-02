import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../constants/app_theme.dart';
import 'home_screen.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint(
      '[InitializationScreen] Showing splash screen (model already loaded in main())',
    );
    // Just show splash screen briefly then navigate
    // Model is already initialized in main.dart before widget tree
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        debugPrint('[InitializationScreen] Navigating to HomeScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Don't watch here to avoid rebuild during initialization
    // Use read() in _initializeApp instead
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // App Name
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: const Text(
                  'NutriSnap',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tagline
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: const Text(
                  'AI-Powered Food Recognition',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Loading Indicator
              FadeIn(
                delay: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Loading AI model...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'This may take a few moments',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

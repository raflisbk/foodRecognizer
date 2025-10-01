import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_recognizer/screens/home_screen.dart';
import 'package:food_recognizer/providers/classification_provider.dart';
import 'package:food_recognizer/providers/camera_provider.dart';
import 'package:food_recognizer/constants/app_theme.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('HomeScreen should display app title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert
      expect(find.text('Food Recognizer'), findsOneWidget);
    });

    testWidgets('HomeScreen should display logo icon', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });

    testWidgets('HomeScreen should display welcome text', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Selamat Datang'), findsOneWidget);
    });

    testWidgets('HomeScreen should display instruction text', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Ambil atau pilih foto makanan'), findsOneWidget);
    });

    testWidgets('HomeScreen should have camera button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.text('Ambil Foto'), findsOneWidget);
    });

    testWidgets('HomeScreen should have gallery button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);
      expect(find.text('Pilih dari Galeri'), findsOneWidget);
    });

    testWidgets('HomeScreen should show loading state when initializing', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            classificationProvider.overrideWith(
              (ref) => _MockClassificationNotifier(
                ClassificationState(isLoading: true),
              ),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.textContaining('Mengunduh model'), findsOneWidget);
    });

    testWidgets('HomeScreen should show error state when initialization fails', (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Gagal memuat model AI';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            classificationProvider.overrideWith(
              (ref) => _MockClassificationNotifier(
                ClassificationState(error: errorMessage),
              ),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.textContaining(errorMessage), findsOneWidget);
    });

    testWidgets('HomeScreen should use correct theme colors', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.light(
                primary: AppTheme.primaryColor,
                secondary: AppTheme.secondaryColor,
              ),
            ),
            home: HomeScreen(),
          ),
        ),
      );

      // Assert
      final BuildContext context = tester.element(find.byType(HomeScreen));
      final theme = Theme.of(context);
      expect(theme.colorScheme.primary, AppTheme.primaryColor);
      expect(theme.colorScheme.secondary, AppTheme.secondaryColor);
    });

    testWidgets('Camera button should be tappable', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Act
      final cameraButton = find.ancestor(
        of: find.text('Ambil Foto'),
        matching: find.byType(FilledButton),
      );

      // Assert
      expect(cameraButton, findsOneWidget);
      expect(tester.widget<FilledButton>(cameraButton).onPressed, isNotNull);
    });

    testWidgets('Gallery button should be tappable', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Act
      final galleryButton = find.ancestor(
        of: find.text('Pilih dari Galeri'),
        matching: find.byType(FilledButton),
      );

      // Assert
      expect(galleryButton, findsOneWidget);
      expect(tester.widget<FilledButton>(galleryButton).onPressed, isNotNull);
    });
  });
}

// Mock ClassificationNotifier for testing
class _MockClassificationNotifier extends StateNotifier<ClassificationState> {
  _MockClassificationNotifier(ClassificationState state) : super(state);
}

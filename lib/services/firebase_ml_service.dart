import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import '../constants/api_constants.dart';

class FirebaseMLService {
  // Singleton pattern
  static final FirebaseMLService _instance = FirebaseMLService._internal();
  factory FirebaseMLService() => _instance;
  FirebaseMLService._internal();

  Future<String?> downloadModel() async {
    try {
      debugPrint('[FirebaseML] Starting model download from Firebase ML');
      debugPrint('[FirebaseML] Model name: ${ApiConstants.firebaseModelName}');
      debugPrint('[FirebaseML] Download type: Latest model');

      final model = await FirebaseModelDownloader.instance.getModel(
        ApiConstants.firebaseModelName,
        FirebaseModelDownloadType.latestModel,
        FirebaseModelDownloadConditions(
          iosAllowsCellularAccess: true,
          iosAllowsBackgroundDownloading: false,
          androidChargingRequired: false,
          androidWifiRequired: false,
          androidDeviceIdleRequired: false,
        ),
      );

      debugPrint('[FirebaseML] Model downloaded successfully');
      debugPrint('[FirebaseML] Model file path: ${model.file.path}');
      return model.file.path;
    } catch (e) {
      debugPrint(
        '[FirebaseML] ERROR: Failed to download model from Firebase - $e',
      );
      return null;
    }
  }

  Future<bool> deleteModel() async {
    try {
      debugPrint('[FirebaseML] Attempting to delete model');
      // Note: deleteModel method may not be available in some versions
      // Alternative: manually delete the model file
      final models = await FirebaseModelDownloader.instance
          .listDownloadedModels();
      final targetModel = models.firstWhere(
        (model) => model.name == ApiConstants.firebaseModelName,
        orElse: () => throw Exception('Model not found'),
      );

      // Delete the file manually
      final file = File(targetModel.file.path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[FirebaseML] Model deleted successfully');
        return true;
      }
      debugPrint('[FirebaseML] Model file does not exist');
      return false;
    } catch (e) {
      debugPrint('[FirebaseML] ERROR: Failed to delete model - $e');
      return false;
    }
  }

  Future<List<FirebaseCustomModel>> listDownloadedModels() async {
    try {
      debugPrint('[FirebaseML] Listing downloaded models');
      final models = await FirebaseModelDownloader.instance
          .listDownloadedModels();
      debugPrint('[FirebaseML] Found ${models.length} downloaded models');
      return models;
    } catch (e) {
      debugPrint('[FirebaseML] ERROR: Failed to list models - $e');
      return [];
    }
  }

  Future<bool> isModelDownloaded() async {
    try {
      final models = await listDownloadedModels();
      return models.any(
        (model) => model.name == ApiConstants.firebaseModelName,
      );
    } catch (e) {
      return false;
    }
  }
}

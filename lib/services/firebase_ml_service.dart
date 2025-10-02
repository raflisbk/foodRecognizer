import 'dart:io';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';

class FirebaseMLService {
  static final Logger _logger = Logger();

  // Singleton pattern
  static final FirebaseMLService _instance = FirebaseMLService._internal();
  factory FirebaseMLService() => _instance;
  FirebaseMLService._internal();

  Future<String?> downloadModel() async {
    try {
      _logger.i('[FirebaseML] Starting model download from Firebase ML');
      _logger.i('[FirebaseML] Model name: ${ApiConstants.firebaseModelName}');
      _logger.i('[FirebaseML] Download type: Latest model');

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

      _logger.i('[FirebaseML] Model downloaded successfully');
      _logger.i('[FirebaseML] Model file path: ${model.file.path}');
      return model.file.path;
    } catch (e) {
      _logger.e(
        '[FirebaseML] ERROR: Failed to download model from Firebase - $e',
      );
      return null;
    }
  }

  Future<bool> deleteModel() async {
    try {
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
        _logger.i('Model deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Error deleting model: $e');
      return false;
    }
  }

  Future<List<FirebaseCustomModel>> listDownloadedModels() async {
    try {
      final models = await FirebaseModelDownloader.instance
          .listDownloadedModels();
      _logger.i('Found ${models.length} downloaded models');
      return models;
    } catch (e) {
      _logger.e('Error listing models: $e');
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

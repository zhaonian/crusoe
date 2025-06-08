import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ModelDownloader {
  // Using the official Gemma 3 1B model from LiteRT community
  static const String _modelUrl = 
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task';
  static const String _modelFileName = 'gemma3-1b-it-int4.task';
  static const int _expectedModelSize = 529 * 1024 * 1024; // ~529MB
  
  /// Get the model path - prioritizes bundled asset, then downloads if needed
  static Future<String> downloadModel({
    required Function(double progress) onProgress,
    required Function(String status) onStatusUpdate,
  }) async {
    try {
      onStatusUpdate('Checking for bundled Gemma model...');
      
      // First, try to get the bundled model from assets
      String? modelPath = await _getBundledModelPath(onProgress, onStatusUpdate);
      if (modelPath != null) {
        onStatusUpdate('Using bundled Gemma model');
        onProgress(1.0);
        return modelPath;
      }
      
      // Fall back to download logic (not implemented yet, would need real HTTP download)
      onStatusUpdate('No bundled model found, download not implemented yet');
      throw Exception('Real model download not implemented. Please include model in assets/models/');
      
    } catch (e) {
      throw Exception('Failed to get model: $e');
    }
  }
  
  /// Try to get bundled model path from assets
  static Future<String?> _getBundledModelPath([
    Function(double progress)? onProgress,
    Function(String status)? onStatusUpdate,
  ]) async {
    try {
      // Check if the model exists in assets
      const assetPath = 'assets/models/gemma3-1b-it-int4.task';
      
      onStatusUpdate?.call('Checking for bundled model...');
      
      try {
        // Try to load the asset to verify it exists
        final assetData = await rootBundle.load(assetPath);
        debugPrint('📁 Found bundled model, size: ${assetData.lengthInBytes} bytes');
        
        // Get documents directory for copying the model
        final appDir = await getApplicationDocumentsDirectory();
        final modelDir = Directory(path.join(appDir.path, 'models'));
        
        if (!await modelDir.exists()) {
          await modelDir.create(recursive: true);
        }
        
        final modelFile = File(path.join(modelDir.path, _modelFileName));
        
        // Check if we already have the model copied and it's the right size
        if (await modelFile.exists()) {
          final fileSize = await modelFile.length();
          if (fileSize == assetData.lengthInBytes) {
            debugPrint('📁 Using existing copied model at: ${modelFile.path}');
            return modelFile.path;
          } else {
            debugPrint('📁 Model file size mismatch, re-copying...');
          }
        }
        
        // Copy the real asset to the file system
        onStatusUpdate?.call('Copying bundled model to device storage...');
        
        // Simulate progress for the copy operation
        if (onProgress != null) {
          for (int i = 0; i <= 10; i++) {
            await Future.delayed(Duration(milliseconds: 100));
            onProgress(i / 10.0);
          }
        }
        
        await modelFile.writeAsBytes(assetData.buffer.asUint8List());
        
        // Verify the copied file
        final copiedSize = await modelFile.length();
        debugPrint('📁 Copied bundled model to: ${modelFile.path}');
        debugPrint('📁 Original size: ${assetData.lengthInBytes}, Copied size: $copiedSize');
        
        if (copiedSize != assetData.lengthInBytes) {
          throw Exception('Model copy verification failed: size mismatch');
        }
        
        return modelFile.path;
      } catch (assetError) {
        debugPrint('❌ Asset not found or couldn\'t be loaded: $assetError');
        return null;
      }
      
    } catch (e) {
      debugPrint('Error accessing bundled model: $e');
      return null;
    }
  }
  
  /// Check if model exists locally
  static Future<String?> getLocalModelPath() async {
    try {
      // First check for bundled model
      String? bundledPath = await _getBundledModelPath();
      if (bundledPath != null) {
        return bundledPath;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error checking local model: $e');
      return null;
    }
  }
  
  /// Delete local model (for cleanup or re-download)
  static Future<void> deleteLocalModel() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File(path.join(appDir.path, 'models', _modelFileName));
      
      if (await modelFile.exists()) {
        await modelFile.delete();
        debugPrint('🗑️ Deleted local model file');
      }
    } catch (e) {
      debugPrint('Error deleting local model: $e');
    }
  }
} 
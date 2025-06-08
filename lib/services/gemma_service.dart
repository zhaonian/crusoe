import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'model_downloader.dart';

/// Service class for handling Gemma model operations
class GemmaService {
  static GemmaService? _instance;
  static GemmaService get instance => _instance ??= GemmaService._();
  
  GemmaService._();

  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isSimulationMode = false; // Track if we're in fallback mode
  String? _modelPath;
  InferenceModel? _inferenceModel;
  InferenceChat? _chatSession; // Maintain a single chat session

  /// Stream controller for model loading status
  final StreamController<ModelStatus> _statusController = StreamController<ModelStatus>.broadcast();
  Stream<ModelStatus> get statusStream => _statusController.stream;

  /// Initialize the Gemma model
  Future<bool> initialize({String? modelPath}) async {
    if (_isInitialized) return true;
    if (_isLoading) return false;

    _isLoading = true;
    _statusController.add(ModelStatus.loading);

    try {
      // Try to initialize flutter_gemma using the new API
      debugPrint('🤖 Attempting to load real Gemma model using new API...');
      
      try {
        final gemma = FlutterGemmaPlugin.instance;
        final modelManager = gemma.modelManager;
        
        // Install model from assets using the new API
        _statusController.add(ModelStatus.downloading);
        debugPrint('📦 Installing model from assets...');
        
        await modelManager.installModelFromAsset('models/gemma3-1b-it-int4.task');
        
        _statusController.add(ModelStatus.loading);
        debugPrint('🏗️ Creating inference model...');
        
        // Create the inference model with CORRECT API parameters
        _inferenceModel = await gemma.createModel(
          modelType: ModelType.gemmaIt,
          preferredBackend: PreferredBackend.gpu,
          maxTokens: 1024,
        );
        
        // Create a single chat session that will be reused
        debugPrint('💬 Creating persistent chat session...');
        _chatSession = await _inferenceModel!.createChat(
          temperature: 0.8,
          randomSeed: 42,
          topK: 40,
        );
        
        debugPrint('✅ Real Gemma model loaded successfully with new API');
        _isSimulationMode = false;
      } catch (modelError) {
        debugPrint('⚠️ Real model failed to load: $modelError');
        debugPrint('🔄 Falling back to simulation mode...');
        _isSimulationMode = true;
        _inferenceModel = null;
        _chatSession = null;
      }
      
      _isInitialized = true;
      _isLoading = false;
      
      _statusController.add(ModelStatus.ready);
      
      if (_isSimulationMode) {
        debugPrint('✅ Gemma service initialized in simulation mode');
      } else {
        debugPrint('✅ Gemma model initialized successfully with new API');
      }
      
      return true;
    } catch (e) {
      _isLoading = false;
      
      // Even if everything fails, fall back to simulation mode
      debugPrint('❌ Complete initialization failure: $e');
      debugPrint('🔄 Enabling simulation mode as final fallback...');
      
      _isSimulationMode = true;
      _isInitialized = true;
      _statusController.add(ModelStatus.ready);
      
      return true; // Return true because we can still work in simulation mode
    }
  }

  /// Generate a response from the model
  Future<String> generateResponse(String prompt) async {
    if (!_isInitialized) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    debugPrint('🔍 generateResponse called with prompt: "${prompt.substring(0, prompt.length.clamp(0, 50))}${prompt.length > 50 ? "..." : ""}"');

    try {
      _statusController.add(ModelStatus.generating);

      // If we have a real model, use it
      if (!_isSimulationMode && _chatSession != null) {
        debugPrint('🤖 Using real model for response generation...');
        debugPrint('💬 Using existing chat session...');
        
        // Add the user's query using the existing chat session
        await _chatSession!.addQueryChunk(Message(text: prompt, isUser: true));
        
        debugPrint('✏️ Query chunk added, generating response...');
        
        // Generate the response using the existing chat session
        final response = await _chatSession!.generateChatResponse();
        
        debugPrint('🤖 Real model response generated: "${response.substring(0, response.length.clamp(0, 100))}${response.length > 100 ? "..." : ""}"');
        debugPrint('📏 Response length: ${response.length} characters');
        
        _statusController.add(ModelStatus.ready);
        
        final trimmedResponse = response.trim();
        debugPrint('📋 Final trimmed response length: ${trimmedResponse.length} characters');
        
        return trimmedResponse;
      } else {
        // Use simulation mode
        debugPrint('🎭 Using simulation mode for response...');
        await Future.delayed(Duration(milliseconds: 500 + (prompt.length * 10))); // Simulate processing time
        final response = _generateSimulatedResponse(prompt);
        
        debugPrint('🎭 Simulation response generated: "$response"');
        _statusController.add(ModelStatus.ready);
        return response;
      }
    } catch (e) {
      debugPrint('❌ Generation error: $e, falling back to simulation');
      
      // Always fall back to simulation if anything fails
      await Future.delayed(Duration(milliseconds: 300));
      final fallbackResponse = _generateSimulatedResponse(prompt);
      _statusController.add(ModelStatus.ready);
      return "🎭 Simulation mode: $fallbackResponse";
    }
  }

  /// Generate a simulated response (fallback only)
  String _generateSimulatedResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    
    if (lowerPrompt.contains('hello') || lowerPrompt.contains('hi')) {
      return "Hello! I'm your offline AI assistant running in simulation mode. How can I help you today?";
    } else if (lowerPrompt.contains('weather')) {
      return "I'm running offline in simulation mode, so I can't check current weather. But I can help you with other questions!";
    } else if (lowerPrompt.contains('what') && lowerPrompt.contains('you')) {
      return "I'm Gemma running in simulation mode on your device. While the real model is being prepared, I can still help with various tasks like answering questions and conversations!";
    } else if (lowerPrompt.contains('code') || lowerPrompt.contains('program')) {
      return "I can help you with coding questions! What programming language or concept would you like assistance with?";
    } else if (lowerPrompt.contains('joke')) {
      return "Why don't scientists trust atoms? Because they make up everything! 😄 (This is from simulation mode!)";
    } else if (lowerPrompt.contains('explain')) {
      return "I'd be happy to explain that topic. Could you be more specific about what you'd like me to explain?";
    } else if (lowerPrompt.contains('model') || lowerPrompt.contains('simulation')) {
      return "I'm currently running in simulation mode because the real Gemma model couldn't be loaded. This allows you to test the chat interface while the model setup is being worked on!";
    } else {
      return "That's an interesting question! I'm running in simulation mode to provide you with responses while the real AI model is being set up. What else would you like to know?";
    }
  }

  /// Check if the model is ready to generate responses
  bool get isReady => _isInitialized && !_isLoading;

  /// Check if the model is currently loading
  bool get isLoading => _isLoading;

  /// Check if running in simulation mode
  bool get isSimulationMode => _isSimulationMode;

  /// Get current model path
  String? get modelPath => _modelPath;

  /// Dispose resources
  void dispose() {
    _statusController.close();
    _chatSession = null;
    _inferenceModel?.close();
    _inferenceModel = null;
  }
}

/// Enum representing the current status of the model
enum ModelStatus {
  idle,
  downloading,
  loading,
  ready,
  generating,
  error,
}

/// Extension to get human-readable status messages
extension ModelStatusExtension on ModelStatus {
  String get message {
    switch (this) {
      case ModelStatus.idle:
        return 'Model not loaded';
      case ModelStatus.downloading:
        return 'Installing model from assets...';
      case ModelStatus.loading:
        return 'Loading Gemma model...';
      case ModelStatus.ready:
        return 'Gemma ready';
      case ModelStatus.generating:
        return 'Generating response...';
      case ModelStatus.error:
        return 'Model error';
    }
  }

  /// Get status message with simulation mode context
  String getMessageWithContext(bool isSimulationMode) {
    switch (this) {
      case ModelStatus.idle:
        return 'Model not loaded';
      case ModelStatus.downloading:
        return 'Installing model from assets...';
      case ModelStatus.loading:
        return 'Loading Gemma model...';
      case ModelStatus.ready:
        return isSimulationMode ? 'Simulation mode' : 'Gemma ready';
      case ModelStatus.generating:
        return isSimulationMode ? 'Thinking... (simulation)' : 'Generating response...';
      case ModelStatus.error:
        return 'Model error';
    }
  }

  bool get isOperational => this == ModelStatus.ready || this == ModelStatus.generating;
} 
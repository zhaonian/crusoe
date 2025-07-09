import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import '../constants/model_constants.dart';

/// Service class for handling Gemma model operations
class GemmaService {
  static GemmaService? _instance;
  static GemmaService get instance => _instance ??= GemmaService._internal();

  GemmaService._internal();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _modelPath;
  InferenceModel? _inferenceModel;
  InferenceChat? _chatSession; // Maintain a single chat session

  // System prompt to make the AI smarter as an assistant
  static const String _defaultSystemPrompt =
      '''You are a helpful, intelligent, and knowledgeable AI assistant. Your goal is to provide accurate, useful, and engaging responses. Please:

• Be conversational and friendly while remaining professional
• Provide clear, well-structured answers
• Ask clarifying questions when the user's request is ambiguous
• Break down complex topics into understandable explanations
• Offer practical suggestions and actionable advice
• Admit when you don't know something rather than guessing
• Remember our conversation context and refer back to it when relevant
• Be concise but thorough - aim for helpful detail without being verbose
• Use examples when they help clarify your explanations

You are running offline on the user's device, so you cannot access real-time information or browse the internet. Focus on providing helpful responses based on your training knowledge.''';

  /// Stream controller for model loading status
  final StreamController<ModelStatus> _statusController =
      StreamController<ModelStatus>.broadcast();
  Stream<ModelStatus> get statusStream => _statusController.stream;

  /// Initialize the Gemma model with an optional system prompt
  Future<bool> initialize({String? modelPath, String? systemPrompt}) async {
    if (_isInitialized) return true;
    if (_isLoading) return false;

    _isLoading = true;
    _statusController.add(ModelStatus.loading);

    try {
      debugPrint('🤖 Loading Gemma model...');

      final gemma = FlutterGemmaPlugin.instance;
      final modelManager = gemma.modelManager;

      // Install model from assets
      _statusController.add(ModelStatus.downloading);
      debugPrint('📦 Installing model from assets...');

      await modelManager.installModelFromAsset(
        ModelConstants.gemma3_1b_it_int4,
      );

      _statusController.add(ModelStatus.loading);
      debugPrint('🏗️ Creating inference model...');

      // Create the inference model with platform-optimized backend
      final preferredBackend = Platform.isAndroid
          ? PreferredBackend
                .cpu // Android: Use CPU for stability
          : PreferredBackend.gpu; // iOS: Use GPU for performance

      debugPrint(
        '🔧 Using ${Platform.isAndroid ? "CPU" : "GPU"} backend for ${Platform.isAndroid ? "Android" : "iOS"}',
      );

      _inferenceModel = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: preferredBackend,
        maxTokens: 1024,
      );

      // Create a single chat session that will be reused
      debugPrint('💬 Creating persistent chat session...');
      _chatSession = await _inferenceModel!.createChat(
        temperature: 0.8,
        randomSeed: 42,
        topK: 40,
      );

      // Initialize with system prompt to make the AI smarter
      final promptToUse = systemPrompt ?? _defaultSystemPrompt;
      await _initializeSystemPrompt(promptToUse);

      debugPrint('✅ Gemma model loaded successfully');
      _isInitialized = true;
      _isLoading = false;
      _statusController.add(ModelStatus.ready);

      return true;
    } catch (e) {
      _isLoading = false;
      _isInitialized = false;
      _statusController.add(ModelStatus.error);
      debugPrint('❌ Failed to initialize Gemma model: $e');
      return false;
    }
  }

  /// Initialize the chat session with a system prompt
  Future<void> _initializeSystemPrompt(String systemPrompt) async {
    try {
      debugPrint(
        '📝 ==================== SYSTEM PROMPT INIT ====================',
      );
      debugPrint('📝 Setting up AI assistant with system prompt...');
      debugPrint('📏 System prompt length: ${systemPrompt.length} characters');
      debugPrint(
        '📏 System prompt lines: ${systemPrompt.split('\n').length} lines',
      );
      debugPrint(
        '📝 System prompt preview: "${systemPrompt.substring(0, systemPrompt.length.clamp(0, 100))}${systemPrompt.length > 100 ? "..." : ""}"',
      );

      final stopwatch = Stopwatch()..start();

      // Add system prompt as an assistant message to establish context
      debugPrint('➕ Adding system prompt as assistant message...');
      await _chatSession!.addQueryChunk(
        Message(text: systemPrompt, isUser: false),
      );
      debugPrint('✅ System prompt message added successfully');

      // Generate a brief acknowledgment to "consume" the system prompt
      debugPrint('🤖 Generating system prompt acknowledgment...');
      final acknowledgmentStartTime = stopwatch.elapsedMilliseconds;

      final acknowledgment = await _chatSession!.generateChatResponse();

      final acknowledgmentEndTime = stopwatch.elapsedMilliseconds;
      final acknowledgmentDuration =
          acknowledgmentEndTime - acknowledgmentStartTime;

      debugPrint('📤 System prompt acknowledgment: "$acknowledgment"');
      debugPrint(
        '📏 Acknowledgment length: ${acknowledgment.length} characters',
      );
      debugPrint(
        '⏱️ Acknowledgment generation time: ${acknowledgmentDuration}ms',
      );

      stopwatch.stop();
      debugPrint(
        '⏱️ Total system prompt init time: ${stopwatch.elapsedMilliseconds}ms',
      );
      debugPrint(
        '✅ ==================== SYSTEM PROMPT COMPLETE ====================',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '⚠️ ==================== SYSTEM PROMPT ERROR ====================',
      );
      debugPrint('⚠️ Failed to initialize system prompt: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      debugPrint('📏 System prompt length: ${systemPrompt.length} characters');
      debugPrint(
        '💬 Chat session state: ${_chatSession != null ? "active" : "null"}',
      );
      debugPrint(
        '⚠️ ==================== SYSTEM PROMPT ERROR END ====================',
      );
      // Continue without system prompt rather than failing completely
    }
  }

  /// Generate a response from the model
  Future<String> generateResponse(String prompt) async {
    if (!_isInitialized || _chatSession == null) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    // Debug: Log full request details
    debugPrint(
      '🔍 ==================== LLM REQUEST DEBUG ====================',
    );
    debugPrint('📥 Input prompt: "$prompt"');
    debugPrint('📏 Input length: ${prompt.length} characters');
    debugPrint('📏 Input words: ${prompt.split(' ').length} words');
    debugPrint('🧠 Model initialized: $_isInitialized');
    debugPrint('💬 Chat session active: ${_chatSession != null}');
    debugPrint('🔧 Platform: ${Platform.isAndroid ? "Android" : "iOS"}');
    debugPrint('⏱️ Request timestamp: ${DateTime.now().toIso8601String()}');

    final stopwatch = Stopwatch()..start();

    try {
      _statusController.add(ModelStatus.generating);
      debugPrint('🔄 Status changed to: generating');

      // Add the user's query using the existing chat session
      debugPrint('✏️ Adding query chunk to chat session...');
      await _chatSession!.addQueryChunk(Message(text: prompt, isUser: true));
      debugPrint('✅ Query chunk added successfully');

      debugPrint('🤖 Generating response...');
      final generationStartTime = stopwatch.elapsedMilliseconds;

      // Generate the response using the existing chat session
      final response = await _chatSession!.generateChatResponse();

      final generationEndTime = stopwatch.elapsedMilliseconds;
      final generationDuration = generationEndTime - generationStartTime;

      // Debug: Log full response details
      debugPrint(
        '🎯 ==================== LLM RESPONSE DEBUG ====================',
      );
      debugPrint('📤 Full response: "$response"');
      debugPrint('📏 Response length: ${response.length} characters');
      debugPrint('📏 Response words: ${response.split(' ').length} words');
      debugPrint('📏 Response lines: ${response.split('\n').length} lines');
      debugPrint('⏱️ Generation time: ${generationDuration}ms');
      debugPrint(
        '⚡ Speed: ${response.length / (generationDuration / 1000)} chars/sec',
      );
      debugPrint(
        '🔤 First 200 chars: "${response.substring(0, response.length.clamp(0, 200))}${response.length > 200 ? "..." : ""}"',
      );
      debugPrint(
        '🔤 Last 200 chars: "${response.length > 200 ? "..." + response.substring(response.length - 200) : response}"',
      );

      // Check for common response patterns
      if (response.isEmpty) {
        debugPrint('⚠️ WARNING: Empty response generated');
      }
      if (response.trim().isEmpty) {
        debugPrint('⚠️ WARNING: Response is only whitespace');
      }
      if (response.contains('I don\'t know') ||
          response.contains('I cannot') ||
          response.contains('I\'m not sure')) {
        debugPrint('ℹ️ INFO: Response contains uncertainty markers');
      }
      if (response.length > 2000) {
        debugPrint('ℹ️ INFO: Long response generated (>2000 chars)');
      }

      _statusController.add(ModelStatus.ready);
      debugPrint('🔄 Status changed to: ready');

      final trimmedResponse = response.trim();
      debugPrint(
        '📋 Final trimmed response length: ${trimmedResponse.length} characters',
      );

      stopwatch.stop();
      debugPrint(
        '⏱️ Total processing time: ${stopwatch.elapsedMilliseconds}ms',
      );
      debugPrint(
        '✅ ==================== LLM RESPONSE COMPLETE ====================',
      );

      return trimmedResponse;
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ ==================== LLM ERROR DEBUG ====================');
      debugPrint('💥 Generation error: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      debugPrint('⏱️ Time until error: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint(
        '🔧 Model state - initialized: $_isInitialized, loading: $_isLoading',
      );
      debugPrint(
        '💬 Chat session state: ${_chatSession != null ? "active" : "null"}',
      );
      debugPrint('📱 Platform: ${Platform.isAndroid ? "Android" : "iOS"}');
      debugPrint(
        '🧠 Available memory: ${Platform.isAndroid ? "Android memory info not available" : "iOS memory info not available"}',
      );
      debugPrint('❌ ==================== LLM ERROR END ====================');

      _statusController.add(ModelStatus.error);
      throw Exception('Failed to generate response: $e');
    }
  }

  /// Create a new chat session with system prompt
  Future<void> createNewChatSession({String? systemPrompt}) async {
    if (!_isInitialized || _inferenceModel == null) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    try {
      debugPrint(
        '🔄 ==================== NEW CHAT SESSION ====================',
      );
      debugPrint('🔄 Creating new chat session...');
      debugPrint('🧠 Model initialized: $_isInitialized');
      debugPrint(
        '🤖 Inference model: ${_inferenceModel != null ? "available" : "null"}',
      );
      debugPrint(
        '💬 Previous session: ${_chatSession != null ? "exists" : "null"}',
      );

      final stopwatch = Stopwatch()..start();

      _chatSession = await _inferenceModel!.createChat(
        temperature: 0.8,
        randomSeed: 42,
        topK: 40,
      );

      debugPrint('✅ New chat session created successfully');
      debugPrint('⚙️ Session config: temp=0.8, seed=42, topK=40');

      // Re-initialize with system prompt
      final promptToUse = systemPrompt ?? _defaultSystemPrompt;
      debugPrint(
        '📝 Using ${systemPrompt != null ? "custom" : "default"} system prompt',
      );

      await _initializeSystemPrompt(promptToUse);

      stopwatch.stop();
      debugPrint(
        '⏱️ Total chat session creation time: ${stopwatch.elapsedMilliseconds}ms',
      );
      debugPrint(
        '✅ ==================== NEW CHAT SESSION COMPLETE ====================',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ ==================== CHAT SESSION ERROR ====================',
      );
      debugPrint('❌ Failed to create new chat session: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      debugPrint(
        '🧠 Model state: initialized=$_isInitialized, loading=$_isLoading',
      );
      debugPrint(
        '🤖 Inference model: ${_inferenceModel != null ? "available" : "null"}',
      );
      debugPrint(
        '❌ ==================== CHAT SESSION ERROR END ====================',
      );
      throw Exception('Failed to create new chat session: $e');
    }
  }

  /// Check if the model is ready to generate responses
  bool get isReady => _isInitialized && _chatSession != null;

  /// Get the current model status
  ModelStatus get currentStatus {
    if (!_isInitialized) return ModelStatus.idle;
    if (_isLoading) return ModelStatus.loading;
    if (_chatSession == null) return ModelStatus.error;
    return ModelStatus.ready;
  }

  /// Clean up resources
  Future<void> dispose() async {
    _statusController.close();
    _chatSession = null;
    _inferenceModel = null;
    _isInitialized = false;
  }
}

/// Enum representing the current status of the model
enum ModelStatus {
  idle,
  downloading,
  loading,
  ready,
  generating,
  error;

  bool get isOperational => this == ready || this == generating;

  String getMessageWithContext() {
    switch (this) {
      case ModelStatus.idle:
        return 'Model not loaded';
      case ModelStatus.downloading:
        return 'Installing model from assets...';
      case ModelStatus.loading:
        return 'Loading model...';
      case ModelStatus.ready:
      case ModelStatus.generating:
        return 'Model ready';
      case ModelStatus.error:
        return 'Model error';
    }
  }
}

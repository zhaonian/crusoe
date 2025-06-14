import 'dart:async';
import 'package:flutter/material.dart';
import '../services/gemma_service.dart';
import '../widgets/chat_input_area.dart';
import 'model_info_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GemmaService _gemmaService = GemmaService.instance;

  bool _isModelLoaded = false;
  bool _isGenerating = false;
  ModelStatus _currentStatus = ModelStatus.idle;

  // For cancelling ongoing generation
  Completer<void>? _generationCancellation;

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _addWelcomeMessage();
    _listenToModelStatus();

    // Listen to text changes to update send button state
    _textController.addListener(() {
      setState(() {
        // This will trigger a rebuild to update the send button state
      });
    });
  }

  void _addWelcomeMessage() {
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  "👋 Hello! I'm your offline AI assistant powered by Gemma. How can I help you today?",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    });
  }

  void _listenToModelStatus() {
    _gemmaService.statusStream.listen((status) {
      setState(() {
        _currentStatus = status;
        _isModelLoaded = status.isOperational;
        _isGenerating = status == ModelStatus.generating;
      });

      // Update welcome message when status changes to ready
      if (status == ModelStatus.ready && _messages.length == 1) {
        setState(() {
          _messages.clear();
        });
        _addWelcomeMessage();
      }
    });
  }

  Future<void> _initializeModel() async {
    try {
      await _gemmaService.initialize();
    } catch (e) {
      _showError("Failed to load AI model: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty || _isGenerating || !_isModelLoaded) return;

    _textController.clear();

    // Add user message
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isGenerating = true;
    });

    // Add loading message
    final loadingMessage = ChatMessage(
      text: "...",
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _messages.add(loadingMessage);
    });

    _scrollToBottom();
    _generateResponse(text);
  }

  void _stopGeneration() {
    debugPrint('🛑 Stop generation requested');

    if (_generationCancellation != null &&
        !_generationCancellation!.isCompleted) {
      _generationCancellation!.complete();
      debugPrint('🛑 Generation cancellation signal sent');
    }

    setState(() {
      _isGenerating = false;
      // Remove loading message if it exists
      if (_messages.isNotEmpty && _messages.last.isLoading) {
        _messages.removeLast();
        // Add cancellation message
        _messages.add(
          ChatMessage(
            text: "⚠️ Response generation was stopped.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    });

    debugPrint('🛑 Generation stopped and UI updated');
  }

  Future<void> _generateResponse(String prompt) async {
    debugPrint('🎯 _generateResponse called with prompt: "$prompt"');

    // Create cancellation completer for this generation
    _generationCancellation = Completer<void>();

    try {
      debugPrint('🔄 Calling gemmaService.generateResponse...');

      // Race between the generation and cancellation
      final result = await Future.any([
        _gemmaService
            .generateResponse(prompt)
            .then((response) => {'type': 'response', 'data': response}),
        _generationCancellation!.future.then((_) => {'type': 'cancelled'}),
      ]);

      // Check if generation was cancelled
      if (result['type'] == 'cancelled') {
        debugPrint('🛑 Generation was cancelled');
        return; // Exit early, UI already updated by _stopGeneration
      }

      final response = result['data'] as String;
      debugPrint(
        '✅ Received response from service: "${response.substring(0, response.length.clamp(0, 100))}${response.length > 100 ? "..." : ""}"',
      );
      debugPrint('📏 Response length in UI: ${response.length} characters');

      // Check once more if cancelled (in case cancellation happened during processing)
      if (_generationCancellation!.isCompleted) {
        debugPrint('🛑 Generation was cancelled during processing');
        return;
      }

      setState(() {
        debugPrint('🗑️ Removing loading message...');
        // Remove loading message
        if (_messages.isNotEmpty && _messages.last.isLoading) {
          _messages.removeLast();
        }
        debugPrint('➕ Adding response message to UI...');
        // Add actual response
        _messages.add(
          ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        );
        debugPrint('💬 Total messages now: ${_messages.length}');
        // Ensure generating state is reset
        _isGenerating = false;
      });

      _scrollToBottom();
      debugPrint('✅ UI update complete');
    } catch (e) {
      debugPrint('❌ Error in _generateResponse: $e');

      // Only update UI if not cancelled
      if (_generationCancellation == null ||
          !_generationCancellation!.isCompleted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last.isLoading) {
            _messages.removeLast(); // Remove loading message
          }
          _messages.add(
            ChatMessage(
              text: "Sorry, I encountered an error. Please try again.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          // Ensure generating state is reset even on error
          _isGenerating = false;
        });
        _showError("Generation failed: $e");
      }
    } finally {
      // Clean up the cancellation completer
      _generationCancellation = null;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleRefresh() async {
    setState(() {
      _messages.clear();
    });

    // Create a new chat session
    await _gemmaService.createNewChatSession();

    // Add welcome message after new session is created
    _addWelcomeMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.smart_toy),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Offline AI Chat", style: TextStyle(fontSize: 18)),
                Text(
                  _currentStatus.getMessageWithContext(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: "Clear chat",
          ),
          IconButton(
            icon: Icon(Icons.storage),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ModelInfoScreen()),
              );
            },
            tooltip: "Model info",
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("About"),
                  content: Text(
                    "This chat runs completely offline using Google's Gemma model. "
                    "Your conversations stay private on your device.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("OK"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Start a conversation!",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessage(_messages[index], index),
                  ),
          ),
          ChatInputArea(
            textController: _textController,
            isModelLoaded: _isModelLoaded,
            isGenerating: _isGenerating,
            onSendPressed: () => _handleSubmitted(_textController.text),
            onStopPressed: _stopGeneration,
            onSubmitted: _handleSubmitted,
            onTextChanged: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cancel any ongoing generation
    if (_generationCancellation != null &&
        !_generationCancellation!.isCompleted) {
      _generationCancellation!.complete();
    }

    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessage(ChatMessage message, int index) {
    final isUser = message.isUser;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isUser
                      ? Radius.circular(4)
                      : Radius.circular(18),
                  bottomLeft: !isUser
                      ? Radius.circular(4)
                      : Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: message.isLoading
                  ? _buildLoadingIndicator()
                  : Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : null,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600], size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
        SizedBox(width: 12),
        Text("Thinking...", style: TextStyle(fontStyle: FontStyle.italic)),
      ],
    );
  }
}

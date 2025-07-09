import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/gemma_service.dart';
import '../widgets/chat_input_area.dart';
import '../widgets/glassmorphism_app_bar.dart';
import 'model_info_screen.dart';
import '../widgets/markdown_message.dart';

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
                  "👋 Hello! I'm your enhanced offline AI assistant powered by Gemma. I'm now equipped with improved reasoning and context awareness. How can I help you today?",
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

  Future<void> _launchFeedbackForm() async {
    final Uri url = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLScZE3S2vYkNfrCpvxzfAqi1mU4IP50yulpkCDzuE-mki9R5ng/viewform');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not launch feedback form');
      }
    } catch (e) {
      _showError('Error opening feedback form: $e');
    }
  }

  void _showLoadingDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final platform = Platform.isAndroid ? "CPU" : "GPU";
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lottie Animation
                Container(
                  width: 460,
                  height: 120,
                  child: Lottie.asset(
                    'assets/animations/loading_animation.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  strokeWidth: 4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Loading...",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                // Title
                Text(
                  "Loading LLM Model...",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                // Friendly message
                Text(
                  "Your $platform is working hard to load the LLM model!",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                // Close button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "Got it!",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF1a1a2e),
                  Color(0xFF0f0f23),
                ]
              : [
                  Colors.blue[100]!,
                  Colors.blue[50]!,
                  Colors.purple[50]!,
                  Colors.pink[50]!,
                ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassmorphismAppBar(
          centerTitle: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/icons/app_logo.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Offline AI",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _currentStatus.getMessageWithContext(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _handleRefresh,
              tooltip: "Clear chat",
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onSelected: (String value) {
                switch (value) {
                  case 'model_info':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ModelInfoScreen()),
                    );
                    break;
                  case 'feedback':
                    _launchFeedbackForm();
                    break;
                  case 'about':
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("About"),
                        content: Text(
                          "🌐 No WiFi Required!\n\n"
                          "This AI assistant runs completely offline on your device. "
                          "No internet connection needed - your conversations stay "
                          "private and secure on your device.\n\n"
                          "✓ Works without internet\n"
                          "✓ Complete privacy\n"
                          "✓ No data sent to servers",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("OK"),
                          ),
                        ],
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'model_info',
                  child: Row(
                    children: [
                      Icon(Icons.storage, size: 20),
                      SizedBox(width: 12),
                      Text('Model Info'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'feedback',
                  child: Row(
                    children: [
                      Icon(Icons.feedback, size: 20),
                      SizedBox(width: 12),
                      Text('Feedback'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'about',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20),
                      SizedBox(width: 12),
                      Text('About'),
                    ],
                  ),
                ),
              ],
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
              onLoadingTap: _showLoadingDialog,
            ),
          ],
        ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (!isUser) {
      // Check if this is a loading message
      if (message.isLoading) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
          child: Row(
            children: [
                              Container(
                  width: 80,
                  height: 40,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      isDarkMode ? Colors.white : Colors.black87,
                      BlendMode.srcIn,
                    ),
                    child: Lottie.asset(
                      'assets/animations/typing_animation.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      backgroundLoading: false,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          "...",
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      }
      
      // LLM message: full width, no container
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: MarkdownMessage(content: message.text),
      );
    }

    // User message: minimal with subtle distinction
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.2) 
                      : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
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

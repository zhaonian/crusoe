import 'package:flutter/material.dart';
import '../services/gemma_service.dart';
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
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GemmaService _gemmaService = GemmaService.instance;

  bool _isModelLoaded = false;
  bool _isGenerating = false;
  ModelStatus _currentStatus = ModelStatus.idle;

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

  Future<void> _generateResponse(String prompt) async {
    try {
      final response = await _gemmaService.generateResponse(prompt);

      setState(() {
        // Remove loading message
        _messages.removeLast();
        // Add actual response
        _messages.add(
          ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        );
        // Ensure generating state is reset
        _isGenerating = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.removeLast(); // Remove loading message
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

  Widget _buildMessage(ChatMessage message, int index) {
    final isUser = message.isUser;
    final isLast = index == _messages.length - 1;

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

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: _isModelLoaded
                        ? "Type your message..."
                        : "Loading AI model...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  enabled: _isModelLoaded && !_isGenerating,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: _handleSubmitted,
                ),
              ),
            ),
            SizedBox(width: 12),
            FloatingActionButton(
              onPressed:
                  (_isModelLoaded &&
                      !_isGenerating &&
                      _textController.text.trim().isNotEmpty)
                  ? () => _handleSubmitted(_textController.text)
                  : null,
              backgroundColor:
                  (_isModelLoaded &&
                      !_isGenerating &&
                      _textController.text.trim().isNotEmpty)
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
              mini: true,
              child: Icon(
                _isGenerating ? Icons.stop : Icons.send,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
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
                  _currentStatus.message,
                  style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              _addWelcomeMessage();
            },
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
          if (!_isModelLoaded)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(_currentStatus.message),
                ],
              ),
            ),
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
          _buildInputArea(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

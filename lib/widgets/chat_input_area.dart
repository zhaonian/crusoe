import 'package:flutter/material.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController textController;
  final bool isModelLoaded;
  final bool isGenerating;
  final VoidCallback? onSendPressed;
  final VoidCallback? onStopPressed;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTextChanged;

  const ChatInputArea({
    super.key,
    required this.textController,
    required this.isModelLoaded,
    required this.isGenerating,
    this.onSendPressed,
    this.onStopPressed,
    this.onSubmitted,
    this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasText = textController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? Colors.grey.withOpacity(0.1)
                : Colors.grey.withOpacity(0.15),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            minHeight: 44,
            maxHeight: 120, // Limit max height for multiline
          ),
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isDarkMode
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button (optional - like ChatGPT)
              Container(
                width: 44,
                height: 44,
                child: IconButton(
                  onPressed: isModelLoaded && !isGenerating
                      ? () {
                          // Future: Add attachment functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Attachment feature coming soon!"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  icon: Icon(
                    Icons.add,
                    color: isModelLoaded && !isGenerating
                        ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                        : Colors.grey[400],
                    size: 20,
                  ),
                  splashRadius: 20,
                ),
              ),

              // Text input area
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 20,
                    maxHeight: 80, // Max height for text field
                  ),
                  child: TextField(
                    controller: textController,
                    enabled: isModelLoaded && !isGenerating,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(fontSize: 16, height: 1.4),
                    decoration: InputDecoration(
                      hintText: isModelLoaded
                          ? "Message..."
                          : "LLM Thinking...",
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    onChanged: (text) {
                      // Trigger rebuild for send button state
                      onTextChanged?.call();
                    },
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty &&
                          isModelLoaded &&
                          !isGenerating) {
                        onSubmitted?.call(text);
                      }
                    },
                  ),
                ),
              ),

              // Send/Stop button
              Container(
                width: 44,
                height: 44,
                child: isGenerating
                    ? IconButton(
                        onPressed: onStopPressed,
                        icon: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.stop_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        splashRadius: 20,
                      )
                    : IconButton(
                        onPressed: hasText && isModelLoaded
                            ? onSendPressed
                            : null,
                        icon: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: hasText && isModelLoaded
                                ? Theme.of(context).primaryColor
                                : (isDarkMode
                                      ? Colors.grey[700]
                                      : Colors.grey[400]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        splashRadius: 20,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

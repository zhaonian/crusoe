import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

class MarkdownMessage extends StatelessWidget {
  final String content;

  const MarkdownMessage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, 12), // Simple hack: move up to hide bottom padding
      child: MarkdownWidget(data: content, shrinkWrap: true),
    );
  }
}

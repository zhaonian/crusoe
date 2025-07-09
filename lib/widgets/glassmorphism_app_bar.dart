import 'package:flutter/material.dart';
import 'dart:ui';

class GlassmorphismAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const GlassmorphismAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.height = kToolbarHeight,
    this.backgroundColor,
    this.foregroundColor,
  }) : assert(title != null || titleText != null, 'Either title or titleText must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: height + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [
            Colors.blue[600]!.withValues(alpha: 0.4),
            Colors.purple[600]!.withValues(alpha: 0.3),
            Colors.pink[600]!.withValues(alpha: 0.2),
          ] : [
            Colors.blue[400]!.withValues(alpha: 0.3),
            Colors.purple[400]!.withValues(alpha: 0.2),
            Colors.pink[400]!.withValues(alpha: 0.1),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark ? [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.1),
                ] : [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (leading != null) leading!,
                    Expanded(
                      child: centerTitle
                          ? Center(
                              child: title ?? Text(
                                titleText!,
                                style: TextStyle(
                                  color: foregroundColor ?? 
                                      (isDark ? Colors.white : Colors.black87),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: isDark 
                                          ? Colors.black.withValues(alpha: 0.5)
                                          : Colors.black.withValues(alpha: 0.3),
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : title ?? Text(
                              titleText!,
                              style: TextStyle(
                                color: foregroundColor ?? 
                                    (isDark ? Colors.white : Colors.black87),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: isDark 
                                        ? Colors.black.withValues(alpha: 0.5)
                                        : Colors.black.withValues(alpha: 0.3),
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height + 44); // 44 is typical status bar height
} 
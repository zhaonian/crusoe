import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(OfflineAIApp());
}

class OfflineAIApp extends StatelessWidget {
  const OfflineAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Modern, clean theme optimized for chat interfaces
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[600],
        scaffoldBackgroundColor: Colors.grey[50],
        cardColor: Colors.white,

        // AppBar styling
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: false,
        ),

        // Floating Action Button
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),

        // Input decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),

        // Text theme
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),

        // Modern visual density
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // Dark theme for users who prefer it
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[400],
        scaffoldBackgroundColor: Color(0xFF121212),
        cardColor: Color(0xFF1E1E1E),

        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: false,
        ),

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue[400],
          foregroundColor: Colors.white,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),

        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
        ),

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // Automatically switch between light and dark themes
      themeMode: ThemeMode.system,

      // Set ChatScreen as the home screen
      home: ChatScreen(),
    );
  }
}

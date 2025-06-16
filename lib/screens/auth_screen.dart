import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isAuthenticated = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _currentDownload = '';
  bool _isInitialized = false;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await FlutterDownloader.initialize();
      await _checkAuthStatus();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    final token = await _storage.read(key: 'huggingface_token');
    setState(() {
      _isAuthenticated = token != null;
      _accessToken = token;
    });
  }

  Future<void> _login() async {
    final clientId = dotenv.env['HUGGINGFACE_CLIENT_ID'] ?? '';
    if (clientId.isEmpty) {
      throw Exception(
        'HUGGINGFACE_CLIENT_ID not found in environment variables',
      );
    }

    final FlutterAppAuth appAuth = FlutterAppAuth();
    try {
      final AuthorizationTokenResponse? result = await appAuth
          .authorizeAndExchangeCode(
            AuthorizationTokenRequest(
              clientId,
              'io.zluan.crusoe.oauth://oauthredirect',
              discoveryUrl:
                  'https://huggingface.co/.well-known/openid-configuration',
              scopes: ['openid', 'profile'],
            ),
          );

      if (result != null) {
        await _storage.write(
          key: 'huggingface_token',
          value: result.accessToken,
        );
        setState(() {
          _isAuthenticated = true;
          _accessToken = result.accessToken;
        });
      }
    } catch (e) {
      print('Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Authentication failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Hugging Face Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isAuthenticated)
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login with Hugging Face'),
              )
            else ...[
              const Text(
                'Logged in successfully!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_accessToken != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Access Token:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText(
                  _accessToken ?? '',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

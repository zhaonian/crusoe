import 'package:flutter/material.dart';
import '../services/gemma_service.dart';
import '../services/model_downloader.dart';

class ModelInfoScreen extends StatefulWidget {
  const ModelInfoScreen({super.key});

  @override
  State<ModelInfoScreen> createState() => _ModelInfoScreenState();
}

class _ModelInfoScreenState extends State<ModelInfoScreen> {
  final GemmaService _gemmaService = GemmaService.instance;
  String? _localModelPath;
  bool _isLoading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkLocalModel();
  }

  Future<void> _checkLocalModel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final modelPath = await ModelDownloader.getLocalModelPath();
      setState(() {
        _localModelPath = modelPath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadModel() async {
    setState(() {
      _isLoading = true;
      _downloadProgress = 0.0;
      _statusMessage = 'Preparing download...';
    });

    try {
      final modelPath = await ModelDownloader.downloadModel(
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
        onStatusUpdate: (status) {
          setState(() {
            _statusMessage = status;
          });
        },
      );

      setState(() {
        _localModelPath = modelPath;
        _isLoading = false;
        _statusMessage = 'Download complete!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Model downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Download failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download model: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteModel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Model'),
        content: Text(
          'Are you sure you want to delete the downloaded model? This will free up 529MB of storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ModelDownloader.deleteLocalModel();
      setState(() {
        _localModelPath = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Model deleted successfully'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Model Information')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemma 3 1B Model',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A compact, efficient language model optimized for mobile devices.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow('Model Size:', '529 MB'),
                    _buildInfoRow('Parameters:', '1 Billion'),
                    _buildInfoRow('Quantization:', 'INT4'),
                    _buildInfoRow('Speed:', 'Up to 2,585 tok/sec'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    if (_isLoading) ...[
                      LinearProgressIndicator(value: _downloadProgress),
                      SizedBox(height: 8),
                      Text(_statusMessage),
                      SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Icon(
                          _localModelPath != null
                              ? Icons.check_circle
                              : Icons.cloud_download,
                          color: _localModelPath != null
                              ? Colors.green
                              : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _localModelPath != null
                                ? 'Model downloaded and ready'
                                : 'Model not downloaded',
                            style: TextStyle(
                              color: _localModelPath != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_localModelPath != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Path: $_localModelPath',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                if (_localModelPath == null) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _downloadModel,
                      icon: Icon(Icons.download),
                      label: Text('Download Model'),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _deleteModel,
                      icon: Icon(Icons.delete),
                      label: Text('Delete Model'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

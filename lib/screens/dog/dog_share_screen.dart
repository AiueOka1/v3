import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pawtech/models/dog.dart';
import 'package:pawtech/providers/dog_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pawtech/widgets/smart_image.dart';

class DogShareScreen extends StatefulWidget {
  final Dog dog;

  const DogShareScreen({
    super.key,
    required this.dog,
  });

  @override
  State<DogShareScreen> createState() => _DogShareScreenState();
}

class _DogShareScreenState extends State<DogShareScreen> {
  late String _shareableUrl;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    _shareableUrl = dogProvider.generateDogShareableUrl(widget.dog.id);
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _shareableUrl));
    setState(() {
      _copied = true;
    });
    
    // Reset copied state after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Dog Information'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SmartCircleAvatar(
              radius: 50,
              imagePath: widget.dog.imageUrl,
            ),
            const SizedBox(height: 16),
            Text(
              widget.dog.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Text(
              widget.dog.breed,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Scan this QR code to access dog information',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: _shareableUrl,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Or use this link:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _shareableUrl,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _copied ? Icons.check : Icons.copy,
                              color: _copied ? Colors.green : null,
                            ),
                            onPressed: _copyToClipboard,
                            tooltip: 'Copy to clipboard',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'This link provides access to basic information about your dog, including:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildInfoItem(Icons.pets, 'Dog name and breed'),
            _buildInfoItem(Icons.person, 'Handler information'),
            _buildInfoItem(Icons.business, 'Department'),
            _buildInfoItem(Icons.nfc, 'NFC Tag ID'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // In a real app, this would use a sharing plugin
                _copyToClipboard();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard'),
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:pawtech/models/dog.dart';
import 'package:pawtech/widgets/custom_button.dart';

class DogNfcScreen extends StatefulWidget {
  final Dog dog;

  const DogNfcScreen({
    super.key,
    required this.dog,
  });

  @override
  State<DogNfcScreen> createState() => _DogNfcScreenState();
}

class _DogNfcScreenState extends State<DogNfcScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startNfcScan() {
    setState(() {
      _isScanning = true;
    });

    // Simulate NFC scanning
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.nfc,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text('NFC Tag Detected'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Tag ID', widget.dog.nfcTagId),
                const SizedBox(height: 8),
                _buildInfoRow('Dog ID', widget.dog.id),
                const SizedBox(height: 8),
                _buildInfoRow('Name', widget.dog.name),
                const SizedBox(height: 8),
                _buildInfoRow('Breed', widget.dog.breed),
                const SizedBox(height: 8),
                _buildInfoRow('Handler', widget.dog.handlerName),
                const SizedBox(height: 8),
                _buildInfoRow('Department', widget.dog.department),
                const SizedBox(height: 8),
                _buildInfoRow('Emergency', widget.dog.emergencyContact),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Identification'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isScanning
                            ? Theme.of(context).primaryColor.withOpacity(_animation.value)
                            : Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: _isScanning
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            )
                          : Icon(
                              Icons.nfc,
                              size: 80,
                              color: Theme.of(context).primaryColor,
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                _isScanning ? 'Scanning...' : 'NFC Scanner',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isScanning
                    ? 'Hold your phone near the NFC tag on the dog\'s harness'
                    : 'Tap the button below to scan the NFC tag on the dog\'s harness',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: _isScanning ? 'Cancel' : 'Start Scanning',
                icon: _isScanning ? Icons.close : Icons.nfc,
                isLoading: _isScanning,
                onPressed: _isScanning ? () {
                  setState(() {
                    _isScanning = false;
                  });
                } : _startNfcScan,
                width: double.infinity,
              ),
              const SizedBox(height: 24),
              if (!_isScanning)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'About NFC Identification',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'NFC tags embedded in the smart harness allow instant access to dog information without specialized scanners. Any smartphone can retrieve data instantly.',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


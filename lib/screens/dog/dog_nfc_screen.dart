import 'package:flutter/material.dart';
import 'package:pawtech/models/dog.dart';

class DogNfcScreen extends StatelessWidget {
  final Dog dog;

  const DogNfcScreen({
    super.key,
    required this.dog,
  });

  Widget _buildInfoCard(String label, String value, IconData icon, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
        title: const Text('NFC Information'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with NFC Icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.nfc,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'NFC Tag Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Smart harness embedded identification',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Dog Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),

            // Dog Information Cards
            _buildInfoCard('NFC Tag ID', dog.nfcTagId, Icons.qr_code_2, context),
            _buildInfoCard('Dog ID', dog.id, Icons.fingerprint, context),
            _buildInfoCard('Name', dog.name, Icons.pets, context),
            _buildInfoCard('Breed', dog.breed, Icons.category, context),
            _buildInfoCard('Handler', dog.handlerName, Icons.person, context),
            _buildInfoCard('Department', dog.department, Icons.business, context),
            _buildInfoCard('Emergency Contact', dog.emergencyContact, Icons.emergency, context),
            
            const SizedBox(height: 24),
            
            // Info Card about NFC
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About NFC Technology',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This information is stored on an NFC tag embedded in the dog\'s smart harness. Any NFC-enabled smartphone can instantly read this data by tapping the harness, providing quick access to essential information in emergency situations.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


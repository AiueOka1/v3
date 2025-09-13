import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'package:pawtech/models/dog.dart';
import 'package:pawtech/providers/dog_provider.dart';
import 'package:pawtech/providers/geofence_provider.dart';
import 'package:pawtech/providers/alert_provider.dart';
import 'package:pawtech/screens/dog/dog_nfc_screen.dart';
import 'package:pawtech/screens/dog/dog_share_screen.dart';
import 'package:pawtech/widgets/smart_image.dart';

class DogDetailsScreen extends StatefulWidget {
  final String dogId;

  const DogDetailsScreen({super.key, required this.dogId});

  @override
  State<DogDetailsScreen> createState() => _DogDetailsScreenState();
}

class _DogDetailsScreenState extends State<DogDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Fixed: Changed from 2 to 1
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dogProvider = Provider.of<DogProvider>(context);
    final geofenceProvider = Provider.of<GeofenceProvider>(context);
    final alertProvider = Provider.of<AlertProvider>(context);

    final dog = dogProvider.getDogById(widget.dogId);

    if (dog == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dog Details')),
        body: const Center(child: Text('Dog not found')),
      );
    }

    final geofences = geofenceProvider.getGeofencesForDog(dog.id);
    final dogAlerts = alertProvider.getAlertsForDog(dog.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(dog.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.nfc),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DogNfcScreen(dog: dog))
              );
            },
            tooltip: 'NFC Identification',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DogShareScreen(dog: dog)),
              );
            },
            tooltip: 'Share Dog Information',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Hero(
                  tag: 'dog_image_${dog.id}',
                  child: SmartCircleAvatar(
                    radius: 40,
                    imagePath: dog.imageUrl,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dog.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dog.breed,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: dog.isActive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              dog.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: dog.isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible( // Fixed: Added Flexible wrapper
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                dog.specialization,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis, // Fixed: Added overflow handling
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: dog.isActive,
                  onChanged: (value) {
                    dogProvider.updateDogStatus(dog.id, value);
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Info'), // Only one tab now
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Info Tab - This now includes both info and geofences
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(context, 'Handler Information', [
                        _buildInfoItem('Name', dog.handlerName),
                        _buildInfoItem('Department', dog.department),
                        _buildInfoItem('Emergency Contact', dog.emergencyContact),
                      ]),
                      const SizedBox(height: 16),
                      _buildInfoSection(context, 'Dog Information', [
                        _buildInfoItem('Breed', dog.breed),
                        _buildInfoItem('Specialization', dog.specialization),
                        _buildInfoItem('Training Level', dog.trainingLevel),
                        _buildInfoItem('NFC Tag ID', dog.nfcTagId),
                        _buildInfoItem('Medical Info', dog.medicalInfo),
                        if (dog.deviceId != null && dog.deviceId!.isNotEmpty)
                          _buildInfoItemWithAction(
                            'GPS Device',
                            dog.deviceId!,
                            Icons.delete,
                            Colors.red,
                            () => _showRemoveDeviceDialog(context, dog),
                          )
                        else
                          _buildInfoItemWithAction(
                            'GPS Device',
                            'Not assigned',
                            Icons.add,
                            Theme.of(context).primaryColor,
                            () => _showAssignDeviceDialog(context, dog),
                          ),
                      ]),
                      const SizedBox(height: 16),
                      _buildInfoSection(context, 'Status', [
                        _buildInfoItem(
                          'Active Status',
                          dog.isActive ? 'Active' : 'Inactive',
                        ),
                        _buildInfoItem(
                          'Last Updated',
                          _formatTimestamp(
                            dog.lastKnownLocation['timestamp'] as String,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        context,
                        'Recent Alerts',
                        dogAlerts.isEmpty
                            ? [_buildInfoItem('Status', 'No recent alerts')]
                            : dogAlerts
                                .take(3)
                                .map(
                                  (alert) => _buildInfoItem(
                                    _formatTimestamp(alert.timestamp),
                                    alert.message,
                                    valueColor: alert.isRead ? null : Colors.red,
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 16),
                      // Add geofences section here
                      _buildInfoSection(context, 'Geofences', [
                        if (geofences.isEmpty)
                          _buildInfoItem('Status', 'No geofences configured')
                        else
                          ...geofences.map((geofence) => _buildInfoItem(
                            geofence.name,
                            '${geofence.radius.toInt()}m radius',
                          )).toList(),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItemWithAction(
    String label, 
    String value, 
    IconData icon, 
    Color iconColor, 
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      icon,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignDeviceDialog(BuildContext context, Dog dog) async {
    final TextEditingController deviceIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Assign GPS Device to ${dog.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: deviceIdController,
                decoration: const InputDecoration(
                  labelText: 'Enter Device ID',
                  hintText: 'e.g., DEVICE###',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final deviceId = deviceIdController.text.trim();

                if (deviceId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Device ID cannot be empty')),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                
                final dogProvider = Provider.of<DogProvider>(context, listen: false);
                final errorMessage = await dogProvider.assignDeviceToDog(dog.id, deviceId);

                if (mounted) {
                  if (errorMessage != null) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Error'),
                        content: Text(errorMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Device assigned successfully!')),
                    );
                  }
                }
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRemoveDeviceDialog(BuildContext context, Dog dog) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Remove GPS Device from ${dog.name}'),
          content: Text(
            'Are you sure you want to remove the GPS device (${dog.deviceId}) from ${dog.name}? '
            'This will stop location tracking for this dog.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                
                final dogProvider = Provider.of<DogProvider>(context, listen: false);
                final errorMessage = await dogProvider.removeDeviceFromDog(dog.id);

                if (mounted) {
                  if (errorMessage != null) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Error'),
                        content: Text(errorMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GPS device removed successfully!')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

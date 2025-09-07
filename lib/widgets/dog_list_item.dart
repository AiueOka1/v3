import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtech/models/dog.dart';
import 'package:pawtech/providers/dog_provider.dart';
import 'package:pawtech/widgets/smart_image.dart';
import 'package:pawtech/screens/dog/medical_info_screen.dart';

class DogListItem extends StatelessWidget {
  final Dog dog;
  final VoidCallback onTap;

  const DogListItem({
    super.key,
    required this.dog,
    required this.onTap,
  });

  Future<void> _assignDevice(
    BuildContext context,
    String dogId,
    String deviceId,
  ) async {
    final dogProvider = Provider.of<DogProvider>(context, listen: false);

    final errorMessage = await dogProvider.assignDeviceToDog(dogId, deviceId);

    if (errorMessage != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
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

  Future<void> _showAssignDeviceDialog(
    BuildContext context,
    String dogId,
  ) async {
    final TextEditingController deviceIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Assign GPS Device'),
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
              onPressed: () {
                final deviceId = deviceIdController.text.trim();

                if (deviceId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Device ID cannot be empty')),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                _assignDevice(context, dogId, deviceId);
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMedicalInfo(BuildContext context) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MedicalInfoScreen(dog: dog),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'dog_image_${dog.id}',
                child: SmartCircleAvatar(
                  radius: 30,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // GPS status and Medical info buttons
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        // GPS Status/Button
                        if (dog.deviceId != null && dog.deviceId!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.gps_fixed, size: 12, color: Colors.green[700]),
                                const SizedBox(width: 3),
                                Text(
                                  'GPS',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          InkWell(
                            onTap: () => _showAssignDeviceDialog(context, dog.id),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 12,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Add GPS',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Medical Info Button
                        InkWell(
                          onTap: () => _showMedicalInfo(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.medical_services,
                                  size: 12,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Medical',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}


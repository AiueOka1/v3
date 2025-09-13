import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtech/providers/dog_provider.dart';

class DeviceAssignmentDebugScreen extends StatefulWidget {
  const DeviceAssignmentDebugScreen({super.key});

  @override
  State<DeviceAssignmentDebugScreen> createState() => _DeviceAssignmentDebugScreenState();
}

class _DeviceAssignmentDebugScreenState extends State<DeviceAssignmentDebugScreen> {
  Map<String, String>? _deviceAssignments;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceAssignments();
  }

  Future<void> _loadDeviceAssignments() async {
    setState(() => _isLoading = true);
    
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    final assignments = await dogProvider.getDeviceAssignments();
    
    setState(() {
      _deviceAssignments = assignments;
      _isLoading = false;
    });
  }

  Future<void> _refreshAssignments() async {
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    
    setState(() => _isLoading = true);
    
    // Refresh device assignments
    await dogProvider.refreshDeviceAssignments();
    
    // Reload the debug info
    await _loadDeviceAssignments();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device assignments refreshed!')),
      );
    }
  }

  Future<void> _removeDeviceFromDog(String dogId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove GPS Device'),
        content: const Text('Are you sure you want to remove the GPS device from this dog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    
    setState(() => _isLoading = true);
    
    final errorMessage = await dogProvider.removeDeviceFromDog(dogId);
    
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
      
      // Refresh the data
      await _loadDeviceAssignments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Assignment Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAssignments,
            tooltip: 'Refresh Assignments',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device Assignments Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.devices, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Device → Dog Assignments',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_deviceAssignments == null || _deviceAssignments!.isEmpty)
                            const Text(
                              'No device assignments found in realtime database.',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...(_deviceAssignments!.entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward, color: Colors.grey),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList()),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Dogs Section
                  Consumer<DogProvider>(
                    builder: (context, dogProvider, child) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.pets, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Dogs with Device Status',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (dogProvider.dogs.isEmpty)
                                const Text(
                                  'No dogs found.',
                                  style: TextStyle(color: Colors.grey),
                                )
                              else
                                ...(dogProvider.dogs.map((dog) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                dog.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: (dog.deviceId != null && dog.deviceId!.isNotEmpty)
                                                    ? Colors.green.withOpacity(0.1)
                                                    : Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                (dog.deviceId != null && dog.deviceId!.isNotEmpty)
                                                    ? 'HAS GPS'
                                                    : 'NO GPS',
                                                style: TextStyle(
                                                  color: (dog.deviceId != null && dog.deviceId!.isNotEmpty)
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text('ID: ', style: TextStyle(color: Colors.grey[600])),
                                            Text(dog.id, style: const TextStyle(fontFamily: 'monospace')),
                                          ],
                                        ),
                                        if (dog.deviceId != null && dog.deviceId!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text('Device: ', style: TextStyle(color: Colors.grey[600])),
                                              Expanded(
                                                child: Text(
                                                  dog.deviceId!,
                                                  style: const TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () => _removeDeviceFromDog(dog.id),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Icon(
                                                    Icons.delete,
                                                    size: 16,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                )).toList()),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.sync),
                      label: const Text('Refresh All Data'),
                      onPressed: () async {
                        final dogProvider = Provider.of<DogProvider>(context, listen: false);
                        await dogProvider.fetchDogs();
                        await _loadDeviceAssignments();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All data refreshed!')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

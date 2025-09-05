import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtech/providers/dog_provider.dart';
import 'package:pawtech/widgets/map_placeholder.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  String? _selectedDogId;
  String _geofenceLocation = 'current'; // Default to current location
  double _geofenceRadius = 100.0; // Default radius

  void _showRadiusDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double tempRadius = _geofenceRadius;
        final TextEditingController radiusController = TextEditingController(
          text: tempRadius.toInt().toString(),
        );
        bool useSlider = true; // Toggle between slider and manual input

        return AlertDialog(
          title: const Text('Set Geofence Radius'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Radius: ${tempRadius.toInt()} meters',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Toggle between slider and manual input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ChoiceChip(
                        label: const Text('Slider'),
                        selected: useSlider,
                        onSelected: (selected) {
                          setDialogState(() {
                            useSlider = true;
                            // Update controller when switching to slider
                            radiusController.text = tempRadius.toInt().toString();
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Manual'),
                        selected: !useSlider,
                        onSelected: (selected) {
                          setDialogState(() {
                            useSlider = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Slider or Text Field based on selection
                  if (useSlider) ...[
                    Slider(
                      value: tempRadius,
                      min: 50,
                      max: 1000,
                      divisions: 19,
                      label: '${tempRadius.toInt()}',
                      onChanged: (value) {
                        setDialogState(() {
                          tempRadius = value;
                          radiusController.text = value.toInt().toString();
                        });
                      },
                    ),
                  ] else ...[
                    TextField(
                      controller: radiusController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Radius (meters)',
                        hintText: 'Enter radius between 50-2000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixText: 'm',
                      ),
                      onChanged: (value) {
                        final parsed = double.tryParse(value);
                        if (parsed != null && parsed >= 50 && parsed <= 2000) {
                          setDialogState(() {
                            tempRadius = parsed;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Range: 50 - 2000 meters',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Validate manual input if using text field
                if (!useSlider) {
                  final inputValue = double.tryParse(radiusController.text);
                  if (inputValue == null || inputValue < 50 || inputValue > 2000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid radius between 50-2000 meters'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  tempRadius = inputValue;
                }
                
                setState(() {
                  _geofenceRadius = tempRadius;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dogProvider = Provider.of<DogProvider>(context);

    final dogs = dogProvider.dogs;
    final activeDogs = dogs.where((dog) => dog.isActive).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tracking',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Dog',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      value: _selectedDogId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Dogs'),
                        ),
                        ...activeDogs.map(
                          (dog) => DropdownMenuItem<String>(
                            value: dog.id,
                            child: Text(dog.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDogId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _showRadiusDialog,
                    child: const Text('Set Radius'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Geofence Location:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _geofenceLocation,
                    items: const [
                      DropdownMenuItem(
                        value: 'current',
                        child: Text('Current Location'),
                      ),
                      DropdownMenuItem(
                        value: 'city_hall',
                        child: Text('City Hall Location'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _geofenceLocation = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              RealMapView(
                selectedDogId: _selectedDogId,
                dogs:
                    _selectedDogId == null
                        ? activeDogs
                        : activeDogs
                            .where((dog) => dog.id == _selectedDogId)
                            .toList(),
                geofences: [], // 🛠 FIX: Pass empty list for now
                geofenceLocation: _geofenceLocation,
                geofenceRadius: _geofenceRadius,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

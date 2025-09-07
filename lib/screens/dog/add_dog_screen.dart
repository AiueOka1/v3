import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtech/models/dog.dart';
import 'package:pawtech/providers/dog_provider.dart';
import 'package:pawtech/providers/auth_provider.dart';
import 'package:pawtech/widgets/custom_button.dart';
import 'package:pawtech/widgets/custom_text_field.dart';
import 'package:pawtech/services/image_storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddDogScreen extends StatefulWidget {
  const AddDogScreen({super.key});

  @override
  State<AddDogScreen> createState() => _AddDogScreenState();
}

class _AddDogScreenState extends State<AddDogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _handlerNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _trainingLevelController = TextEditingController();
  final _departmentController = TextEditingController();
  final _medicalInfoController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _nfcTagIdController = TextEditingController();
  
  String _selectedTrainingLevel = 'Beginner';
  String _selectedSpecialization = 'Search and Rescue';
  File? _imageFile;
  bool _isLoading = false;
  
  final List<String> _trainingLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert'
  ];
  
  final List<String> _specializations = [
    'Search and Rescue',
    'Narcotics Detection',
    'Bomb Detection',
    'Patrol',
    'Cadaver Detection',
    'Tracking'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _handlerNameController.dispose();
    _specializationController.dispose();
    _trainingLevelController.dispose();
    _departmentController.dispose();
    _medicalInfoController.dispose();
    _emergencyContactController.dispose();
    _nfcTagIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _scanNfcTag() async {
    // In a real app, this would use NFC plugin to scan a tag
    setState(() {
      _isLoading = true;
    });
    
    // Simulate NFC scanning
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
      _nfcTagIdController.text = 'NFC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('NFC tag scanned successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveDog() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final dogProvider = Provider.of<DogProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Generate dog ID first
        final dogId = 'dog_${DateTime.now().millisecondsSinceEpoch}';
        
        // Save image to permanent storage if one was selected
        String imageUrl;
        if (_imageFile != null) {
          // Save image to permanent storage and get the permanent path
          final permanentImagePath = await ImageStorageService.saveImageToPermanentStorage(_imageFile!, dogId);
          imageUrl = permanentImagePath;
        } else {
          // Use placeholder image if no image was selected
          imageUrl = 'https://images.unsplash.com/photo-1589941013453-ec89f33b5e95?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60';
        }
        
        final newDog = Dog(
          id: dogId,
          name: _nameController.text.trim(),
          breed: _breedController.text.trim(),
          imageUrl: imageUrl,
          handlerId: authProvider.currentUser!.id,
          handlerName: _handlerNameController.text.trim(),
          specialization: _selectedSpecialization,
          trainingLevel: _selectedTrainingLevel,
          lastKnownLocation: {
            'latitude': 14.6499,
            'longitude': 120.9809,
            'timestamp': DateTime.now().toIso8601String(),
          },
          isActive: true,
          nfcTagId: _nfcTagIdController.text.trim(),
          department: _departmentController.text.trim(),
          medicalInfo: _medicalInfoController.text.trim(),
          emergencyContact: _emergencyContactController.text.trim(),
        );
        
        await dogProvider.addDog(newDog);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dog added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding dog: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Dog'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dog Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Dog Image
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imageFile == null
                              ? Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Theme.of(context).primaryColor,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _pickImage,
                        child: const Text('Upload Photo'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Basic Information
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Dog Name',
                      hintText: 'Enter dog name',
                      prefixIcon: Icons.pets,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter dog name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _breedController,
                      labelText: 'Breed',
                      hintText: 'Enter dog breed',
                      prefixIcon: Icons.category,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter dog breed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Handler Information
                    Text(
                      'Handler Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _handlerNameController,
                      labelText: 'Handler Name',
                      hintText: 'Enter handler name',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter handler name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _departmentController,
                      labelText: 'Department',
                      hintText: 'Enter department',
                      prefixIcon: Icons.business,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter department';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emergencyContactController,
                      labelText: 'Emergency Contact',
                      hintText: 'Enter emergency contact',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter emergency contact';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Training Information
                    Text(
                      'Training Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Specialization',
                        prefixIcon: const Icon(Icons.work),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _selectedSpecialization,
                      items: _specializations.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedSpecialization = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Training Level',
                        prefixIcon: const Icon(Icons.school),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _selectedTrainingLevel,
                      items: _trainingLevels.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTrainingLevel = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Medical Information
                    Text(
                      'Medical Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _medicalInfoController,
                      labelText: 'Medical Information',
                      hintText: 'Enter medical information',
                      prefixIcon: Icons.medical_services,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // NFC Tag Information
                    Text(
                      'NFC Tag Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _nfcTagIdController,
                            labelText: 'NFC Tag ID',
                            hintText: 'Scan or enter NFC tag ID',
                            prefixIcon: Icons.nfc,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter NFC tag ID';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _scanNfcTag,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Icon(Icons.nfc),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Save',
                      isLoading: _isLoading,
                      onPressed: _saveDog,
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
}


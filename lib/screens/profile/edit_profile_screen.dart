// Profile editing screen for user profile management
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pawtech/models/user.dart';
import 'package:pawtech/providers/auth_provider.dart';
import 'package:pawtech/services/cloud_image_service.dart';
import 'package:pawtech/widgets/custom_button.dart';
import 'package:pawtech/widgets/custom_text_field.dart';
import 'package:pawtech/widgets/smart_image.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _badgeController = TextEditingController();
  
  File? _imageFile;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _departmentController.text = user.department;
      _phoneController.text = user.phoneNumber;
      _badgeController.text = user.badgeNumber;
    }

    // Add listeners to detect changes
    _nameController.addListener(_onFieldChanged);
    _departmentController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _badgeController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser!;
      
      // Handle profile image
      String profileImageUrl = currentUser.profileImageUrl;
      if (_imageFile != null) {
        print('Uploading image file: ${_imageFile!.path}'); // Debug log
        // Upload image to cloud storage
        profileImageUrl = await CloudImageService.uploadProfileImageToFirestore(
          _imageFile!, 
          currentUser.id
        );
        
        print('Uploaded image URL: $profileImageUrl'); // Debug log
        print('Image URL length: ${profileImageUrl.length}'); // Debug log
      }

      // Create updated user
      final updatedUser = User(
        id: currentUser.id,
        name: _nameController.text.trim(),
        email: currentUser.email, // Email cannot be changed
        role: currentUser.role, // Role cannot be changed by user
        department: _departmentController.text.trim(),
        profileImageUrl: profileImageUrl,
        phoneNumber: _phoneController.text.trim(),
        badgeNumber: _badgeController.text.trim(),
        assignedDogIds: currentUser.assignedDogIds,
      );

      // Update profile
      await authProvider.updateProfile(updatedUser);
      
      print('Profile updated in provider. Current user image URL: ${authProvider.currentUser?.profileImageUrl}'); // Debug log
      
      // Give a small delay for Firestore to sync
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Clear local state after successful save
      setState(() {
        _imageFile = null;
        _hasChanges = false;
      });
      
      // Clear the local image file after successful save but keep the changes flag
      // until we navigate away to ensure the UI updates properly
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error saving profile: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: Text('No user data found')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: const Text('Save'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Image Section
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _imageFile != null
                                      ? Image.file(
                                          _imageFile!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        )
                                      : Consumer<AuthProvider>(
                                          builder: (context, authProvider, _) {
                                            return SmartCircleAvatar(
                                              radius: 58,
                                              imagePath: authProvider.currentUser?.profileImageUrl ?? '',
                                              fallbackWidget: Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Colors.grey[400],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _pickImage,
                        child: const Text('Change Profile Photo'),
                      ),
                      const SizedBox(height: 32),

                      // Form Fields
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email field (disabled)
                      TextFormField(
                        controller: _emailController,
                        enabled: false,
                        style: TextStyle(
                          color: Colors.grey[700], // Make text more visible
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Email cannot be changed',
                          prefixIcon: Icon(Icons.email, color: Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: Colors.grey[50], // Lighter background
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          suffixIcon: Icon(
                            Icons.lock,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _departmentController,
                        labelText: 'Department',
                        hintText: 'Enter your department',
                        prefixIcon: Icons.business,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your department';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _phoneController,
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _badgeController,
                        labelText: 'Badge Number',
                        hintText: 'Enter your badge number',
                        prefixIcon: Icons.badge,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your badge number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Role and other info (read-only)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Information',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildReadOnlyField('Role', user.role),
                              const SizedBox(height: 8),
                              _buildReadOnlyField('User ID', user.id),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Save Button
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
                        onPressed: _isLoading ? null : () async {
                          final shouldPop = await _onWillPop();
                          if (shouldPop && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'Save Changes',
                        isLoading: _isLoading,
                        onPressed: _hasChanges && !_isLoading ? _saveProfile : () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

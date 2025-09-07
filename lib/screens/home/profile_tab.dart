import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtech/providers/auth_provider.dart';
import 'package:pawtech/widgets/profile_menu_item.dart';
import 'package:pawtech/screens/auth/login_screen.dart';
import 'package:pawtech/screens/profile/edit_profile_screen.dart';
import 'package:pawtech/screens/profile/change_password_screen.dart';
import 'package:pawtech/widgets/smart_image.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SmartCircleAvatar(
            radius: 50,
            imagePath: user?.profileImageUrl ?? 'https://ui-avatars.com/api/?name=User',
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'user@example.com',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user?.role ?? 'Handler',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.department ?? 'Department',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ProfileMenuItem(
                  icon: Icons.person,
                  title: 'Edit Profile',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.badge,
                  title: 'Badge: ${user?.badgeNumber ?? 'N/A'}',
                  onTap: () {
                    // Show badge details
                  },
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.phone,
                  title: 'Phone: ${user?.phoneNumber ?? 'N/A'}',
                  onTap: () {
                    // Edit phone number
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.security,
                  title: 'Security',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ProfileMenuItem(
                  icon: Icons.info,
                  title: 'About PawTech',
                  onTap: () {
                    // Show about dialog
                    showAboutDialog(
                      context: context,
                      applicationName: 'PawTech',
                      applicationVersion: '1.0.0',
                      applicationIcon: Icon(
                        Icons.pets,
                        color: Theme.of(context).primaryColor,
                        size: 40,
                      ),
                      children: [
                        const Text(
                          'PawTech is an IoT-enabled smart harness and mobile app for canine units with GPS tracking, NFC identification, and geofencing security alerts.',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Developed by: Kian Jake Cornelio, Marious So, Marjobelle Solleza, Arnold Corpuz',
                        ),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.policy,
                  title: 'Privacy Policy',
                  onTap: () {
                    // Show privacy policy
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _logout(context); // Use the new _logout method
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}


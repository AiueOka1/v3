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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.currentUser;
              return SmartCircleAvatar(
                radius: 50,
                imagePath: user?.profileImageUrl ?? '',
                fallbackWidget: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.grey[400],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.currentUser;
              return Column(
                children: [
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
                ],
              );
            },
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
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final user = authProvider.currentUser;
                    return ProfileMenuItem(
                      icon: Icons.badge,
                      title: 'Badge: ${user?.badgeNumber ?? 'N/A'}',
                      onTap: () {
                        // Show badge details
                      },
                    );
                  },
                ),
                const Divider(height: 1),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final user = authProvider.currentUser;
                    return ProfileMenuItem(
                      icon: Icons.phone,
                      title: 'Phone: ${user?.phoneNumber ?? 'N/A'}',
                      onTap: () {
                        // Edit phone number
                      },
                    );
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
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Privacy Policy'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PawTech Privacy Policy',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Last Updated: September 12, 2025\n',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                              _buildPolicySection(
                                'Information We Collect',
                                '• Personal Information: Name, email, phone number, badge number, department\n'
                                '• Device Data: GPS location, device status, battery levels\n'
                                '• Usage Data: App interactions, feature usage, performance metrics\n'
                                '• Canine Data: Dog profiles, training records, medical information',
                              ),
                              _buildPolicySection(
                                'How We Use Your Information',
                                '• Provide location tracking and safety monitoring services\n'
                                '• Send geofencing alerts and notifications\n'
                                '• Maintain and improve app functionality\n'
                                '• Ensure security and prevent unauthorized access\n'
                                '• Generate analytics and reports for operational efficiency',
                              ),
                              _buildPolicySection(
                                'Information Sharing',
                                '• We do not sell or rent your personal information\n'
                                '• Data may be shared with authorized personnel within your department\n'
                                '• Emergency information may be shared with first responders when necessary\n'
                                '• We may share anonymized data for research and development',
                              ),
                              _buildPolicySection(
                                'Data Security',
                                '• All data is encrypted in transit and at rest\n'
                                '• Access is restricted to authorized personnel only\n'
                                '• Regular security audits and monitoring\n'
                                '• Secure cloud infrastructure with Firebase/Google Cloud',
                              ),
                              _buildPolicySection(
                                'Data Retention',
                                '• Personal data is retained while you have an active account\n'
                                '• Location data is retained for 90 days for operational purposes\n'
                                '• You may request data deletion by contacting support\n'
                                '• Some data may be retained longer for legal compliance',
                              ),
                              _buildPolicySection(
                                'Your Rights',
                                '• Access and review your personal information\n'
                                '• Request corrections to inaccurate data\n'
                                '• Request deletion of your account and data\n'
                                '• Opt-out of non-essential communications\n'
                                '• Contact us with privacy concerns or questions',
                              ),
                              _buildPolicySection(
                                'Contact Information',
                                'For privacy-related questions or concerns:\n'
                                'Email: pawtechsender@gmail.com\n'
                                'Phone: [09297523789]',
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'This privacy policy may be updated periodically. Users will be notified of significant changes.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Development/Debug Section
          /*
          Card(
            margin: EdgeInsets.zero,
            color: Colors.grey[50],
            child: Column(
              children: [
                ProfileMenuItem(
                  icon: Icons.developer_mode,
                  title: 'Device Assignment Debug',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DeviceAssignmentDebugScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ), */
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


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'package:pawtech/models/dog.dart';
import 'package:pawtech/providers/auth_provider.dart';
import 'package:pawtech/providers/dog_provider.dart';
import 'package:pawtech/providers/alert_provider.dart';
import 'package:pawtech/widgets/dog_status_card.dart';
import 'package:pawtech/widgets/stats_card.dart';
import 'package:pawtech/widgets/alert_card.dart';
import 'package:pawtech/screens/home/home_screen.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  void _handleAlertTap(BuildContext context, String alertId) {
    Future.microtask(() {
      Provider.of<AlertProvider>(context, listen: false).markAlertAsRead(alertId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final dogProvider = Provider.of<DogProvider>(context, listen: false);
        final alertProvider = Provider.of<AlertProvider>(context, listen: false);
        
        await dogProvider.fetchDogs();
        await alertProvider.fetchAlerts();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Consumer3<AuthProvider, DogProvider, AlertProvider>(
          builder: (context, authProvider, dogProvider, alertProvider, child) {
            final user = authProvider.currentUser;
            final dogs = dogProvider.dogs;
            final activeDogs = dogs.where((dog) => dog.isActive).toList();
            final unreadAlerts = alertProvider.unreadAlerts;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user?.name ?? 'Handler'}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s your canine unit overview',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Total Dogs',
                        value: dogs.length.toString(),
                        icon: Icons.pets,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: 'Active Dogs',
                        value: activeDogs.length.toString(),
                        icon: Icons.check_circle,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Alerts',
                        value: alertProvider.unreadCount.toString(),
                        icon: Icons.notifications,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()), // Empty space to maintain layout
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Dogs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to dogs tab
                        HomeScreen.homeScreenKey.currentState?.changeTab(2);
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (dogProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (activeDogs.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        Icon(
                          Icons.pets,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active dogs found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeDogs.length > 2 ? 2 : activeDogs.length,
                    itemBuilder: (context, index) {
                      final dog = activeDogs[index];
                      return DogStatusCard(dog: dog);
                    },
                  ),
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Alerts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to alerts tab
                        HomeScreen.homeScreenKey.currentState?.changeTab(3);
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (alertProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (unreadAlerts.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No unread alerts',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: unreadAlerts.length > 3 ? 3 : unreadAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = unreadAlerts[index];
                      return AlertCard(
                        alert: alert,
                        onTap: () => _handleAlertTap(context, alert.id),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}


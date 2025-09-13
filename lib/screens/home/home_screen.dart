import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtech/providers/auth_provider.dart';
import 'package:pawtech/providers/dog_provider.dart';
import 'package:pawtech/providers/alert_provider.dart';
import 'package:pawtech/screens/auth/login_screen.dart';
import 'package:pawtech/screens/home/dashboard_tab.dart';
import 'package:pawtech/screens/home/map_tab.dart';
import 'package:pawtech/screens/home/dogs_tab.dart';
import 'package:pawtech/screens/home/alerts_tab.dart';
import 'package:pawtech/screens/home/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  static final GlobalKey<_HomeScreenState> homeScreenKey =
      GlobalKey<_HomeScreenState>();

  HomeScreen({Key? key}) : super(key: homeScreenKey);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const DashboardTab(),
    const MapTab(),
    const DogsTab(),
    const AlertsTab(),
    const ProfileTab(),
  ];

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);

    await dogProvider.fetchDogs();
    await alertProvider.fetchAlerts();
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = Provider.of<AlertProvider>(context);
    final unreadCount = alertProvider.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PawTech'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (ctx) => AlertDialog(
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
                            _logout();
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          const BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Dogs'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

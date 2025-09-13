import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtech/providers/auth_provider.dart';
import 'package:pawtech/screens/auth/login_screen.dart';
import 'package:pawtech/screens/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _authChecked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    
    await Future.wait<dynamic>([
      Future.delayed(_controller.duration!), 
      authProvider.initialize(), 
    ]);

    setState(() => _authChecked = true);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => authProvider.isAuthenticated
              ? HomeScreen()
              : const LoginScreen(),
        ),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColorDark,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _animation,
                child: ScaleTransition(
                  scale: _animation,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(75),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.pets,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeTransition(
                opacity: _animation,
                child: Text(
                  'PawTech',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _animation,
                child: Text(
                  'Smart Canine Management',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _animation,
                child: Text(
                  'Caloocan K-9 Unit',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 50),
              _authChecked
                  ? const SizedBox.shrink()
                  : const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

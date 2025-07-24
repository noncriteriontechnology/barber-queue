import 'package:flutter/material.dart';
import '../services/mock_auth_service.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  _initializeAndNavigate() async {
    try {
      // Initialize MockAuth with demo users
      await MockAuthService.initialize();
      
      // Wait for splash delay
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // Check if user is logged in
        if (MockAuthService.isLoggedIn) {
          Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
        } else {
          Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
        }
      }
    } catch (e) {
      // If initialization fails, go to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.content_cut,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Queue Management System',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

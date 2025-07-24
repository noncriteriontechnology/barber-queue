import 'package:flutter/material.dart';
import '../services/mock_auth_service.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'admin_dashboard.dart';
import 'barber_dashboard.dart';
import 'customer_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockAuthService.currentUser;
    
    // If no user is logged in, redirect to login
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Route to appropriate dashboard based on user role
    switch (user.role) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.barber:
        return const BarberDashboard();
      case UserRole.customer:
        return const CustomerDashboard();
    }
  }
}

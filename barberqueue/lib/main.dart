import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/queue_screen.dart';
import 'screens/add_walkin_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/add_appointment_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/barbers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize OneSignal (temporarily disabled for web compatibility)
  // await NotificationService.initialize();
  
  runApp(const BarberQueueApp());
}

class BarberQueueApp extends StatelessWidget {
  const BarberQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialRoute: AppConstants.splashRoute,
      routes: {
        AppConstants.splashRoute: (context) => const SplashScreen(),
        AppConstants.loginRoute: (context) => const LoginScreen(),
        AppConstants.dashboardRoute: (context) => const DashboardScreen(),
        AppConstants.queueRoute: (context) => const QueueScreen(),
        AppConstants.addWalkinRoute: (context) => const AddWalkinScreen(),
        AppConstants.appointmentsRoute: (context) => const AppointmentsScreen(),
        '/add-appointment': (context) => AddAppointmentScreen(
          selectedDate: ModalRoute.of(context)?.settings.arguments as DateTime?,
        ),
        AppConstants.customersRoute: (context) => const CustomersScreen(),
        AppConstants.barbersRoute: (context) => const BarbersScreen(),
        AppConstants.settingsRoute: (context) => const SettingsScreen(),
      },
    );
  }
}

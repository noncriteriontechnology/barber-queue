import 'package:flutter/material.dart';
import '../services/mock_auth_service.dart';
import '../utils/constants.dart';
import 'queue_screen.dart';
import 'appointments_screen.dart';
import 'customers_screen.dart';
import 'admin/barber_roster_screen.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<_AdminHomeScreenState> _homeScreenKey = GlobalKey();
  
  final List<Widget> _screens = [];
  
  @override
  void initState() {
    super.initState();
    _screens.addAll([
      _AdminHomeScreen(key: _homeScreenKey, onNavigate: _onItemTapped),
      const QueueScreen(),
      const AppointmentsScreen(),
      const CustomersScreen(),
      const BarberRosterScreen(),
      const SettingsScreen(),
      const ReportsScreen(),
    ]);
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.content_cut),
            label: 'Barbers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _AdminHomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  
  const _AdminHomeScreen({super.key, required this.onNavigate});
  
  @override
  State<_AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<_AdminHomeScreen> {

  @override
  Widget build(BuildContext context) {
    final user = MockAuthService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await MockAuthService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user?.name ?? 'Admin'}!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Admin Dashboard - Full Access',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Admin Features Grid
            Text(
              'Admin Features',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildFeatureCard(
                  context,
                  'Queue Management',
                  'Manage walk-in customers and service queue',
                  Icons.queue,
                  Colors.blue,
                  () => _navigateToTab(1),
                ),
                _buildFeatureCard(
                  context,
                  'Appointments',
                  'Schedule and manage customer appointments',
                  Icons.calendar_today,
                  Colors.green,
                  () => _navigateToTab(2),
                ),
                _buildFeatureCard(
                  context,
                  'Customer Management',
                  'View and manage customer database',
                  Icons.people,
                  Colors.orange,
                  () => _navigateToTab(3),
                ),
                _buildFeatureCard(
                  context,
                  'Barber Management',
                  'Manage barber staff and schedules',
                  Icons.content_cut,
                  Colors.purple,
                  () => _navigateToTab(4),
                ),
                _buildFeatureCard(
                  context,
                  'Settings',
                  'Configure services, hours, and sync',
                  Icons.settings,
                  Colors.grey,
                  () => _navigateToTab(5),
                ),
                _buildFeatureCard(
                  context,
                  'Reports',
                  'View analytics and reports (Coming Soon)',
                  Icons.analytics,
                  Colors.teal,
                  () => _showComingSoon(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quick Stats
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Today\'s Queue',
                    '0',
                    Icons.queue,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Appointments',
                    '0',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(int index) {
    // Use the callback to navigate
    widget.onNavigate(index);
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

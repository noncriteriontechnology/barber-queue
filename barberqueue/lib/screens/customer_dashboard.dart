import 'package:flutter/material.dart';
import '../services/mock_auth_service.dart';
import '../utils/constants.dart';
import 'appointments_screen.dart';
import 'customer_self_service_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const _CustomerHomeScreen(),
    const AppointmentsScreen(),
    const _CustomerQueueScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'My Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue),
            label: 'Queue Status',
          ),
        ],
      ),
    );
  }
}

class _CustomerHomeScreen extends StatelessWidget {
  const _CustomerHomeScreen();

  @override
  Widget build(BuildContext context) {
    final user = MockAuthService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('BarberQueue'),
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
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user?.name ?? 'Customer'}!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Book appointments and track your queue status',
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

            // Quick Actions
            Text(
              'Quick Actions',
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
                _buildActionCard(
                  context,
                  'Book Now',
                  'Book a new appointment',
                  Icons.calendar_today,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerSelfServiceScreen(),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  'My Appointments',
                  'View your scheduled appointments',
                  Icons.event,
                  Colors.blue,
                  () => _navigateToTab(1),
                ),
                _buildActionCard(
                  context,
                  'Queue Status',
                  'Check current queue and waiting time',
                  Icons.queue,
                  Colors.orange,
                  () => _navigateToTab(2),
                ),
                _buildActionCard(
                  context,
                  'Services',
                  'View available services and prices',
                  Icons.content_cut,
                  Colors.purple,
                  () => _showServices(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Services Preview
            Text(
              'Our Services',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildServiceItem('Haircut', '30 min', '\$25'),
                    const Divider(),
                    _buildServiceItem('Beard Trim', '15 min', '\$15'),
                    const Divider(),
                    _buildServiceItem('Hair Wash', '10 min', '\$10'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showServices(context),
                        child: const Text('View All Services'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recent Activity
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info, color: Colors.blue),
                      title: const Text('No recent activity'),
                      subtitle: const Text('Your appointment history will appear here'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
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

  Widget _buildServiceItem(String name, String duration, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.content_cut, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTab(int index) {
    // This would be handled by the parent widget
  }

  void _showServices(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Available Services'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildServiceItem('Haircut', '30 min', '\$25'),
            const Divider(),
            _buildServiceItem('Beard Trim', '15 min', '\$15'),
            const Divider(),
            _buildServiceItem('Hair Wash', '10 min', '\$10'),
            const Divider(),
            _buildServiceItem('Full Service', '45 min', '\$35'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, AppConstants.addAppointmentRoute);
            },
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }
}

class _CustomerQueueScreen extends StatelessWidget {
  const _CustomerQueueScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Status'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.queue,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No Active Queue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You are not currently in the queue.\nBook an appointment or visit the shop to join.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

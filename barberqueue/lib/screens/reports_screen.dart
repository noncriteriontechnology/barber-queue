import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/barber.dart';
import '../models/service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  
  // Metrics
  int _todayQueueCount = 0;
  int _todayAppointmentsCount = 0;
  String _mostUsedService = 'Loading...';
  String _mostActiveBarber = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get queue items for today
      final queueItems = await _storageService.getQueueItems();
      _todayQueueCount = queueItems.where((item) => 
        item.timestamp.isAfter(today)
      ).length;
      
      // Get appointments for today
      final appointments = await _storageService.getAppointments();
      _todayAppointmentsCount = appointments.where((appt) => 
        appt.datetime.isAfter(today) && 
        appt.datetime.isBefore(today.add(const Duration(days: 1)))
      ).length;
      
      // Get most used service
      final services = await _storageService.getServices();
      if (services.isNotEmpty) {
        final serviceCounts = <int, int>{};
        for (final appt in appointments) {
          serviceCounts[appt.serviceId] = (serviceCounts[appt.serviceId] ?? 0) + 1;
        }
        
        if (serviceCounts.isNotEmpty) {
          final mostUsedServiceId = serviceCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b).key;
          final service = services.firstWhere(
            (s) => s.id == mostUsedServiceId,
            orElse: () => Service(
              id: -1, 
              name: 'Unknown', 
              price: 0, 
              duration: 30,
              createdAt: DateTime.now(),
            ),
          );
          _mostUsedService = service.name;
        } else {
          _mostUsedService = 'No data';
        }
      }
      
      // Get most active barber
      final barbers = await _storageService.getBarbers();
      if (barbers.isNotEmpty) {
        final barberCounts = <int, int>{};
        for (final appt in appointments) {
          if (appt.barberId != null) {
            barberCounts[appt.barberId!] = (barberCounts[appt.barberId] ?? 0) + 1;
          }
        }
        
        if (barberCounts.isNotEmpty) {
          final mostActiveBarberId = barberCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b).key;
          final barber = barbers.firstWhere(
            (b) => b.id == mostActiveBarberId,
            orElse: () => Barber(
              id: -1, 
              name: 'Unknown Barber',
              status: 'active',
              userId: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          _mostActiveBarber = barber.name;
        } else {
          _mostActiveBarber = 'No data';
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading reports: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading reports data')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadReportsData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatCard(
                        context,
                        'Today\'s Queue',
                        _todayQueueCount.toString(),
                        Icons.people_alt_outlined,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        context,
                        'Today\'s Appointments',
                        _todayAppointmentsCount.toString(),
                        Icons.calendar_today,
                        Colors.green,
                      ),
                      _buildStatCard(
                        context,
                        'Most Used Service',
                        _mostUsedService,
                        Icons.auto_awesome_motion,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        context,
                        'Most Active Barber',
                        _mostActiveBarber,
                        Icons.face_retouching_natural,
                        Colors.purple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Additional Reports Section
                  const Text(
                    'Additional Reports',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildReportTile(
                    context,
                    'Service Performance',
                    'View detailed analytics for each service',
                    Icons.analytics,
                    () => _showComingSoon(context),
                  ),
                  _buildReportTile(
                    context,
                    'Barber Performance',
                    'Track barber productivity and ratings',
                    Icons.bar_chart,
                    () => _showComingSoon(context),
                  ),
                  _buildReportTile(
                    context,
                    'Revenue Report',
                    'View revenue by service, barber, and period',
                    Icons.attach_money,
                    () => _showComingSoon(context),
                  ),
                ],
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReportTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
  
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is coming soon!')),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/queue_item.dart';
import '../models/customer.dart';
import '../models/service.dart';
import '../models/appointment.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final StorageService _storageService = StorageService();
  List<QueueItem> _queueItems = [];
  List<Appointment> _todaysAppointments = [];
  Map<int, Customer> _customers = {};
  Map<int, Service> _services = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final queueItems = await _storageService.getQueueItems();
      final customers = await _storageService.getCustomers();
      final services = await _storageService.getServices();
      final todaysAppointments = await _storageService.getAppointmentsForDate(DateTime.now());

      setState(() {
        _queueItems = queueItems;
        _todaysAppointments = todaysAppointments.where((apt) => apt.status == 'Scheduled').toList();
        _customers = {for (var customer in customers) customer.id!: customer};
        _services = {for (var service in services) service.id!: service};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _updateQueueItemStatus(QueueItem item, String newStatus) async {
    try {
      final updatedItem = item.copyWith(
        status: newStatus,
        startedAt: newStatus == AppConstants.statusStarted ? DateTime.now() : item.startedAt,
        completedAt: newStatus == AppConstants.statusCompleted ? DateTime.now() : item.completedAt,
      );
      
      await _storageService.updateQueueItem(updatedItem);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _moveAppointmentToQueue(Appointment appointment) async {
    try {
      // Create a queue item from the appointment
      final queueItem = QueueItem(
        customerId: appointment.customerId,
        serviceId: appointment.serviceId,
        barberId: appointment.barberId,
        status: AppConstants.statusWaiting,
        notes: appointment.notes,
        timestamp: DateTime.now(),
      );
      
      // Add to queue
      await _storageService.insertQueueItem(queueItem);
      
      // Update appointment status to 'In Progress'
      final updatedAppointment = appointment.copyWith(status: 'In Progress');
      await _storageService.updateAppointment(updatedAppointment);
      
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment moved to queue!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving appointment to queue: $e')),
      );
    }
  }

  Widget _buildQueueCard(QueueItem item) {
    final customer = _customers[item.customerId];
    final service = _services[item.serviceId];
    
    if (customer == null || service == null) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    IconData statusIcon;
    
    switch (item.status) {
      case AppConstants.statusWaiting:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case AppConstants.statusStarted:
        statusColor = Colors.blue;
        statusIcon = Icons.play_arrow;
        break;
      case AppConstants.statusCompleted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Service: ${service.name}',
              style: const TextStyle(fontSize: 16),
            ),
            if (customer.phone != null) ...[
              const SizedBox(height: 4),
              Text(
                'Phone: ${customer.phone}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${item.notes}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (item.status == AppConstants.statusWaiting) ...[
                  ElevatedButton.icon(
                    onPressed: () => _updateQueueItemStatus(item, AppConstants.statusStarted),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (item.status == AppConstants.statusStarted) ...[
                  ElevatedButton.icon(
                    onPressed: () => _updateQueueItemStatus(item, AppConstants.statusCompleted),
                    icon: const Icon(Icons.check),
                    label: const Text('Complete'),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: () => _updateQueueItemStatus(item, AppConstants.statusCancelled),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final customer = _customers[appointment.customerId];
    final service = _services[appointment.serviceId];
    
    if (customer == null || service == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    DateFormat('HH:mm').format(appointment.datetime),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Service: ${service.name}',
              style: const TextStyle(fontSize: 16),
            ),
            if (customer.phone != null) ...[
              const SizedBox(height: 4),
              Text(
                'Phone: ${customer.phone}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${appointment.notes}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _moveAppointmentToQueue(appointment),
                icon: const Icon(Icons.add_to_queue),
                label: const Text('Add to Queue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Appointments Section
                  if (_todaysAppointments.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Today\'s Appointments (${DateFormat('MMM dd').format(DateTime.now())})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...(_todaysAppointments.map((appointment) => _buildAppointmentCard(appointment)).toList()),
                    const Divider(thickness: 2),
                  ],
                  
                  // Queue Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Current Queue (${_queueItems.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  if (_queueItems.isEmpty && _todaysAppointments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.queue,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No customers in queue',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a walk-in customer or move an appointment to queue',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_queueItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Queue is empty. Move appointments to queue when customers arrive.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...(_queueItems.map((item) => _buildQueueCard(item)).toList()),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppConstants.addWalkinRoute)
              .then((_) => _loadData());
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Walk-in'),
      ),
    );
  }
}

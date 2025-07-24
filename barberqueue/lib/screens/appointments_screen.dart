import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/service.dart';
import '../models/barber.dart';
import '../utils/constants.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final StorageService _storageService = StorageService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Appointment> _appointments = [];
  List<Appointment> _selectedDayAppointments = [];
  Map<int, Customer> _customers = {};
  Map<int, Service> _services = {};
  Map<int, Barber> _barbers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final appointments = await _storageService.getAppointments();
      final customers = await _storageService.getCustomers();
      final services = await _storageService.getServices();
      final barbers = await _storageService.getBarbers();

      setState(() {
        _appointments = appointments;
        _customers = {for (var customer in customers) customer.id!: customer};
        _services = {for (var service in services) service.id!: service};
        _barbers = {for (var barber in barbers) barber.id!: barber};
        _isLoading = false;
      });
      
      _updateSelectedDayAppointments();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointments: $e')),
      );
    }
  }

  void _updateSelectedDayAppointments() {
    setState(() {
      _selectedDayAppointments = _appointments
          .where((appointment) => 
              appointment.datetime.year == _selectedDay.year &&
              appointment.datetime.month == _selectedDay.month &&
              appointment.datetime.day == _selectedDay.day)
          .toList()
        ..sort((a, b) => a.datetime.compareTo(b.datetime));
    });
  }

  List<Appointment> _getAppointmentsForDay(DateTime day) {
    return _appointments
        .where((appointment) => 
            appointment.datetime.year == day.year &&
            appointment.datetime.month == day.month &&
            appointment.datetime.day == day.day)
        .toList();
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final customer = _customers[appointment.customerId];
    final service = _services[appointment.serviceId];
    final barber = _barbers[appointment.barberId];
    
    if (customer == null || service == null) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    switch (appointment.status) {
      case 'Scheduled':
        statusColor = Colors.blue;
        break;
      case 'Completed':
        statusColor = Colors.green;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            Icons.schedule,
            color: statusColor,
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${service.name}'),
            Text('Time: ${DateFormat('HH:mm').format(appointment.datetime)}'),
            if (barber != null) Text('Barber: ${barber.name}'),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              Text('Notes: ${appointment.notes}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor),
          ),
          child: Text(
            appointment.status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () => _showAppointmentDetails(appointment),
      ),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    final customer = _customers[appointment.customerId];
    final service = _services[appointment.serviceId];
    final barber = _barbers[appointment.barberId];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${customer?.name ?? 'Unknown'}'),
            Text('Service: ${service?.name ?? 'Unknown'}'),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(appointment.datetime)}'),
            Text('Time: ${DateFormat('HH:mm').format(appointment.datetime)}'),
            if (barber != null) Text('Barber: ${barber.name}'),
            Text('Status: ${appointment.status}'),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              Text('Notes: ${appointment.notes}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (appointment.status == 'Scheduled') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateAppointmentStatus(appointment, 'Completed');
              },
              child: const Text('Mark Complete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateAppointmentStatus(appointment, 'Cancelled');
              },
              child: const Text('Cancel'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateAppointmentStatus(Appointment appointment, String newStatus) async {
    try {
      final updatedAppointment = appointment.copyWith(status: newStatus);
      await _storageService.updateAppointment(updatedAppointment);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar<Appointment>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getAppointmentsForDay,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: false,
                    markersMaxCount: 3,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _updateSelectedDayAppointments();
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(_selectedDay),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_selectedDayAppointments.length} appointments',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedDayAppointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No appointments for this day',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _selectedDayAppointments.length,
                          itemBuilder: (context, index) {
                            return _buildAppointmentCard(_selectedDayAppointments[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/add-appointment', arguments: _selectedDay)
              .then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('Book Appointment'),
      ),
    );
  }
}

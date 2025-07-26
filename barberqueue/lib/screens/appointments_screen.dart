import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _updateSelectedDayAppointments();
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        eventLoader: (day) {
          return _getAppointmentsForDay(day).map((appt) => appt.id).toList();
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments for ${DateFormat('MMMM d, y').format(_selectedDay)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Tap + to add a new appointment'),
        ],
      ),
    );
  }

  Widget _buildAppointmentList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _selectedDayAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _selectedDayAppointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final customer = _customers[appointment.customerId];
    final service = _services[appointment.serviceId];
    final barber = _barbers[appointment.barberId];
    
    if (customer == null || service == null) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    IconData statusIcon;
    switch (appointment.status) {
      case 'Scheduled':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case 'Completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      case 'No-show':
        statusColor = Colors.orange;
        statusIcon = Icons.person_off_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.name),
            if (barber != null) Text('Barber: ${barber.name}'),
            Text(
              '${DateFormat('h:mm a').format(appointment.datetime)} • ${appointment.status}',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (appointment.notes?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  appointment.notes!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        onTap: () => _showAppointmentDetails(appointment),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                _showEditAppointmentDialog(appointment);
                break;
              case 'delete':
                await _confirmDeleteAppointment(appointment);
                break;
              case 'complete':
                await _updateAppointmentStatus(appointment, 'Completed');
                break;
              case 'cancel':
                await _updateAppointmentStatus(appointment, 'Cancelled');
                break;
              case 'no_show':
                await _updateAppointmentStatus(appointment, 'No-show');
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit, size: 20),
                title: const Text('Edit'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  _showEditAppointmentDialog(appointment);
                },
              ),
            ),
            if (appointment.status != 'Completed')
              PopupMenuItem(
                value: 'complete',
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                  title: const Text('Mark as Completed'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    _updateAppointmentStatus(appointment, 'Completed');
                  },
                ),
              ),
            if (appointment.status != 'Cancelled')
              PopupMenuItem(
                value: 'cancel',
                child: ListTile(
                  leading: const Icon(Icons.cancel_outlined, size: 20, color: Colors.red),
                  title: const Text('Cancel Appointment'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    _updateAppointmentStatus(appointment, 'Cancelled');
                  },
                ),
              ),
            if (appointment.status != 'No-show')
              PopupMenuItem(
                value: 'no_show',
                child: ListTile(
                  leading: const Icon(Icons.person_off_outlined, size: 20, color: Colors.orange),
                  title: const Text('Mark as No-show'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    _updateAppointmentStatus(appointment, 'No-show');
                  },
                ),
              ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                title: const Text('Delete'),
                textColor: Theme.of(context).colorScheme.error,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteAppointment(appointment);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    final customer = _customers[appointment.customerId];
    final service = _services[appointment.serviceId];
    final barber = _barbers[appointment.barberId];

    if (customer == null || service == null) return;

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
      case 'No-show':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer', customer.name, Icons.person_outline),
              _buildDetailRow('Service', service.name, Icons.work_outline),
              if (barber != null) _buildDetailRow('Barber', barber.name, Icons.face_retouching_natural),
              const SizedBox(height: 16),
              _buildDetailRow('Date', DateFormat('EEEE, MMMM d, y').format(appointment.datetime), Icons.calendar_today),
              _buildDetailRow('Time', DateFormat('h:mm a').format(appointment.datetime), Icons.access_time),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appointment.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (appointment.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(appointment.notes!),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditAppointmentDialog(appointment);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAppointmentDialog(Appointment appointment) async {
    final customers = await _storageService.getCustomers();
    final services = await _storageService.getServices();
    final barbers = await _storageService.getBarbers();

    if (customers.isEmpty || services.isEmpty || barbers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add customers, services, and barbers first')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    int? selectedCustomerId = appointment.customerId;
    int? selectedServiceId = appointment.serviceId;
    int? selectedBarberId = appointment.barberId;
    DateTime selectedDate = appointment.datetime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(appointment.datetime);
    String notes = appointment.notes ?? '';
    String status = appointment.status;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Appointment'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedCustomerId,
                    decoration: const InputDecoration(labelText: 'Customer'),
                    items: customers
                        .map((customer) => DropdownMenuItem(
                              value: customer.id,
                              child: Text(customer.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedCustomerId = value!),
                    validator: (value) => value == null ? 'Please select a customer' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedServiceId,
                    decoration: const InputDecoration(labelText: 'Service'),
                    items: services
                        .map((service) => DropdownMenuItem(
                              value: service.id,
                              child: Text(service.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedServiceId = value!),
                    validator: (value) => value == null ? 'Please select a service' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedBarberId,
                    decoration: const InputDecoration(labelText: 'Barber'),
                    items: barbers
                        .map((barber) => DropdownMenuItem(
                              value: barber.id,
                              child: Text(barber.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedBarberId = value!),
                    validator: (value) => value == null ? 'Please select a barber' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Date'),
                          controller: TextEditingController(
                              text: DateFormat('MMM d, y').format(selectedDate)),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Time'),
                          controller: TextEditingController(
                              text: selectedTime.format(context)),
                          readOnly: true,
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setState(() => selectedTime = time);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                      DropdownMenuItem(value: 'No-show', child: Text('No-show')),
                    ],
                    onChanged: (value) => setState(() => status = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    initialValue: notes,
                    onChanged: (value) => notes = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final updatedAppointment = appointment.copyWith(
                    customerId: selectedCustomerId!,
                    serviceId: selectedServiceId!,
                    barberId: selectedBarberId!,
                    datetime: DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    ),
                    status: status,
                    notes: notes.isNotEmpty ? notes : null,
                    updatedAt: DateTime.now(),
                  );

                  await _storageService.updateAppointment(updatedAppointment);
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAppointmentDialog() async {
    final customers = await _storageService.getCustomers();
    final services = await _storageService.getServices();
    final barbers = await _storageService.getBarbers();

    if (customers.isEmpty || services.isEmpty || barbers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add customers, services, and barbers first')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    int? selectedCustomerId = customers.isNotEmpty ? customers.first.id : null;
    int? selectedServiceId = services.isNotEmpty ? services.first.id : null;
    int? selectedBarberId = barbers.isNotEmpty ? barbers.first.id : null;
    DateTime selectedDate = _selectedDay;
    TimeOfDay selectedTime = TimeOfDay.now();
    String notes = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Appointment'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedCustomerId,
                    decoration: const InputDecoration(labelText: 'Customer'),
                    items: customers
                        .map((customer) => DropdownMenuItem(
                              value: customer.id,
                              child: Text(customer.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedCustomerId = value!),
                    validator: (value) => value == null ? 'Please select a customer' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedServiceId,
                    decoration: const InputDecoration(labelText: 'Service'),
                    items: services
                        .map((service) => DropdownMenuItem(
                              value: service.id,
                              child: Text(service.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedServiceId = value!),
                    validator: (value) => value == null ? 'Please select a service' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedBarberId,
                    decoration: const InputDecoration(labelText: 'Barber'),
                    items: barbers
                        .map((barber) => DropdownMenuItem(
                              value: barber.id,
                              child: Text(barber.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedBarberId = value!),
                    validator: (value) => value == null ? 'Please select a barber' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Date'),
                          controller: TextEditingController(
                              text: DateFormat('MMM d, y').format(selectedDate)),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Time'),
                          controller: TextEditingController(
                              text: selectedTime.format(context)),
                          readOnly: true,
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setState(() => selectedTime = time);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    onChanged: (value) => notes = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newAppointment = Appointment(
                    id: 0, // Will be set by the database
                    customerId: selectedCustomerId!,
                    serviceId: selectedServiceId!,
                    barberId: selectedBarberId!,
                    datetime: DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    ),
                    status: 'Scheduled',
                    notes: notes.isNotEmpty ? notes : null,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  await _storageService.insertAppointment(newAppointment);
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _storageService.deleteAppointment(appointment.id!);
      _loadData();
    }
  }

  Future<void> _updateAppointmentStatus(Appointment appointment, String status) async {
    await _storageService.updateAppointmentStatus(appointment.id!, status);
    _loadData();
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
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddAppointmentDialog,
            tooltip: 'Add Appointment',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendar(),
                const Divider(height: 1),
                Expanded(
                  child: _selectedDayAppointments.isEmpty
                      ? _buildEmptyState()
                      : _buildAppointmentList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAppointmentDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

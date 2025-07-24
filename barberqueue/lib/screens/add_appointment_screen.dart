import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/customer.dart';
import '../models/service.dart';
import '../models/barber.dart';
import '../models/appointment.dart';

class AddAppointmentScreen extends StatefulWidget {
  final DateTime? selectedDate;
  
  const AddAppointmentScreen({super.key, this.selectedDate});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  final StorageService _storageService = StorageService();
  
  List<Service> _services = [];
  List<Barber> _barbers = [];
  Service? _selectedService;
  Barber? _selectedBarber;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _selectedTime = TimeOfDay.now();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final services = await _storageService.getServices();
      final barbers = await _storageService.getBarbers();
      
      setState(() {
        _services = services;
        _barbers = barbers;
        _selectedService = services.isNotEmpty ? services.first : null;
        _selectedBarber = barbers.isNotEmpty ? barbers.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate() || 
        _selectedService == null || 
        _selectedDate == null || 
        _selectedTime == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // First, create or find the customer
      final customer = Customer(
        name: _customerNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        visits: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customerId = await _storageService.insertCustomer(customer);

      // Create the appointment datetime
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Create the appointment
      final appointment = Appointment(
        customerId: customerId,
        serviceId: _selectedService!.id!,
        barberId: _selectedBarber?.id,
        datetime: appointmentDateTime,
        status: 'Scheduled',
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _storageService.insertAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking appointment: $e')),
      );
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Customer Information Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer Information',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _customerNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Customer Name *',
                                  hintText: 'Enter customer name',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter customer name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number (Optional)',
                                  hintText: 'Enter phone number',
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Appointment Details Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appointment Details',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Date Selection
                              InkWell(
                                onTap: _selectDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date *',
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(
                                    _selectedDate != null
                                        ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                                        : 'Select date',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Time Selection
                              InkWell(
                                onTap: _selectTime,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Time *',
                                    prefixIcon: Icon(Icons.access_time),
                                  ),
                                  child: Text(
                                    _selectedTime != null
                                        ? _selectedTime!.format(context)
                                        : 'Select time',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Service Selection
                              DropdownButtonFormField<Service>(
                                value: _selectedService,
                                decoration: const InputDecoration(
                                  labelText: 'Service *',
                                  prefixIcon: Icon(Icons.content_cut),
                                ),
                                items: _services.map((service) {
                                  return DropdownMenuItem<Service>(
                                    value: service,
                                    child: Text('${service.name} (${service.duration} min)'),
                                  );
                                }).toList(),
                                onChanged: (Service? newValue) {
                                  setState(() {
                                    _selectedService = newValue;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a service';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Barber Selection
                              DropdownButtonFormField<Barber>(
                                value: _selectedBarber,
                                decoration: const InputDecoration(
                                  labelText: 'Barber (Optional)',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                items: _barbers.map((barber) {
                                  return DropdownMenuItem<Barber>(
                                    value: barber,
                                    child: Text('${barber.name} (${barber.status})'),
                                  );
                                }).toList(),
                                onChanged: (Barber? newValue) {
                                  setState(() {
                                    _selectedBarber = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // Notes
                              TextFormField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  labelText: 'Notes (Optional)',
                                  hintText: 'Any special requests or notes',
                                  prefixIcon: Icon(Icons.note),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Book Button
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveAppointment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Book Appointment',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

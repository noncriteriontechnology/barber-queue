import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../models/customer.dart';
import '../models/service.dart';
import '../models/queue_item.dart';
import '../utils/constants.dart';

class AddWalkinScreen extends StatefulWidget {
  const AddWalkinScreen({super.key});

  @override
  State<AddWalkinScreen> createState() => _AddWalkinScreenState();
}

class _AddWalkinScreenState extends State<AddWalkinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  final StorageService _storageService = StorageService();
  List<Service> _services = [];
  Service? _selectedService;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final services = await _storageService.getServices();
      setState(() {
        _services = services;
        _selectedService = services.isNotEmpty ? services.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading services: $e')),
      );
    }
  }

  Future<void> _saveWalkin() async {
    if (!_formKey.currentState!.validate() || _selectedService == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // First, create or find the customer
      final customer = Customer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        visits: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customerId = await _storageService.insertCustomer(customer);

      // Then, add to queue
      final queueItem = QueueItem(
        customerId: customerId,
        serviceId: _selectedService!.id!,
        status: AppConstants.statusWaiting,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        timestamp: DateTime.now(),
      );

      await _storageService.insertQueueItem(queueItem);

      // Get queue position
      final queueItems = await _storageService.getQueueItems();
      final position = queueItems.length;
      
      // Send push notification for new queue entry
      await NotificationService.sendNewQueueEntryNotification(
        customerName: _nameController.text.trim(),
        serviceName: _selectedService!.name,
        position: position.toString(),
        estimatedWaitTime: '${_selectedService!.duration} minutes',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Walk-in customer added to queue!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving walk-in: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Walk-in Customer'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Service>(
                      value: _selectedService,
                      decoration: const InputDecoration(
                        labelText: 'Service Type *',
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
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Any special requests or notes',
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveWalkin,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add to Queue'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

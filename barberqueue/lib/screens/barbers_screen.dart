import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/barber.dart';
import '../utils/constants.dart';

class BarbersScreen extends StatefulWidget {
  const BarbersScreen({super.key});

  @override
  State<BarbersScreen> createState() => _BarbersScreenState();
}

class _BarbersScreenState extends State<BarbersScreen> {
  final StorageService _storageService = StorageService();
  List<Barber> _barbers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBarbers();
  }

  Future<void> _loadBarbers() async {
    setState(() => _isLoading = true);
    
    try {
      final barbers = await _storageService.getBarbers();
      setState(() {
        _barbers = barbers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading barbers: $e')),
      );
    }
  }

  void _showAddBarberDialog() {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedStatus = AppConstants.barberAvailable;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Barber'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Barber Name *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter barber name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.work),
                  ),
                  items: [
                    AppConstants.barberAvailable,
                    AppConstants.barberOnBreak,
                    AppConstants.barberBusy,
                  ].map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setDialogState(() {
                        selectedStatus = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final barber = Barber(
                      name: nameController.text.trim(),
                      status: selectedStatus,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    
                    await _storageService.insertBarber(barber);
                    Navigator.pop(context);
                    _loadBarbers();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Barber added successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding barber: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBarberDialog(Barber barber) {
    final nameController = TextEditingController(text: barber.name);
    final formKey = GlobalKey<FormState>();
    String selectedStatus = barber.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Barber'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Barber Name *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter barber name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.work),
                  ),
                  items: [
                    AppConstants.barberAvailable,
                    AppConstants.barberOnBreak,
                    AppConstants.barberBusy,
                  ].map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setDialogState(() {
                        selectedStatus = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final updatedBarber = barber.copyWith(
                      name: nameController.text.trim(),
                      status: selectedStatus,
                      updatedAt: DateTime.now(),
                    );
                    
                    await _storageService.updateBarber(updatedBarber);
                    Navigator.pop(context);
                    _loadBarbers();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Barber updated successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating barber: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBarberStatus(Barber barber, String newStatus) async {
    try {
      final updatedBarber = barber.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      
      await _storageService.updateBarber(updatedBarber);
      _loadBarbers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${barber.name} status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Widget _buildBarberCard(Barber barber) {
    Color statusColor;
    IconData statusIcon;
    
    switch (barber.status) {
      case AppConstants.barberAvailable:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case AppConstants.barberOnBreak:
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle;
        break;
      case AppConstants.barberBusy:
        statusColor = Colors.red;
        statusIcon = Icons.work;
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
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Text(
                    barber.name.isNotEmpty ? barber.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barber.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            barber.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditBarberDialog(barber);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (barber.status != AppConstants.barberAvailable) ...[
                  OutlinedButton.icon(
                    onPressed: () => _updateBarberStatus(barber, AppConstants.barberAvailable),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Available'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (barber.status != AppConstants.barberOnBreak) ...[
                  OutlinedButton.icon(
                    onPressed: () => _updateBarberStatus(barber, AppConstants.barberOnBreak),
                    icon: const Icon(Icons.pause_circle, size: 16),
                    label: const Text('On Break'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (barber.status != AppConstants.barberBusy) ...[
                  OutlinedButton.icon(
                    onPressed: () => _updateBarberStatus(barber, AppConstants.barberBusy),
                    icon: const Icon(Icons.work, size: 16),
                    label: const Text('Busy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ],
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
        title: const Text('Barber Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBarbers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _barbers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No barbers added yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first barber to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _barbers.length,
                  itemBuilder: (context, index) {
                    return _buildBarberCard(_barbers[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBarberDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Barber'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../models/customer.dart';
import '../utils/constants.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      final customers = await _storageService.getCustomers();
      if (mounted) {
        setState(() {
          _customers = customers;
          _filteredCustomers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading customers. Please try again.')),
        );
      }
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers
            .where((customer) =>
                customer.name.toLowerCase().contains(query.toLowerCase()) ||
                (customer.phone?.contains(query) ?? false))
            .toList();
      }
    });
  }

  Future<void> _addCustomer(String name, String? phone) async {
    try {
      final customer = Customer(
        name: name.trim(),
        phone: phone?.trim().isEmpty ?? true ? null : phone!.trim(),
        visits: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _storageService.insertCustomer(customer);
      await _loadCustomers();
      
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add customer. Please try again.')),
        );
      }
    }
  }

  Future<void> _updateCustomer(Customer customer) async {
    try {
      await _storageService.updateCustomer(customer);
      await _loadCustomers();
      
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update customer. Please try again.')),
        );
      }
    }
  }

  Future<void> _deleteCustomer(int customerId) async {
    try {
      await _storageService.deleteCustomer(customerId);
      await _loadCustomers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete customer. Please try again.')),
        );
      }
    }
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Customer'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter customer name';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    hintText: 'e.g., +1234567890',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    // You can add phone number formatting here if needed
                  ],
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
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _addCustomer(
                  nameController.text,
                  phoneController.text,
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCustomerDialog(Customer customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter customer name';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    hintText: 'e.g., +1234567890',
                  ),
                  keyboardType: TextInputType.phone,
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
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updatedCustomer = customer.copyWith(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim().isEmpty 
                      ? null 
                      : phoneController.text.trim(),
                  updatedAt: DateTime.now(),
                );
                await _updateCustomer(updatedCustomer);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _deleteCustomer(customer.id!);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    if (_filteredCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No customers found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Tap + to add a new customer'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterCustomers('');
                      },
                    )
                  : null,
            ),
            onChanged: _filterCustomers,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCustomers,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = _filteredCustomers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Text(
                        customer.name.isNotEmpty 
                            ? customer.name[0].toUpperCase() 
                            : '?',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      customer.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: customer.phone != null
                        ? Text(customer.phone!)
                        : const Text('No phone number'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditCustomerDialog(customer),
                          tooltip: 'Edit customer',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _showDeleteConfirmationDialog(customer),
                          tooltip: 'Delete customer',
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ),
                    onTap: () {
                      // TODO: Navigate to customer details screen
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCustomerDialog,
            tooltip: 'Add Customer',
          ),
                          _searchController.clear();
                          _filterCustomers('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterCustomers,
            ),
          ),
          
          // Customer List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _customers.isEmpty 
                                  ? 'No customers yet'
                                  : 'No customers found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _customers.isEmpty
                                  ? 'Add your first customer to get started'
                                  : 'Try a different search term',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          return _buildCustomerCard(_filteredCustomers[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomerDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }
}

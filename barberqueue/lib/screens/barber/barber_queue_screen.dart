import 'package:flutter/material.dart';
import '../../models/queue_item.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';

class BarberQueueScreen extends StatefulWidget {
  static const routeName = '/barber/queue';
  
  final int? barberId;
  
  const BarberQueueScreen({
    super.key,
    this.barberId,
  });

  @override
  State<BarberQueueScreen> createState() => _BarberQueueScreenState();
}

class _BarberQueueScreenState extends State<BarberQueueScreen> {
  final StorageService _storageService = StorageService();
  List<QueueItem> _queueItems = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final items = await _storageService.getQueueItems();
      // Filter by barber if specified and sort by timestamp
      final filteredItems = widget.barberId != null
          ? items.where((item) => item.barberId == widget.barberId).toList()
          : List<QueueItem>.from(items);
          
      filteredItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      setState(() {
        _queueItems = filteredItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load queue: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQueueItemStatus(QueueItem item, String newStatus) async {
    try {
      final updatedItem = item.copyWith(status: newStatus);
      await _storageService.updateQueueItem(updatedItem);
      _loadQueue();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queue updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating queue: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.barberId == null 
            ? const Text('All Barbers Queue')
            : const Text('My Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQueue,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQueue,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_queueItems.isEmpty) {
      return const Center(child: Text('No customers in the queue'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _queueItems.length,
      itemBuilder: (context, index) => _buildQueueItem(_queueItems[index]),
    );
  }

  Widget _buildQueueItem(QueueItem item) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.access_time;
    
    switch (item.status) {
      case AppConstants.statusWaiting:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case AppConstants.statusStarted:
        statusColor = Colors.blue;
        statusIcon = Icons.person;
        break;
      case AppConstants.statusCompleted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case AppConstants.statusCancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadQueueItemDetails(item),
      builder: (context, snapshot) {
        final customerName = snapshot.data?['customerName'] ?? 'Loading...';
        final serviceName = snapshot.data?['serviceName'] ?? 'Loading...';
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.2),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Text(
              customerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service: $serviceName'),
                Text('Status: ${item.status}'),
                if (item.notes?.isNotEmpty ?? false)
                  Text('Notes: ${item.notes}'),
              ],
            ),
            trailing: _buildStatusActions(item),
            onTap: () {
              // Show more details or edit
            },
          ),
        );
      },
    );
  }
  
  Future<Map<String, String>> _loadQueueItemDetails(QueueItem item) async {
    try {
      final customer = await _storageService.getCustomer(item.customerId);
      final service = await _storageService.getService(item.serviceId);
      
      return {
        'customerName': '${customer?.firstName ?? ''} ${customer?.lastName ?? ''}'.trim(),
        'serviceName': service?.name ?? 'Unknown Service',
      };
    } catch (e) {
      debugPrint('Error loading queue item details: $e');
      return {
        'customerName': 'Error loading customer',
        'serviceName': 'Error loading service',
      };
    }
  }

  Widget _buildStatusActions(QueueItem item) {
    if (item.status == AppConstants.statusCompleted || 
        item.status == AppConstants.statusCancelled) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      onSelected: (value) => _updateQueueItemStatus(item, value),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        if (item.status == AppConstants.statusWaiting)
          PopupMenuItem<String>(
            value: AppConstants.statusStarted,
            child: const Text('Start Service'),
          ),
        if (item.status == AppConstants.statusStarted)
          PopupMenuItem<String>(
            value: AppConstants.statusCompleted,
            child: const Text('Mark as Completed'),
          ),
        if (item.status != AppConstants.statusCancelled)
          const PopupMenuItem<String>(
            value: AppConstants.statusCancelled,
            child: Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}

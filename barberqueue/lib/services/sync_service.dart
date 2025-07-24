import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import '../models/customer.dart';
import '../models/barber.dart';
import '../models/service.dart';
import '../models/appointment.dart';
import '../models/queue_item.dart';

class SyncService {
  static const String _baseUrl = 'https://your-backend-api.com/api'; // Replace with actual backend URL
  static final StorageService _storageService = StorageService();
  
  // Check if device is online
  static Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      return false;
    }
  }
  
  // Manual sync - sync all data with backend
  static Future<SyncResult> syncAll() async {
    try {
      if (!await isOnline()) {
        return SyncResult(
          success: false,
          message: 'No internet connection. Please check your network and try again.',
        );
      }
      
      int syncedItems = 0;
      List<String> errors = [];
      
      // Sync customers
      try {
        final customerResult = await _syncCustomers();
        syncedItems += customerResult.syncedCount;
        if (customerResult.error != null) {
          errors.add('Customers: ${customerResult.error}');
        }
      } catch (e) {
        errors.add('Customers: $e');
      }
      
      // Sync barbers
      try {
        final barberResult = await _syncBarbers();
        syncedItems += barberResult.syncedCount;
        if (barberResult.error != null) {
          errors.add('Barbers: ${barberResult.error}');
        }
      } catch (e) {
        errors.add('Barbers: $e');
      }
      
      // Sync services
      try {
        final serviceResult = await _syncServices();
        syncedItems += serviceResult.syncedCount;
        if (serviceResult.error != null) {
          errors.add('Services: ${serviceResult.error}');
        }
      } catch (e) {
        errors.add('Services: $e');
      }
      
      // Sync appointments
      try {
        final appointmentResult = await _syncAppointments();
        syncedItems += appointmentResult.syncedCount;
        if (appointmentResult.error != null) {
          errors.add('Appointments: ${appointmentResult.error}');
        }
      } catch (e) {
        errors.add('Appointments: $e');
      }
      
      // Sync queue items
      try {
        final queueResult = await _syncQueueItems();
        syncedItems += queueResult.syncedCount;
        if (queueResult.error != null) {
          errors.add('Queue: ${queueResult.error}');
        }
      } catch (e) {
        errors.add('Queue: $e');
      }
      
      String message;
      if (errors.isEmpty) {
        message = 'Sync completed successfully! $syncedItems items synced.';
      } else {
        message = 'Sync completed with some errors. $syncedItems items synced.\nErrors: ${errors.join(', ')}';
      }
      
      return SyncResult(
        success: errors.isEmpty,
        message: message,
        syncedCount: syncedItems,
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('Sync error: $e');
      }
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
      );
    }
  }
  
  // Sync customers with backend
  static Future<SyncItemResult> _syncCustomers() async {
    try {
      final customers = await _storageService.getCustomers();
      int syncedCount = 0;
      
      for (final customer in customers) {
        // In a real implementation, you would:
        // 1. Check if customer exists on backend
        // 2. POST new customers or PUT updates
        // 3. Handle conflicts and sync status
        
        // Simulated API call
        final success = await _simulateApiCall('customers', customer.toMap());
        if (success) {
          syncedCount++;
        }
      }
      
      return SyncItemResult(syncedCount: syncedCount);
    } catch (e) {
      return SyncItemResult(syncedCount: 0, error: e.toString());
    }
  }
  
  // Sync barbers with backend
  static Future<SyncItemResult> _syncBarbers() async {
    try {
      final barbers = await _storageService.getBarbers();
      int syncedCount = 0;
      
      for (final barber in barbers) {
        final success = await _simulateApiCall('barbers', barber.toMap());
        if (success) {
          syncedCount++;
        }
      }
      
      return SyncItemResult(syncedCount: syncedCount);
    } catch (e) {
      return SyncItemResult(syncedCount: 0, error: e.toString());
    }
  }
  
  // Sync services with backend
  static Future<SyncItemResult> _syncServices() async {
    try {
      final services = await _storageService.getServices();
      int syncedCount = 0;
      
      for (final service in services) {
        final success = await _simulateApiCall('services', service.toMap());
        if (success) {
          syncedCount++;
        }
      }
      
      return SyncItemResult(syncedCount: syncedCount);
    } catch (e) {
      return SyncItemResult(syncedCount: 0, error: e.toString());
    }
  }
  
  // Sync appointments with backend
  static Future<SyncItemResult> _syncAppointments() async {
    try {
      final appointments = await _storageService.getAppointments();
      int syncedCount = 0;
      
      for (final appointment in appointments) {
        final success = await _simulateApiCall('appointments', appointment.toMap());
        if (success) {
          syncedCount++;
        }
      }
      
      return SyncItemResult(syncedCount: syncedCount);
    } catch (e) {
      return SyncItemResult(syncedCount: 0, error: e.toString());
    }
  }
  
  // Sync queue items with backend
  static Future<SyncItemResult> _syncQueueItems() async {
    try {
      final queueItems = await _storageService.getQueueItems();
      int syncedCount = 0;
      
      for (final queueItem in queueItems) {
        final success = await _simulateApiCall('queue', queueItem.toMap());
        if (success) {
          syncedCount++;
        }
      }
      
      return SyncItemResult(syncedCount: syncedCount);
    } catch (e) {
      return SyncItemResult(syncedCount: 0, error: e.toString());
    }
  }
  
  // Simulate API call (replace with actual HTTP requests)
  static Future<bool> _simulateApiCall(String endpoint, Map<String, dynamic> data) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      // In a real implementation, you would make actual HTTP requests:
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/$endpoint'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode(data),
      // );
      // return response.statusCode == 200 || response.statusCode == 201;
      
      // For demo purposes, simulate success
      if (kDebugMode) {
        print('Simulated sync for $endpoint: ${data['id'] ?? 'new item'}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Simulated API error for $endpoint: $e');
      }
      return false;
    }
  }
  
  // Get last sync time (placeholder)
  static Future<DateTime?> getLastSyncTime() async {
    // In a real implementation, you would store this in local storage
    return null;
  }
  
  // Set last sync time (placeholder)
  static Future<void> setLastSyncTime(DateTime time) async {
    // In a real implementation, you would store this in local storage
    if (kDebugMode) {
      print('Last sync time set: $time');
    }
  }
}

// Result classes for sync operations
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  
  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
  });
}

class SyncItemResult {
  final int syncedCount;
  final String? error;
  
  SyncItemResult({
    required this.syncedCount,
    this.error,
  });
}

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/barber.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class MockAuthService {
  static User? _currentUser;
  static final StorageService _storageService = StorageService();
  
  // Get current user
  static User? get currentUser => _currentUser;
  
  // Check if user is logged in
  static bool get isLoggedIn => _currentUser != null;
  
  // Initialize with demo users
  static Future<void> initialize() async {
    await _createDemoUsers();
  }
  
  // Create demo users for testing
  static Future<void> _createDemoUsers() async {
    // Check if demo users already exist
    final existingAdmin = await _storageService.getUserByEmail('admin@barberqueue.com');
    if (existingAdmin == null) {
      // Create admin user
      final adminSalt = User.generateSalt();
      final adminPassword = 'admin123'; // Default password for demo
      final admin = User(
        id: 1,
        email: 'admin@barberqueue.com',
        name: 'Admin User',
        role: UserRole.admin,
        phone: '+1234567890',
        hashedPassword: User.hashPassword(adminPassword, adminSalt),
        salt: adminSalt,
        isActive: true,
        isVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _storageService.insertUser(admin);
      
      // Create demo barber
      final barberSalt = User.generateSalt();
      final barberPassword = 'barber123';
      final barber = User(
        id: 2,
        email: 'barber@barberqueue.com',
        name: 'John Barber',
        role: UserRole.barber,
        phone: '+1234567891',
        hashedPassword: User.hashPassword(barberPassword, barberSalt),
        salt: barberSalt,
        isActive: true,
        isVerified: true,
        specialization: 'Hair Stylist',
        bio: 'Professional barber with 5+ years of experience',
        rating: 4.8,
        totalAppointments: 120,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _storageService.insertUser(barber);
      
      // Create demo customer
      final customerSalt = User.generateSalt();
      final customerPassword = 'customer123';
      final customer = User(
        id: 3,
        email: 'customer@barberqueue.com',
        name: 'Jane Customer',
        role: UserRole.customer,
        phone: '+1234567892',
        hashedPassword: User.hashPassword(customerPassword, customerSalt),
        salt: customerSalt,
        isActive: true,
        isVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _storageService.insertUser(customer);
    }
  }
  
  // Sign in with email and password
  static Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw 'Please enter both email and password.';
      }
      
      // Get user by email
      final user = await _storageService.getUserByEmail(email);
      
      if (user == null) {
        throw 'No account found with this email address.';
      }
      
      if (!user.isActive) {
        throw 'This account has been deactivated. Please contact support.';
      }
      
      // Verify password
      if (!user.verifyPassword(password)) {
        throw 'Incorrect password. Please try again.';
      }
      
      // Update last login time
      final updatedUser = user.copyWith(
        lastLogin: DateTime.now(),
      );
      
      await _storageService.updateUser(updatedUser);
      _currentUser = updatedUser;
      
      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }
  
  // Register a new user
  static Future<User> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? specialization,
    String? bio,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw 'Please fill in all required fields.';
      }
      
      if (!AppConstants.emailRegex.hasMatch(email)) {
        throw 'Please enter a valid email address.';
      }
      
      if (password.length < 6) {
        throw 'Password must be at least 6 characters long.';
      }
      
      // Check if user already exists
      final existingUser = await _storageService.getUserByEmail(email);
      if (existingUser != null) {
        throw 'An account already exists with this email address.';
      }
      
      // Generate salt and hash password
      final salt = User.generateSalt();
      final hashedPassword = User.hashPassword(password, salt);
      
      // Get next available ID (in a real app, this would be handled by the database)
      final users = await _storageService.getUsers();
      final nextId = users.isEmpty ? 1 : (users.map((u) => u.id ?? 0).reduce((a, b) => a > b ? a : b)) + 1;
      
      // Create new user
      final now = DateTime.now();
      final user = User(
        id: nextId,
        email: email.trim(),
        name: name.trim(),
        role: role,
        phone: phone?.trim(),
        hashedPassword: hashedPassword,
        salt: salt,
        isActive: role != UserRole.barber, // Barbers need admin approval
        isVerified: role != UserRole.barber, // Email verification would be required in a real app
        specialization: specialization?.trim(),
        bio: bio?.trim(),
        rating: 0.0,
        totalAppointments: 0,
        createdAt: now,
        updatedAt: now,
      );
      
      await _storageService.insertUser(user);
      
      // If this is a barber, notify admin for approval
      if (role == UserRole.barber) {
        await _notifyAdminForBarberApproval(user);
      }
      
      _currentUser = user;
      return user;
    } catch (e) {
      rethrow;
    }
  }
  
  // Sign out
  static Future<void> signOut() async {
    _currentUser = null;
    // In a real app, you might want to clear any cached data or tokens here
  }
  
  // Update user profile
  static Future<User> updateProfile({
    required int userId,
    String? name,
    String? phone,
    String? specialization,
    String? bio,
  }) async {
    try {
      final user = await _storageService.getUserById(userId);
      if (user == null) {
        throw 'User not found';
      }
      
      final updatedUser = user.copyWith(
        name: name ?? user.name,
        phone: phone ?? user.phone,
        specialization: specialization ?? user.specialization,
        bio: bio ?? user.bio,
        updatedAt: DateTime.now(),
      );
      
      await _storageService.updateUser(updatedUser);
      
      // Update current user if it's the same user
      if (_currentUser?.id == updatedUser.id) {
        _currentUser = updatedUser;
      }
      
      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update user status (admin only)
  static Future<void> updateUserStatus(int userId, bool isActive) async {
    try {
      final user = await _storageService.getUserById(userId);
      if (user != null) {
        final updatedUser = user.copyWith(isActive: isActive);
        await _storageService.updateUser(updatedUser);
        
        // If this is a barber being activated, update their status in the barbers table
        if (user.role == UserRole.barber && isActive) {
          final barbers = await _storageService.getBarbers();
          final barber = barbers.firstWhere(
            (b) => b.userId == userId,
            orElse: () => Barber(
              id: 0,
              name: user.name,
              status: AppConstants.barberAvailable,
              userId: userId,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          
          if (barber.id == 0) {
            // New barber, add to barbers table
            await _storageService.insertBarber(barber);
          } else {
            // Existing barber, update status
            await _storageService.updateBarber(barber.copyWith(
              status: AppConstants.barberAvailable,
              updatedAt: DateTime.now(),
            ));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error updating user status: $e');
      }
      rethrow;
    }
  }
  
  // Change password
  static Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = await _storageService.getUserById(userId);
      if (user == null) {
        throw 'User not found';
      }
      
      // Verify current password
      if (!user.verifyPassword(currentPassword)) {
        throw 'Current password is incorrect';
      }
      
      // Update password
      final updatedUser = user.withNewPassword(newPassword).copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _storageService.updateUser(updatedUser);
      
      // Update current user if it's the same user
      if (_currentUser?.id == updatedUser.id) {
        _currentUser = updatedUser;
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Get all barbers (for customer booking)
  static Future<List<User>> getBarbers() async {
    try {
      final users = await _storageService.getUsers();
      return users
          .where((user) => user.role == UserRole.barber && user.isActive == true)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error getting barbers: $e');
      }
      rethrow;
    }
  }
  
  // Get barber by ID
  static Future<User?> getBarberById(int id) async {
    try {
      final user = await _storageService.getUserById(id);
      if (user == null || user.role != UserRole.barber || user.isActive != true) {
        return null;
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }
  
  // Notify admin for barber approval (stub for notification)
  static Future<void> _notifyAdminForBarberApproval(User barber) async {
    // In a real app, this would send a notification to admin
    if (kDebugMode) {
      developer.log('New barber registration requires approval: ${barber.name} (${barber.email})');
    }
  }
  
  // Get user display name
  static String get userDisplayName {
    return _currentUser?.name ?? 'Guest';
  }
  
  // Get user email
  static String get userEmail {
    return _currentUser?.email ?? '';
  }
  
  // Get user role
  static UserRole? get userRole {
    return _currentUser?.role;
  }
  
  // Check if current user has permission
  static bool hasPermission(Permission permission) {
    return _currentUser?.role.hasPermission(permission) ?? false;
  }
  
  // Get all users (admin only)
  static Future<List<User>> getAllUsers() async {
    if (!hasPermission(Permission.manageSettings)) {
      throw 'Access denied. Admin permission required.';
    }
    return await _storageService.getUsers();
  }
}

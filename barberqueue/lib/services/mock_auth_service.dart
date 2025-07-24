import '../models/user.dart';
import '../services/storage_service.dart';

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
    final demoUsers = [
      User(
        id: 1,
        email: 'admin@barberqueue.com',
        name: 'Admin User',
        role: UserRole.admin,
        phone: '+1234567890',
        createdAt: DateTime.now(),
      ),
      User(
        id: 2,
        email: 'barber@barberqueue.com',
        name: 'John Barber',
        role: UserRole.barber,
        phone: '+1234567891',
        createdAt: DateTime.now(),
      ),
      User(
        id: 3,
        email: 'customer@barberqueue.com',
        name: 'Jane Customer',
        role: UserRole.customer,
        phone: '+1234567892',
        createdAt: DateTime.now(),
      ),
    ];
    
    // Store demo users (in a real app, this would be in a database)
    for (final user in demoUsers) {
      await _storageService.insertUser(user);
    }
  }
  
  // Sign in with email and password
  static Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Simulate authentication delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get user by email
      final user = await _storageService.getUserByEmail(email);
      
      if (user == null) {
        throw 'No user found with this email address.';
      }
      
      if (!user.isActive) {
        throw 'This account has been disabled.';
      }
      
      // In a real app, you would verify the password hash
      // For demo purposes, accept any password
      if (password.isEmpty) {
        throw 'Please enter your password.';
      }
      
      _currentUser = user;
      return user;
    } catch (e) {
      throw e.toString();
    }
  }
  
  // Register with email, password, and role
  static Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
  }) async {
    try {
      // Simulate registration delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if user already exists
      final existingUser = await _storageService.getUserByEmail(email);
      if (existingUser != null) {
        throw 'An account already exists with this email address.';
      }
      
      // Validate inputs
      if (password.length < 6) {
        throw 'Password must be at least 6 characters long.';
      }
      
      if (name.trim().isEmpty) {
        throw 'Please enter your name.';
      }
      
      // Create new user
      final newUser = User(
        email: email.trim().toLowerCase(),
        name: name.trim(),
        role: role,
        phone: phone?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save user to storage
      final userId = await _storageService.insertUser(newUser);
      final savedUser = newUser.copyWith(id: userId);
      
      _currentUser = savedUser;
      return savedUser;
    } catch (e) {
      throw e.toString();
    }
  }
  
  // Sign out
  static Future<void> signOut() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      _currentUser = null;
    } catch (e) {
      throw 'Error signing out. Please try again.';
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
  
  // Update user status (admin only)
  static Future<void> updateUserStatus(int userId, bool isActive) async {
    if (!hasPermission(Permission.manageSettings)) {
      throw 'Access denied. Admin permission required.';
    }
    
    final user = await _storageService.getUserById(userId);
    if (user != null) {
      final updatedUser = user.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
      await _storageService.updateUser(updatedUser);
    }
  }
}

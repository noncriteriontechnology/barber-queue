import 'package:crypto/crypto.dart';
import 'dart:convert';

class User {
  final int? id;
  final String email;
  final String name;
  final UserRole role;
  final String? phone;
  final String? hashedPassword;
  final String? salt;
  final bool isActive;
  final bool isVerified;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Additional barber-specific fields
  final String? specialization;
  final String? bio;
  final double? rating;
  final int? totalAppointments;

  User({
    this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.hashedPassword,
    this.salt,
    this.isActive = true,
    this.isVerified = false,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
    this.specialization,
    this.bio,
    this.rating,
    this.totalAppointments = 0,
  });
  
  // Generate a random salt
  static String generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(random)).toString();
  }
  
  // Hash password with salt
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password$salt');
    return sha256.convert(bytes).toString();
  }
  
  // Verify password
  bool verifyPassword(String password) {
    if (hashedPassword == null || salt == null) return false;
    return hashedPassword == hashPassword(password, salt!);
  }
  
  // Update password
  User withNewPassword(String newPassword) {
    final newSalt = generateSalt();
    return copyWith(
      hashedPassword: hashPassword(newPassword, newSalt),
      salt: newSalt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'phone': phone,
      'hashed_password': hashedPassword,
      'salt': salt,
      'is_active': isActive ? 1 : 0,
      'is_verified': isVerified ? 1 : 0,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'specialization': specialization,
      'bio': bio,
      'rating': rating,
      'total_appointments': totalAppointments,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == map['role'],
        orElse: () => UserRole.customer,
      ),
      phone: map['phone'],
      hashedPassword: map['hashed_password'],
      salt: map['salt'],
      isActive: map['is_active'] == 1,
      isVerified: map['is_verified'] == 1,
      lastLogin: map['last_login'] != null ? DateTime.parse(map['last_login']) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      specialization: map['specialization'],
      bio: map['bio'],
      rating: map['rating']?.toDouble(),
      totalAppointments: map['total_appointments']?.toInt(),
    );
  }

  User copyWith({
    int? id,
    String? email,
    String? name,
    UserRole? role,
    String? phone,
    String? hashedPassword,
    String? salt,
    bool? isActive,
    bool? isVerified,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? specialization,
    String? bio,
    double? rating,
    int? totalAppointments,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      hashedPassword: hashedPassword ?? this.hashedPassword,
      salt: salt ?? this.salt,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      specialization: specialization ?? this.specialization,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      totalAppointments: totalAppointments ?? this.totalAppointments,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: ${role.displayName})';
  }
}

enum UserRole {
  admin('admin', 'Admin'),
  barber('barber', 'Barber'),
  customer('customer', 'Customer');

  const UserRole(this.name, this.displayName);
  
  final String name;
  final String displayName;

  // Get role permissions
  List<Permission> get permissions {
    switch (this) {
      case UserRole.admin:
        return [
          Permission.manageQueue,
          Permission.manageCustomers,
          Permission.manageBarbers,
          Permission.manageServices,
          Permission.manageAppointments,
          Permission.viewReports,
          Permission.manageSettings,
        ];
      case UserRole.barber:
        return [
          Permission.manageQueue,
          Permission.viewCustomers,
          Permission.manageAppointments,
          Permission.viewOwnSchedule,
        ];
      case UserRole.customer:
        return [
          Permission.bookAppointment,
          Permission.viewOwnAppointments,
          Permission.viewServices,
          Permission.viewQueue,
        ];
    }
  }

  // Check if role has specific permission
  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }
}

enum Permission {
  manageQueue,
  manageCustomers,
  manageBarbers,
  manageServices,
  manageAppointments,
  viewReports,
  manageSettings,
  viewCustomers,
  viewOwnSchedule,
  bookAppointment,
  viewOwnAppointments,
  viewServices,
  viewQueue,
}

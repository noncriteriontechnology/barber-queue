class User {
  final int? id;
  final String email;
  final String name;
  final UserRole role;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'phone': phone,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
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
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }

  User copyWith({
    int? id,
    String? email,
    String? name,
    UserRole? role,
    String? phone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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

class Barber {
  final int? id;
  final String name;
  final String status;
  final int? userId; // Reference to the user account
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Barber({
    this.id,
    required this.name,
    required this.status,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Barber.fromMap(Map<String, dynamic> map) {
    return Barber(
      id: map['id'],
      name: map['name'],
      status: map['status'],
      userId: map['user_id'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }

  Barber copyWith({
    int? id,
    String? name,
    String? status,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Barber(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Barber{id: $id, name: $name, status: $status}';
  }
}

class Appointment {
  final int? id;
  final int customerId;
  final int serviceId;
  final int? barberId;
  final DateTime datetime;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  Appointment({
    this.id,
    required this.customerId,
    required this.serviceId,
    this.barberId,
    required this.datetime,
    this.status = 'Scheduled',
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'service_id': serviceId,
      'barber_id': barberId,
      'datetime': datetime.toIso8601String(),
      'status': status,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      customerId: map['customer_id'],
      serviceId: map['service_id'],
      barberId: map['barber_id'],
      datetime: DateTime.parse(map['datetime']),
      status: map['status'] ?? 'Scheduled',
      notes: map['notes'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }

  Appointment copyWith({
    int? id,
    int? customerId,
    int? serviceId,
    int? barberId,
    DateTime? datetime,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      serviceId: serviceId ?? this.serviceId,
      barberId: barberId ?? this.barberId,
      datetime: datetime ?? this.datetime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Appointment{id: $id, customerId: $customerId, serviceId: $serviceId, datetime: $datetime, status: $status}';
  }
}

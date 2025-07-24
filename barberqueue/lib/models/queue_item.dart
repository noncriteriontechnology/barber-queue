class QueueItem {
  final int? id;
  final int customerId;
  final int serviceId;
  final int? barberId;
  final String status;
  final String? notes;
  final DateTime timestamp;
  final DateTime? startedAt;
  final DateTime? completedAt;

  QueueItem({
    this.id,
    required this.customerId,
    required this.serviceId,
    this.barberId,
    required this.status,
    this.notes,
    required this.timestamp,
    this.startedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'service_id': serviceId,
      'barber_id': barberId,
      'status': status,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory QueueItem.fromMap(Map<String, dynamic> map) {
    return QueueItem(
      id: map['id'],
      customerId: map['customer_id'],
      serviceId: map['service_id'],
      barberId: map['barber_id'],
      status: map['status'],
      notes: map['notes'],
      timestamp: DateTime.parse(map['timestamp']),
      startedAt: map['started_at'] != null 
          ? DateTime.parse(map['started_at']) 
          : null,
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at']) 
          : null,
    );
  }

  QueueItem copyWith({
    int? id,
    int? customerId,
    int? serviceId,
    int? barberId,
    String? status,
    String? notes,
    DateTime? timestamp,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return QueueItem(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      serviceId: serviceId ?? this.serviceId,
      barberId: barberId ?? this.barberId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'QueueItem{id: $id, customerId: $customerId, serviceId: $serviceId, status: $status}';
  }
}

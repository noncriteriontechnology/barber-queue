import '../models/customer.dart';
import '../models/barber.dart';
import '../models/service.dart';
import '../models/queue_item.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // In-memory storage for web
  final List<Customer> _customers = [];
  final List<Barber> _barbers = [];
  final List<Service> _services = [];
  final List<QueueItem> _queueItems = [];
  final List<Appointment> _appointments = [];
  final List<User> _users = [];
  
  int _nextCustomerId = 1;
  int _nextBarberId = 1;
  int _nextServiceId = 1;
  int _nextQueueId = 1;
  int _nextAppointmentId = 1;
  int _nextUserId = 1;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize with default data
    _initializeDefaultData();
    _initialized = true;
  }

  void _initializeDefaultData() {
    // Add default services
    for (int i = 0; i < AppConstants.defaultServices.length; i++) {
      _services.add(Service(
        id: _nextServiceId++,
        name: AppConstants.defaultServices[i],
        duration: 30,
        createdAt: DateTime.now(),
      ));
    }

    // Add default barber
    _barbers.add(Barber(
      id: _nextBarberId++,
      name: 'Main Barber',
      status: AppConstants.barberAvailable,
      createdAt: DateTime.now(),
    ));
  }

  // Customer operations
  Future<int> insertCustomer(Customer customer) async {
    await initialize();
    final newCustomer = customer.copyWith(
      id: _nextCustomerId++,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _customers.add(newCustomer);
    return newCustomer.id!;
  }

  Future<List<Customer>> getCustomers() async {
    await initialize();
    return List.from(_customers);
  }

  Future<Customer?> getCustomer(int id) async {
    await initialize();
    try {
      return _customers.firstWhere((customer) => customer.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateCustomer(Customer customer) async {
    await initialize();
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer.copyWith(updatedAt: DateTime.now());
      return 1;
    }
    return 0;
  }

  Future<int> deleteCustomer(int id) async {
    await initialize();
    final index = _customers.indexWhere((c) => c.id == id);
    if (index != -1) {
      _customers.removeAt(index);
      return 1;
    }
    return 0;
  }

  // Queue operations
  Future<int> insertQueueItem(QueueItem queueItem) async {
    await initialize();
    final newQueueItem = queueItem.copyWith(id: _nextQueueId++);
    _queueItems.add(newQueueItem);
    return newQueueItem.id!;
  }

  Future<List<QueueItem>> getQueueItems() async {
    await initialize();
    return _queueItems
        .where((item) => item.status != AppConstants.statusCompleted)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<int> updateQueueItem(QueueItem queueItem) async {
    await initialize();
    final index = _queueItems.indexWhere((q) => q.id == queueItem.id);
    if (index != -1) {
      _queueItems[index] = queueItem;
      return 1;
    }
    return 0;
  }

  // Service operations
  Future<List<Service>> getServices() async {
    await initialize();
    return List.from(_services);
  }

  Future<int> insertService(Service service) async {
    await initialize();
    final newService = service.copyWith(
      id: _nextServiceId++,
      createdAt: DateTime.now(),
    );
    _services.add(newService);
    return newService.id!;
  }

  Future<int> updateService(Service service) async {
    await initialize();
    final index = _services.indexWhere((s) => s.id == service.id);
    if (index != -1) {
      _services[index] = service.copyWith(updatedAt: DateTime.now());
      return 1;
    }
    return 0;
  }

  Future<int> deleteService(int id) async {
    await initialize();
    final index = _services.indexWhere((s) => s.id == id);
    if (index != -1) {
      _services.removeAt(index);
      return 1;
    }
    return 0;
  }

  // Barber operations
  Future<List<Barber>> getBarbers() async {
    await initialize();
    return List.from(_barbers);
  }

  Future<int> insertBarber(Barber barber) async {
    await initialize();
    final newBarber = barber.copyWith(
      id: _nextBarberId++,
      createdAt: DateTime.now(),
    );
    _barbers.add(newBarber);
    return newBarber.id!;
  }

  Future<int> updateBarber(Barber barber) async {
    await initialize();
    final index = _barbers.indexWhere((b) => b.id == barber.id);
    if (index != -1) {
      _barbers[index] = barber.copyWith(updatedAt: DateTime.now());
      return 1;
    }
    return 0;
  }

  // Appointment operations
  Future<List<Appointment>> getAppointments() async {
    await initialize();
    return List.from(_appointments);
  }

  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async {
    await initialize();
    return _appointments
        .where((appointment) => 
            appointment.datetime.year == date.year &&
            appointment.datetime.month == date.month &&
            appointment.datetime.day == date.day)
        .toList()
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
  }

  Future<int> insertAppointment(Appointment appointment) async {
    await initialize();
    final newAppointment = appointment.copyWith(
      id: _nextAppointmentId++,
      createdAt: DateTime.now(),
    );
    _appointments.add(newAppointment);
    return newAppointment.id!;
  }

  Future<int> updateAppointment(Appointment appointment) async {
    await initialize();
    final index = _appointments.indexWhere((a) => a.id == appointment.id);
    if (index != -1) {
      _appointments[index] = appointment;
      return 1;
    }
    return 0;
  }

  Future<int> deleteAppointment(int id) async {
    await initialize();
    final index = _appointments.indexWhere((a) => a.id == id);
    if (index != -1) {
      _appointments.removeAt(index);
      return 1;
    }
    return 0;
  }

  // User operations
  Future<List<User>> getUsers() async {
    await initialize();
    return List.from(_users);
  }

  Future<User?> getUserById(int id) async {
    await initialize();
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    await initialize();
    try {
      return _users.firstWhere((user) => user.email.toLowerCase() == email.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  Future<int> insertUser(User user) async {
    await initialize();
    final newUser = user.copyWith(
      id: _nextUserId++,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _users.add(newUser);
    return newUser.id!;
  }

  Future<int> updateUser(User user) async {
    await initialize();
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user.copyWith(updatedAt: DateTime.now());
      return 1;
    }
    return 0;
  }

  Future<int> deleteUser(int id) async {
    await initialize();
    final index = _users.indexWhere((u) => u.id == id);
    if (index != -1) {
      _users.removeAt(index);
      return 1;
    }
    return 0;
  }

  // Clear all data (for testing)
  Future<void> clearAll() async {
    _customers.clear();
    _barbers.clear();
    _services.clear();
    _queueItems.clear();
    _appointments.clear();
    _users.clear();
    _nextCustomerId = 1;
    _nextBarberId = 1;
    _nextServiceId = 1;
    _nextQueueId = 1;
    _nextAppointmentId = 1;
    _nextUserId = 1;
    _initialized = false;
  }
}

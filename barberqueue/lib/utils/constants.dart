class AppConstants {
  // App Info
  static const String appName = 'BarberQueue';
  static const String appVersion = '1.0.0';
  
  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String queueRoute = '/queue';
  static const String addWalkinRoute = '/add-walkin';
  static const String appointmentsRoute = '/appointments';
  static const String addAppointmentRoute = '/add-appointment';
  static const String customersRoute = '/customers';
  static const String barbersRoute = '/barbers';
  static const String settingsRoute = '/settings';
  
  // Database
  static const String databaseName = 'barberqueue.db';
  static const int databaseVersion = 1;
  
  // Table Names
  static const String customersTable = 'customers';
  static const String barbersTable = 'barbers';
  static const String servicesTable = 'services';
  static const String appointmentsTable = 'appointments';
  static const String queueTable = 'queue';
  static const String syncLogTable = 'sync_log';
  
  // Queue Status
  static const String statusWaiting = 'Waiting';
  static const String statusStarted = 'Started';
  static const String statusCompleted = 'Completed';
  static const String statusCancelled = 'Cancelled';
  
  // Barber Status
  static const String barberAvailable = 'Available';
  static const String barberOnBreak = 'On Break';
  static const String barberBusy = 'Busy';
  
  // Default Services
  static const List<String> defaultServices = [
    'Haircut',
    'Beard Trim',
    'Shave',
    'Hair Wash',
    'Styling',
  ];
  
  // Sync Actions
  static const String syncCreated = 'created';
  static const String syncUpdated = 'updated';
  static const String syncDeleted = 'deleted';
  
  // Validation
  static final RegExp emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    caseSensitive: false,
    multiLine: false,
  );
  
  // Default password for demo accounts
  static const String defaultAdminPassword = 'admin123';
  static const String defaultBarberPassword = 'barber123';
  static const String defaultCustomerPassword = 'customer123';
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleBarber = 'barber';
  static const String roleCustomer = 'customer';
  
  // Barber Specializations
  static const List<String> barberSpecializations = [
    'Hair Stylist',
    'Beard Specialist',
    'Master Barber',
    'Color Specialist',
    'Stylist',
  ];
}

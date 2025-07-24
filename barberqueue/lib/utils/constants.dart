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
  static const String syncActionInsert = 'INSERT';
  static const String syncActionUpdate = 'UPDATE';
  static const String syncActionDelete = 'DELETE';
}

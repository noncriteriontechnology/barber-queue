import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/customer.dart';
import '../models/barber.dart';
import '../models/service.dart';
import '../models/queue_item.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create customers table
    await db.execute('''
      CREATE TABLE ${AppConstants.customersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        visits INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Create barbers table
    await db.execute('''
      CREATE TABLE ${AppConstants.barbersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Create services table
    await db.execute('''
      CREATE TABLE ${AppConstants.servicesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        duration INTEGER NOT NULL,
        price REAL,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Create appointments table
    await db.execute('''
      CREATE TABLE ${AppConstants.appointmentsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        service_id INTEGER NOT NULL,
        barber_id INTEGER,
        datetime TEXT NOT NULL,
        status TEXT DEFAULT 'Scheduled',
        notes TEXT,
        created_at TEXT,
        FOREIGN KEY (customer_id) REFERENCES ${AppConstants.customersTable} (id),
        FOREIGN KEY (service_id) REFERENCES ${AppConstants.servicesTable} (id),
        FOREIGN KEY (barber_id) REFERENCES ${AppConstants.barbersTable} (id)
      )
    ''');

    // Create queue table
    await db.execute('''
      CREATE TABLE ${AppConstants.queueTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        service_id INTEGER NOT NULL,
        barber_id INTEGER,
        status TEXT NOT NULL,
        notes TEXT,
        timestamp TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        FOREIGN KEY (customer_id) REFERENCES ${AppConstants.customersTable} (id),
        FOREIGN KEY (service_id) REFERENCES ${AppConstants.servicesTable} (id),
        FOREIGN KEY (barber_id) REFERENCES ${AppConstants.barbersTable} (id)
      )
    ''');

    // Create sync_log table
    await db.execute('''
      CREATE TABLE ${AppConstants.syncLogTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Insert default services
    for (String serviceName in AppConstants.defaultServices) {
      await db.insert(AppConstants.servicesTable, {
        'name': serviceName,
        'duration': 30, // Default 30 minutes
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // Insert default barber
    await db.insert(AppConstants.barbersTable, {
      'name': 'Main Barber',
      'status': AppConstants.barberAvailable,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Customer CRUD operations
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert(AppConstants.customersTable, customer.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.customersTable);
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.customersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      AppConstants.customersTable,
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.customersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Queue operations
  Future<int> insertQueueItem(QueueItem queueItem) async {
    final db = await database;
    return await db.insert(AppConstants.queueTable, queueItem.toMap());
  }

  Future<List<QueueItem>> getQueueItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.queueTable,
      where: 'status != ?',
      whereArgs: [AppConstants.statusCompleted],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => QueueItem.fromMap(maps[i]));
  }

  Future<int> updateQueueItem(QueueItem queueItem) async {
    final db = await database;
    return await db.update(
      AppConstants.queueTable,
      queueItem.toMap(),
      where: 'id = ?',
      whereArgs: [queueItem.id],
    );
  }

  // Service operations
  Future<List<Service>> getServices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.servicesTable);
    return List.generate(maps.length, (i) => Service.fromMap(maps[i]));
  }

  // Barber operations
  Future<List<Barber>> getBarbers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.barbersTable);
    return List.generate(maps.length, (i) => Barber.fromMap(maps[i]));
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

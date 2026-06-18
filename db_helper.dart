import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import '../models/bill.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smartpos_pro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        items_json TEXT NOT NULL
      )
    ''');

    // Seed default products to let the shopkeeper start testing immediately
    await db.insert('products', {'name': 'Mineral Water Slim', 'price': 50.0, 'stock': 120});
    await db.insert('products', {'name': 'Crispy Potato Chips', 'price': 80.0, 'stock': 75});
    await db.insert('products', {'name': 'Chocolate Fudge Bar', 'price': 150.0, 'stock': 40});
    await db.insert('products', {'name': 'Sparkling Orange Cola', 'price': 120.0, 'stock': 90});
  }

  // --- Products CRUD ---
  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Bills Operations ---
  // In a transaction, save the bill and decrement the stock for each item ordered
  Future<int> saveBill(Bill bill) async {
    final db = await instance.database;
    return await db.transaction<int>((txn) async {
      // 1. Insert search elements
      final billMap = bill.toMap();
      final billId = await txn.insert('bills', billMap);

      // 2. Decrement stock for each item ordered in the bill
      for (var item in bill.items) {
        // Query current product
        final List<Map<String, dynamic>> res = await txn.query(
          'products',
          where: 'name = ?',
          whereArgs: [item.productName],
        );

        if (res.isNotEmpty) {
          final product = Product.fromMap(res.first);
          final updatedStock = (product.stock - item.quantity).clamp(0, 999999);
          
          await txn.update(
            'products',
            {'stock': updatedStock},
            where: 'id = ?',
            whereArgs: [product.id],
          );
        }
      }

      return billId;
    });
  }

  Future<List<Bill>> getAllBills() async {
    final db = await instance.database;
    final result = await db.query('bills', orderBy: 'id DESC');
    return result.map((json) => Bill.fromMap(json)).toList();
  }

  // --- Backup Functions ---
  Future<String> exportDatabaseBackup() async {
    final dbPath = await getDatabasesPath();
    final currentDbFile = File(join(dbPath, 'smartpos_pro.db'));

    if (await currentDbFile.exists()) {
      // Get the external downloads or documents directory to save the file
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        // Fallback to application directory
        externalDir = await getApplicationDocumentsDirectory();
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = join(externalDir.path, 'SmartPOS_Backup_$timestamp.db');
      await currentDbFile.copy(backupPath);
      return backupPath;
    } else {
      throw Exception("Database file does not exist to export.");
    }
  }

  Future<void> importDatabaseBackup(String backupFilePath) async {
    final backupFile = File(backupFilePath);
    if (!await backupFile.exists()) {
      throw Exception("Specified backup file does not exist.");
    }

    // Close the current database connection first to avoid corruption
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final dbPath = await getDatabasesPath();
    final targetPath = join(dbPath, 'smartpos_pro.db');
    
    // Overwrite database
    await backupFile.copy(targetPath);
  }
}

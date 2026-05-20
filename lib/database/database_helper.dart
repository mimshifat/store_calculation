import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import '../models/customer.dart';
import '../models/khata.dart';
import '../models/transaction.dart';
import '../models/cash_entry.dart';
import '../models/supplier.dart';
import '../models/supplier_transaction.dart';
import '../models/bank_account.dart';
import '../models/bank_transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shukriya_store.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE khata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        pageNo TEXT,
        khataNo TEXT,
        suchiNo TEXT,
        mobile TEXT,
        address TEXT,
        dueAmount REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        paymentMethod TEXT DEFAULT 'Cash',
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cash_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        paymentMethod TEXT DEFAULT 'Cash'
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        companyName TEXT,
        mobile TEXT,
        dueAmount REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE supplier_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        paymentMethod TEXT DEFAULT 'Cash',
        FOREIGN KEY (supplierId) REFERENCES suppliers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE bank_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        accountNumber TEXT NOT NULL,
        balance REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE bank_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accountId INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (accountId) REFERENCES bank_accounts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE collection_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL UNIQUE,
        addedAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add dueAmount column safely for existing users
      try {
        await db.execute(
            'ALTER TABLE customers ADD COLUMN dueAmount REAL DEFAULT 0.0');
      } catch (_) {
        // Column might already exist, ignore
      }
    }
    
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customerId INTEGER NOT NULL,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT,
          date TEXT NOT NULL,
          FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE cash_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT,
          date TEXT NOT NULL
        )
      ''');
    }
    
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE suppliers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          companyName TEXT,
          mobile TEXT,
          dueAmount REAL DEFAULT 0.0
        )
      ''');

      await db.execute('''
        CREATE TABLE supplier_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplierId INTEGER NOT NULL,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT,
          date TEXT NOT NULL,
          FOREIGN KEY (supplierId) REFERENCES suppliers (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN paymentMethod TEXT DEFAULT "Cash"');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE cash_entries ADD COLUMN paymentMethod TEXT DEFAULT "Cash"');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE supplier_transactions ADD COLUMN paymentMethod TEXT DEFAULT "Cash"');
      } catch (_) {}
    }

    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE customers ADD COLUMN address TEXT');
      } catch (_) {}
    }
    
    if (oldVersion < 7) {
      try {
        await db.execute('''
          CREATE TABLE bank_accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            accountNumber TEXT NOT NULL,
            balance REAL DEFAULT 0.0
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE bank_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            accountId INTEGER NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            description TEXT,
            date TEXT NOT NULL,
            FOREIGN KEY (accountId) REFERENCES bank_accounts (id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 8) {
      try {
        await db.execute('''
          CREATE TABLE collection_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customerId INTEGER NOT NULL UNIQUE,
            addedAt TEXT NOT NULL,
            FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }
  }

  // --- Khata Operations ---

  Future<int> insertKhata(Khata khata) async {
    final db = await instance.database;
    return await db.insert('khata', khata.toMap());
  }

  Future<List<Khata>> getAllKhatas() async {
    final db = await instance.database;
    final result = await db.query('khata', orderBy: 'name ASC');
    return result.map((json) => Khata.fromMap(json)).toList();
  }

  Future<int> updateKhata(Khata khata) async {
    final db = await instance.database;
    return db.update(
      'khata',
      khata.toMap(),
      where: 'id = ?',
      whereArgs: [khata.id],
    );
  }

  Future<int> deleteKhata(int id) async {
    final db = await instance.database;
    return await db.delete(
      'khata',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Customer Operations ---

  Future<int> insertCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', orderBy: 'id DESC');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> updateDueAmount(int customerId, double amount) async {
    final db = await instance.database;
    return db.update(
      'customers',
      {'dueAmount': amount},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCustomerKhataName(
      String oldKhataName, String newKhataName) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      {'khataNo': newKhataName},
      where: 'khataNo = ?',
      whereArgs: [oldKhataName],
    );
  }

  // Batch insert for Excel import
  Future<void> insertCustomersBatch(List<Customer> customers) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var customer in customers) {
      batch.insert('customers', customer.toMap());
    }
    await batch.commit(noResult: true);
  }

  // Optional: insert Khatas in batch if needed
  Future<void> insertKhatasBatch(List<Khata> khatas) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var khata in khatas) {
      batch.insert('khata', khata.toMap());
    }
    await batch.commit(noResult: true);
  }

  // --- Transaction Operations ---

  Future<int> insertTransaction(AppTransaction transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<AppTransaction>> getTransactionsForCustomer(int customerId) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return result.map((json) => AppTransaction.fromMap(json)).toList();
  }

  Future<int> updateTransaction(AppTransaction transaction) async {
    final db = await instance.database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Cash Entry Operations ---

  Future<int> insertCashEntry(CashEntry entry) async {
    final db = await instance.database;
    return await db.insert('cash_entries', entry.toMap());
  }

  Future<List<CashEntry>> getAllCashEntries() async {
    final db = await instance.database;
    final result = await db.query('cash_entries', orderBy: 'date DESC');
    return result.map((json) => CashEntry.fromMap(json)).toList();
  }

  Future<int> updateCashEntry(CashEntry entry) async {
    final db = await instance.database;
    return db.update(
      'cash_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteCashEntry(int id) async {
    final db = await instance.database;
    return await db.delete(
      'cash_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Supplier Operations ---

  Future<int> insertSupplier(Supplier supplier) async {
    final db = await instance.database;
    return await db.insert('suppliers', supplier.toMap());
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await instance.database;
    final result = await db.query('suppliers', orderBy: 'id DESC');
    return result.map((json) => Supplier.fromMap(json)).toList();
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await instance.database;
    return db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> updateSupplierDueAmount(int supplierId, double amount) async {
    final db = await instance.database;
    return db.update(
      'suppliers',
      {'dueAmount': amount},
      where: 'id = ?',
      whereArgs: [supplierId],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await instance.database;
    return await db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Supplier Transaction Operations ---

  Future<int> insertSupplierTransaction(SupplierTransaction transaction) async {
    final db = await instance.database;
    return await db.insert('supplier_transactions', transaction.toMap());
  }

  Future<List<SupplierTransaction>> getTransactionsForSupplier(int supplierId) async {
    final db = await instance.database;
    final result = await db.query(
      'supplier_transactions',
      where: 'supplierId = ?',
      whereArgs: [supplierId],
      orderBy: 'date DESC',
    );
    return result.map((json) => SupplierTransaction.fromMap(json)).toList();
  }

  Future<int> updateSupplierTransaction(SupplierTransaction transaction) async {
    final db = await instance.database;
    return db.update(
      'supplier_transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteSupplierTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'supplier_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns the oldest 'sale' transaction date for each customer (customerId → date).
  /// Used to calculate how long a customer's due has been outstanding.
  Future<Map<int, DateTime>> getOldestSaleDatePerCustomer() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT customerId, MIN(date) as oldestDate
      FROM transactions
      WHERE type = 'sale'
      GROUP BY customerId
    ''');
    final Map<int, DateTime> map = {};
    for (var row in result) {
      map[row['customerId'] as int] = DateTime.parse(row['oldestDate'] as String);
    }
    return map;
  }

  /// Returns the oldest 'purchase' transaction date for each supplier (supplierId → date).
  /// Used to calculate how long a supplier's due has been outstanding.
  Future<Map<int, DateTime>> getOldestPurchaseDatePerSupplier() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT supplierId, MIN(date) as oldestDate
      FROM supplier_transactions
      WHERE type = 'purchase'
      GROUP BY supplierId
    ''');
    final Map<int, DateTime> map = {};
    for (var row in result) {
      map[row['supplierId'] as int] = DateTime.parse(row['oldestDate'] as String);
    }
    return map;
  }

  // --- Bank Account Operations ---

  Future<int> insertBankAccount(BankAccount account) async {
    final db = await instance.database;
    return await db.insert('bank_accounts', account.toMap());
  }

  Future<List<BankAccount>> getAllBankAccounts() async {
    final db = await instance.database;
    final result = await db.query('bank_accounts', orderBy: 'id DESC');
    return result.map((json) => BankAccount.fromMap(json)).toList();
  }

  Future<int> updateBankAccount(BankAccount account) async {
    final db = await instance.database;
    return db.update(
      'bank_accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> updateBankAccountBalance(int accountId, double balance) async {
    final db = await instance.database;
    return db.update(
      'bank_accounts',
      {'balance': balance},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<int> deleteBankAccount(int id) async {
    final db = await instance.database;
    return await db.delete(
      'bank_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Bank Transaction Operations ---

  Future<int> insertBankTransaction(BankTransaction transaction) async {
    final db = await instance.database;
    return await db.insert('bank_transactions', transaction.toMap());
  }

  Future<List<BankTransaction>> getTransactionsForAccount(int accountId) async {
    final db = await instance.database;
    final result = await db.query(
      'bank_transactions',
      where: 'accountId = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
    return result.map((json) => BankTransaction.fromMap(json)).toList();
  }
  
  Future<List<BankTransaction>> getAllBankTransactions() async {
    final db = await instance.database;
    final result = await db.query(
      'bank_transactions',
      orderBy: 'date DESC',
    );
    return result.map((json) => BankTransaction.fromMap(json)).toList();
  }

  Future<int> updateBankTransaction(BankTransaction transaction) async {
    final db = await instance.database;
    return db.update(
      'bank_transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteBankTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'bank_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Collection List Operations ---

  Future<int> addToCollectionList(int customerId) async {
    final db = await instance.database;
    return await db.insert(
      'collection_list',
      {
        'customerId': customerId,
        'addedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> removeFromCollectionList(int customerId) async {
    final db = await instance.database;
    return await db.delete(
      'collection_list',
      where: 'customerId = ?',
      whereArgs: [customerId],
    );
  }

  Future<List<int>> getCollectionListCustomerIds() async {
    final db = await instance.database;
    final result = await db.query('collection_list', orderBy: 'id DESC');
    return result.map((row) => row['customerId'] as int).toList();
  }

  Future<int> clearCollectionList() async {
    final db = await instance.database;
    return await db.delete('collection_list');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}


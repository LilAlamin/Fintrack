import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incremented version to force reset
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS wallets');
      await _createDB(db, newVersion);
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        icon_code INTEGER NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        wallet_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await _seedInitialData(db);
  }

  Future _seedInitialData(Database db) async {
    // The user requested that wallets start empty, so we do NOT seed wallets here.
    // They will manually add wallets in the Wallet app.

    // === Expense Categories ===
    await db.insert('categories', {'name': 'Food & Dining', 'icon_code': 0xe532, 'color': 0xFFFFB74D, 'type': 'EXPENSE'}); // restaurant
    await db.insert('categories', {'name': 'Entertainment', 'icon_code': 0xe406, 'color': 0xFFBA68C8, 'type': 'EXPENSE'}); // movie
    await db.insert('categories', {'name': 'Transportation', 'icon_code': 0xe1d5, 'color': 0xFF4FC3F7, 'type': 'EXPENSE'}); // directions_car
    await db.insert('categories', {'name': 'Bills & Utilities', 'icon_code': 0xe533, 'color': 0xFFE57373, 'type': 'EXPENSE'}); // receipt

    // === Income Categories ===
    await db.insert('categories', {'name': 'Salary', 'icon_code': 0xe041, 'color': 0xFF81C784, 'type': 'INCOME'}); // account_balance_wallet
    await db.insert('categories', {'name': 'Bonus', 'icon_code': 0xe11c, 'color': 0xFFFFD54F, 'type': 'INCOME'}); // card_giftcard
    await db.insert('categories', {'name': 'Freelance', 'icon_code': 0xe30a, 'color': 0xFF64B5F6, 'type': 'INCOME'}); // laptop_mac
  }

  // --- Wallets ---
  Future<List<Map<String, dynamic>>> getWallets() async {
    final db = await instance.database;
    return await db.query('wallets', orderBy: 'id ASC');
  }

  Future<double> getTotalBalance() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(balance) as total FROM wallets');
    double total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    return total;
  }

  Future<int> insertWallet(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('wallets', row);
  }

  Future<int> updateWallet(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('wallets', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteWallet(int id) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // Delete associated transactions first to prevent orphaned records/foreign key constraint failures
      await txn.delete('transactions', where: 'wallet_id = ?', whereArgs: [id]);
      
      // Then delete the wallet itself
      return await txn.delete('wallets', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- Categories ---
  Future<List<Map<String, dynamic>>> getCategories(String type) async {
    final db = await instance.database;
    return await db.query('categories', where: 'type = ?', whereArgs: [type], orderBy: 'id ASC');
  }

  Future<Map<String, dynamic>?> getCategoryById(int id) async {
    final db = await instance.database;
    final res = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> insertCategory(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('categories', row);
  }

  // --- Transactions ---
  Future<List<Map<String, dynamic>>> getTransactions({int? limit}) async {
    final db = await instance.database;
    
    final String query = '''
      SELECT 
        t.id, t.title, t.amount, t.type, t.date, t.notes,
        c.name as category_name, c.icon_code as category_icon, c.color as category_color,
        w.name as wallet_name, w.color as wallet_color
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      JOIN wallets w ON t.wallet_id = w.id
      ORDER BY t.id DESC
    ''' + (limit != null ? ' LIMIT $limit' : '');

    return await db.rawQuery(query);
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    
    int id = 0;
    await db.transaction((txn) async {
      id = await txn.insert('transactions', row);
      
      double amount = (row['amount'] as num).toDouble();
      int walletId = row['wallet_id'];
      String type = row['type'];
      
      final walletRes = await txn.query('wallets', columns: ['balance'], where: 'id = ?', whereArgs: [walletId]);
      if (walletRes.isNotEmpty) {
        double currentBalance = (walletRes.first['balance'] as num).toDouble();
        double newBalance = type == 'INCOME' ? currentBalance + amount : currentBalance - amount;
        
        await txn.update('wallets', {'balance': newBalance}, where: 'id = ?', whereArgs: [walletId]);
      }
    });
    
    return id;
  }

  // --- Statistic summaries ---
  Future<double> getTotalIncome() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT SUM(amount) as total FROM transactions WHERE type = 'INCOME'");
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalExpense() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT SUM(amount) as total FROM transactions WHERE type = 'EXPENSE'");
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // --- Statistics & Charts ---
  Future<List<Map<String, dynamic>>> getGroupedTransactions(String type) async {
    final db = await instance.database;
    // Group transactions by category type, sum the amounts, and join to get category details
    final String query = '''
      SELECT 
        c.name as category_name, 
        c.icon_code as icon_code, 
        c.color as color, 
        SUM(t.amount) as total_amount
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.type = ?
      GROUP BY t.category_id
      ORDER BY total_amount DESC
    ''';
    return await db.rawQuery(query, [type]);
  }
}

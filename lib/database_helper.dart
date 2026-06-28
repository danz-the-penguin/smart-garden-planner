import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:convert'; // REQUIRED: For utf8 encoding support
import 'package:crypto/crypto.dart'; // REQUIRED: For sha256 generation algorithms
import 'models/mango_tree.dart'; 

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_garden.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      // --- VERSION 45: SECURE PASSWORD HASHING BASELINE ---
      version: 45, 
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        List<String> tables = [
          'Users', 'Mango_Trees', 'Growth_Logs', 'Tasks', 'Pest_Issues', 
          'Treatment_Logs', 'Weather_Alerts', 'Weather_Logs', 'Resource_Usage', 
          'Harvest_Logs', 'Listings', 'Orders', 'Shipments', 'Messages', 'Reports'
        ];
        for (var table in tables) {
          await db.execute('DROP TABLE IF EXISTS $table');
        }
        await _createDB(db, newVersion);
      },
    );
  }

  // --- CRYPTOGRAPHIC UTILITY METHOD ---
  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert text string to byte array
    final digest = sha256.convert(bytes); // Run the SHA-256 cryptographic math hashing algorithm
    return digest.toString(); // Return as a clean hex-string signature row
  }

  Future _createDB(Database db, int version) async {
    // 🏗️ INFRASTRUCTURE
    await db.execute('CREATE TABLE Users (user_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, role TEXT NOT NULL, status TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE Mango_Trees (tree_id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, plot_name TEXT NOT NULL, planting_date TEXT NOT NULL, status TEXT NOT NULL, FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE)');
    await db.execute('CREATE TABLE Growth_Logs (log_id INTEGER PRIMARY KEY AUTOINCREMENT, tree_id INTEGER NOT NULL, height_cm REAL, trunk_diam_cm REAL, stage TEXT NOT NULL, log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (tree_id) REFERENCES Mango_Trees(tree_id) ON DELETE CASCADE)');
    
    // HEALTH LOGS
    await db.execute('CREATE TABLE Pest_Issues (issue_id INTEGER PRIMARY KEY AUTOINCREMENT, tree_id INTEGER NOT NULL, symptom TEXT NOT NULL, physical_description TEXT NOT NULL, diagnosis TEXT, report_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (tree_id) REFERENCES Mango_Trees(tree_id) ON DELETE CASCADE)');
    await db.execute('CREATE TABLE Treatment_Logs (treatment_id INTEGER PRIMARY KEY AUTOINCREMENT, issue_id INTEGER NOT NULL, treatment_name TEXT NOT NULL, date_applied TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (issue_id) REFERENCES Pest_Issues(issue_id) ON DELETE CASCADE)');
    
    // TASKS & WEATHER
    await db.execute('CREATE TABLE Tasks (task_id INTEGER PRIMARY KEY AUTOINCREMENT, tree_id INTEGER NOT NULL, fert_id INTEGER, title TEXT NOT NULL, task_type TEXT NOT NULL, schedule_dt TEXT NOT NULL, status TEXT NOT NULL, FOREIGN KEY (tree_id) REFERENCES Mango_Trees(tree_id) ON DELETE CASCADE)');
    await db.execute('CREATE TABLE Weather_Alerts (alert_id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, message TEXT NOT NULL, alert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (user_id) REFERENCES Users(user_id))');
    
    // WEATHER LOGS
    await db.execute('''CREATE TABLE Weather_Logs (
      weather_id INTEGER PRIMARY KEY AUTOINCREMENT, 
      forecast_date TEXT DEFAULT CURRENT_TIMESTAMP, 
      location TEXT, 
      temp_c REAL, 
      rain_mm REAL, 
      humidity_pct INTEGER, 
      raw_json TEXT
    )''');
    
    // RESOURCES & HARVEST
    await db.execute('CREATE TABLE Resource_Usage (usage_id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, tree_id INTEGER, resource_type TEXT NOT NULL, quantity REAL NOT NULL, log_date TEXT DEFAULT CURRENT_DATE, FOREIGN KEY (user_id) REFERENCES Users(user_id), FOREIGN KEY (tree_id) REFERENCES Mango_Trees(tree_id) ON DELETE SET NULL)');
    await db.execute('''CREATE TABLE Harvest_Logs (harvest_id INTEGER PRIMARY KEY AUTOINCREMENT, tree_id INTEGER NOT NULL, quantity_kg REAL NOT NULL, quality_grade TEXT, harvest_date TEXT DEFAULT CURRENT_DATE, status TEXT DEFAULT 'available', FOREIGN KEY (tree_id) REFERENCES Mango_Trees(tree_id) ON DELETE CASCADE)''');
    
    // COMMERCE
    await db.execute('''CREATE TABLE Listings (listing_id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, title TEXT NOT NULL, price REAL NOT NULL, weight_kg REAL, quality_grade TEXT, harvest_date TEXT, status TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (user_id) REFERENCES Users(user_id))''');
    await db.execute('CREATE TABLE Orders (order_id INTEGER PRIMARY KEY AUTOINCREMENT, listing_id INTEGER NOT NULL, buyer_id INTEGER NOT NULL, total_price REAL NOT NULL, order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, status TEXT DEFAULT "Processing", FOREIGN KEY (listing_id) REFERENCES Listings(listing_id), FOREIGN KEY (buyer_id) REFERENCES Users(user_id))');
    await db.execute('CREATE TABLE Shipments (shipment_id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, tracking_number TEXT, shipment_date TEXT, FOREIGN KEY (order_id) REFERENCES Orders(order_id))');
    await db.execute('CREATE TABLE Messages (msg_id INTEGER PRIMARY KEY AUTOINCREMENT, sender_id INTEGER, receiver_id INTEGER, related_listing_id INTEGER, content TEXT, timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (sender_id) REFERENCES Users(user_id), FOREIGN KEY (receiver_id) REFERENCES Users(user_id))');
    await db.execute('CREATE TABLE Reports (report_id INTEGER PRIMARY KEY AUTOINCREMENT, reporter_id INTEGER NOT NULL, target_id INTEGER, report_type TEXT NOT NULL, content TEXT NOT NULL, status TEXT DEFAULT "Pending", timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');

    // 🌱 SEEDING: PRE-HASHED DUMMY ACCOUNTS TO ALIGN WITH VERSION 45 SECURITY CONSTRAINTS
    final String defaultHashedPassword = _hashPassword('1234');

    for (int i = 1; i <= 5; i++) {
      // Seed Farmers with secured password strings
      int fId = await db.insert('Users', {'name': 'Farmer Danz $i', 'email': 'farmer$i@test.com', 'password_hash': defaultHashedPassword, 'role': 'Farmer', 'status': 'Active'});
      
      // Seed Customers with secured password strings
      await db.insert('Users', {'name': 'Customer Mary $i', 'email': 'customer$i@test.com', 'password_hash': defaultHashedPassword, 'role': 'Customer', 'status': 'Active'});
      
      int treeId = await db.insert('Mango_Trees', {'user_id': fId, 'plot_name': 'Sabah Plot ${100+i}', 'planting_date': '2026-01-15', 'status': 'seedling'});
      await db.insert('Listings', {'user_id': fId, 'title': 'Harumanis Grade A - Pack $i', 'price': 45.0 + i, 'weight_kg': 5.0, 'quality_grade': 'A', 'harvest_date': '2026-05-01', 'status': 'Active'});
      await db.insert('Tasks', {'tree_id': treeId, 'title': 'Initial Soil & Root Assessment', 'task_type': 'Maintenance', 'schedule_dt': '2026-05-10', 'status': 'Pending'});
      await db.execute("INSERT INTO Weather_Logs (location, temp_c, rain_mm, humidity_pct) VALUES ('Kota Kinabalu', ${28.5 + i}, ${i * 1.5}, ${80 + i})");
    }
    await db.insert('Users', {'name': 'Admin User', 'email': 'admin@test.com', 'password_hash': defaultHashedPassword, 'role': 'Admin', 'status': 'Active'});
  }

  // --- 1. AUTH & GOVERNANCE ---
  
  Future<int> registerUser(String n, String e, String p, String r) async {
    final db = await database;
    
    final List<Map<String, dynamic>> structuralCheck = await db.query(
      'Users',
      where: 'email = ?',
      whereArgs: [e.toLowerCase().trim()],
    );

    if (structuralCheck.isNotEmpty) {
      return -1; // Collision detected
    }

    return await db.insert('Users', {
      'name': n,
      'email': e.toLowerCase().trim(),
      'password_hash': _hashPassword(p),
      'role': r,
      'status': 'Active'
    });
  }

  Future<Map<String, dynamic>?> loginUser(String e, String p) async { 
    final db = await database;
    final String encryptedInput = _hashPassword(p);

    final res = await db.query(
      'Users', 
      where: 'email = ? AND password_hash = ?', 
      whereArgs: [e.toLowerCase().trim(), encryptedInput]
    ); 
    return res.isNotEmpty ? res.first : null; 
  }

  // FIXED: Cleared erroneous trailing angle brackets and expression layout
  Future<List<Map<String, dynamic>>> queryAllUsers() async => (await database).query('Users', orderBy: 'name ASC');
  
  Future<int> deleteUser(int id) async => (await database).delete('Users', where: 'user_id = ?', whereArgs: [id]);
  
  Future<int> updateUserStatus(int id, String status) async {
    final db = await database;
    String normalizedStatus = status;
    if (status.toLowerCase() == 'suspension') normalizedStatus = 'Suspended';
    return await db.update('Users', {'status': normalizedStatus}, where: 'user_id = ?', whereArgs: [id]);
  }

  Future<int> adminUpdateUserFields(int targetUserId, String newName, String newEmail, String newPassword) async {
    final db = await database;
    final String sanitizedEmail = newEmail.toLowerCase().trim();

    final List<Map<String, dynamic>> emailCheck = await db.query(
      'Users',
      where: 'email = ? AND user_id != ?',
      whereArgs: [sanitizedEmail, targetUserId],
    );

    if (emailCheck.isNotEmpty) {
      return -1; 
    }

    final Map<String, dynamic> updateData = {
      'name': newName.trim(),
      'email': sanitizedEmail,
    };

    if (newPassword.trim().isNotEmpty) {
      updateData['password_hash'] = _hashPassword(newPassword);
    }

    return await db.update(
      'Users', 
      updateData, 
      where: 'user_id = ?', 
      whereArgs: [targetUserId]
    );
  }

  // --- 2. ORCHARD & GROWTH ---
  Future<int> insertTree(MangoTree tree, int userId) async {
    final db = await database;
    int treeId = await db.insert('Mango_Trees', tree.toMap()..['user_id'] = userId);
    await db.insert('Tasks', {'tree_id': treeId, 'title': 'Initial Soil & Root Assessment', 'task_type': 'Maintenance', 'schedule_dt': DateTime.now().add(const Duration(days: 1)).toString().split(' ')[0], 'status': 'Pending'});
    return treeId;
  }
  Future<List<Map<String, dynamic>>> queryTreesByUser(int userId) async => (await database).query('Mango_Trees', where: 'user_id = ?', whereArgs: [userId]);
  Future<int> deleteTree(int id) async => (await database).delete('Mango_Trees', where: 'tree_id = ?', whereArgs: [id]);
  Future<void> insertGrowthLogWithAutoStage(int treeId, double height, double diameter) async {
    final db = await database;
    String newStage = (diameter < 1.0) ? 'Seedling' : (diameter < 10.0) ? 'Vegetative' : (diameter < 20.0) ? 'Flowering' : 'Fruiting';
    await db.transaction((txn) async {
      await txn.insert('Growth_Logs', {'tree_id': treeId, 'height_cm': height, 'trunk_diam_cm': diameter, 'stage': newStage});
      await txn.update('Mango_Trees', {'status': newStage}, where: 'tree_id = ?', whereArgs: [treeId]);
    });
  }
  Future<int> deleteGrowthLog(int logId) async => (await database).delete('Growth_Logs', where: 'log_id = ?', whereArgs: [logId]);
  Future<List<Map<String, dynamic>>> queryLogsForTree(int id) async => (await database).query('Growth_Logs', where: 'tree_id = ?', whereArgs: [id], orderBy: 'log_date DESC');

  // --- 3. HEALTH ---
  Future<int> insertPestIssue(Map<String, dynamic> issue) async => (await database).insert('Pest_Issues', issue);
  Future<List<Map<String, dynamic>>> queryPestIssuesForTree(int id) async => (await database).query('Pest_Issues', where: 'tree_id = ?', whereArgs: [id], orderBy: 'report_date DESC');
  Future<List<Map<String, dynamic>>> querySickTrees() async => (await database).rawQuery('SELECT t.tree_id, t.plot_name, p.issue_id, p.symptom, p.physical_description FROM Mango_Trees t JOIN Pest_Issues p ON t.tree_id = p.tree_id');
  Future<int> querySickTreesCount() async => Sqflite.firstIntValue(await (await database).rawQuery('SELECT COUNT(DISTINCT tree_id) FROM Pest_Issues')) ?? 0;
  Future<int> querySickTreesCountByUser(int userId) async {
    final res = await (await database).rawQuery('SELECT COUNT(DISTINCT p.tree_id) FROM Pest_Issues p JOIN Mango_Trees m ON p.tree_id = m.tree_id WHERE m.user_id = ?', [userId]);
    return Sqflite.firstIntValue(res) ?? 0;
  }
  Future<int> insertTreatment(Map<String, dynamic> t) async => (await database).insert('Treatment_Logs', t);
  Future<List<Map<String, dynamic>>> queryTreatmentsForIssue(int id) async => (await database).query('Treatment_Logs', where: 'issue_id = ?', whereArgs: [id], orderBy: 'date_applied DESC');

  // --- 4. WEATHER & TASKS ---
  Future<int> insertWeatherLog(Map<String, dynamic> log) async => (await database).insert('Weather_Logs', log);
  Future<List<Map<String, dynamic>>> queryWeatherLogs() async => (await database).query('Weather_Logs', orderBy: 'forecast_date DESC', limit: 10);
  Future<int> insertWeatherAlert(String m, int userId) async => (await database).insert('Weather_Alerts', {'user_id': userId, 'message': m});
  Future<List<Map<String, dynamic>>> queryAllAlerts() async => (await database).query('Weather_Alerts', orderBy: 'alert_date DESC');
  Future<List<Map<String, dynamic>>> queryPendingTasksByUser(int userId) async => (await database).rawQuery('SELECT t.* FROM Tasks t JOIN Mango_Trees m ON t.tree_id = m.tree_id WHERE m.user_id = ? AND t.status = "Pending"', [userId]);
  Future<int> completeTask(int id) async => (await database).update('Tasks', {'status': 'Completed'}, where: 'task_id = ?', whereArgs: [id]);

  // --- 5. ECO & ANALYTICS ---
  Future<int> logEcoResource(int userId, int? treeId, String type, double qty) async => (await database).insert('Resource_Usage', {'user_id': userId, 'tree_id': treeId, 'resource_type': type, 'quantity': qty});
  Future<List<Map<String, dynamic>>> queryResourceSummary(int userId) async => (await database).rawQuery('SELECT resource_type, SUM(quantity) as total FROM Resource_Usage WHERE user_id = ? GROUP BY resource_type', [userId]);
  List<String> generateEcoTips(String type, double qty) => (qty > 500) ? ["High usage detected. Optimize irrigation."] : ["Resource usage stable."];

  // --- 6. HARVEST & MARKETPLACE ---
  Future<int> insertHarvest(Map<String, dynamic> h) async => (await database).insert('Harvest_Logs', h);
  Future<List<Map<String, dynamic>>> queryHarvestForTree(int id) async => (await database).query('Harvest_Logs', where: 'tree_id = ?', whereArgs: [id], orderBy: 'harvest_date DESC');
  Future<double> queryTotalYieldByUser(int userId) async {
    final res = await (await database).rawQuery('SELECT SUM(h.quantity_kg) as total FROM Harvest_Logs h JOIN Mango_Trees m ON h.tree_id = m.tree_id WHERE m.user_id = ?', [userId]);
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }
  Future<void> listHarvest(Map<String, dynamic> l, int hId, int uId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('Listings', {...l, 'user_id': uId, 'status': 'Active'});
      await txn.update('Harvest_Logs', {'status': 'Listed'}, where: 'harvest_id = ?', whereArgs: [hId]);
    });
  }
  Future<int> insertListing(Map<String, dynamic> l, int userId) async => (await database).insert('Listings', {...l, 'user_id': userId, 'status': 'Active'});
  Future<int> updateListing(int id, String title, double price) async => (await database).update('Listings', {'title': title, 'price': price}, where: 'listing_id = ?', whereArgs: [id]);
  Future<int> deleteListing(int id) async => (await database).delete('Listings', where: 'listing_id = ?', whereArgs: [id]);
  Future<List<Map<String, dynamic>>> queryMyListings(int userId) async => (await database).query('Listings', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
  Future<int> queryListingsCount() async => Sqflite.firstIntValue(await (await database).rawQuery('SELECT COUNT(*) FROM Listings WHERE status = "Active"')) ?? 0;
  Future<List<Map<String, dynamic>>> queryAllListings() async {
    return await (await database).rawQuery('SELECT l.*, u.name as farmer_name FROM Listings l JOIN Users u ON l.user_id = u.user_id ORDER BY l.created_at DESC');
  }

  Future<List<Map<String, dynamic>>> queryMarketplace() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT l.*, u.name as farmer_name 
      FROM Listings l 
      JOIN Users u ON l.user_id = u.user_id 
      WHERE l.status = 'Active' 
      AND u.status = 'Active' 
      ORDER BY l.created_at DESC
    ''');
  }

  // --- 7. TRANSACTIONS & SHIPPING ---
  Future<int> placeOrder(int lId, double p, int bId) async {
    final db = await database;
    await db.insert('Orders', {'listing_id': lId, 'buyer_id': bId, 'total_price': p});
    return await db.update('Listings', {'status': 'Sold'}, where: 'listing_id = ?', whereArgs: [lId]);
  }
  Future<List<Map<String, dynamic>>> queryMyOrders(int bId) async => (await database).rawQuery('SELECT o.*, l.title, u.name as seller_name FROM Orders o JOIN Listings l ON o.listing_id = l.listing_id JOIN Users u ON l.user_id = u.user_id WHERE o.buyer_id = ?', [bId]);
  Future<List<Map<String, dynamic>>> querySalesByFarmer(int fId) async => (await database).rawQuery('SELECT o.*, l.title, u.name as buyer_name FROM Orders o JOIN Listings l ON o.listing_id = l.listing_id LEFT JOIN Users u ON o.buyer_id = u.user_id WHERE l.user_id = ? ORDER BY o.order_date DESC', [fId]);
  Future<int> deleteOrder(int id) async => (await database).delete('Orders', where: 'order_id = ?', whereArgs: [id]);
  Future<int> updateOrderStatus(int id, String status) async => (await database).update('Orders', {'status': status}, where: 'order_id = ?', whereArgs: [id]);
  Future<int> shipOrder(int id) async => updateOrderStatus(id, 'Shipped');
  Future<double> queryTotalRevenue() async { final res = await (await database).rawQuery('SELECT SUM(total_price) as total FROM Orders'); return (res.first['total'] as num?)?.toDouble() ?? 0.0; }
  Future<List<Map<String, dynamic>>> queryAllSales() async {
    return await (await database).rawQuery('SELECT o.*, l.title, b.name as buyer_name, f.name as farmer_name FROM Orders o JOIN Listings l ON o.listing_id = l.listing_id JOIN Users b ON o.buyer_id = b.user_id JOIN Users f ON l.user_id = f.user_id ORDER BY o.order_date DESC');
  }

  // --- 8. REPORTS & MESSAGING ---
  Future<int> insertReport(int rId, int tId, String typ, String c) async => (await database).insert('Reports', {'reporter_id': rId, 'target_id': tId, 'report_type': typ, 'content': c});
  Future<List<Map<String, dynamic>>> queryAllReports() async {
    return await (await database).rawQuery('SELECT r.*, u.name as reporter_name FROM Reports r JOIN Users u ON r.reporter_id = u.user_id ORDER BY r.timestamp DESC');
  }
  Future<int> sendMessage(int sId, int rId, int lId, String t) async => (await database).insert('Messages', {'sender_id': sId, 'receiver_id': rId, 'related_listing_id': lId, 'content': t});
  Future<List<Map<String, dynamic>>> queryUserInbox(int uId) async => (await database).rawQuery('SELECT m.*, u.name as contact_name, l.title as listing_title FROM Messages m JOIN Listings l ON m.related_listing_id = l.listing_id JOIN Users u ON (CASE WHEN m.sender_id = ? THEN m.receiver_id = u.user_id ELSE m.sender_id = u.user_id END) WHERE m.sender_id = ? OR m.receiver_id = ? GROUP BY m.related_listing_id ORDER BY m.timestamp DESC', [uId, uId, uId]);
  Future<List<Map<String, dynamic>>> queryChatThread(int uId, int cId, int lId) async => (await database).rawQuery('SELECT m.*, u.name as sender_name FROM Messages m JOIN Users u ON m.sender_id = u.user_id WHERE ((sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)) AND related_listing_id = ? ORDER BY timestamp ASC', [uId, cId, cId, uId, lId]);

  // --- 9. PERFORMANCE CORRELATION ---
  Future<Map<String, List<double>>> queryCorrelationData(int userId) async {
    final db = await database;
    final yieldsRaw = await db.rawQuery('SELECT SUM(quantity_kg) as qty FROM Harvest_Logs h JOIN Mango_Trees m ON h.tree_id = m.tree_id WHERE m.user_id = ? GROUP BY harvest_date LIMIT 5', [userId]);
    final fertRaw = await db.rawQuery('SELECT SUM(quantity) as qty FROM Resource_Usage WHERE user_id = ? AND resource_type = "Fertilizer" GROUP BY log_date LIMIT 5', [userId]);
    return {
      'yields': yieldsRaw.isEmpty ? [0.0] : yieldsRaw.map((e) => (e['qty'] as num).toDouble()).toList(),
      'fert': fertRaw.isEmpty ? [0.0] : fertRaw.map((e) => (e['qty'] as num).toDouble()).toList()
    };
  }

  Future close() async => (await database).close();
}

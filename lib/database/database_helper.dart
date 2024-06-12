
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// LocalDatabase class
class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  Database? _database;

  factory LocalDatabase() {
    return _instance;
  }

  LocalDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'local_database.db');

    return await openDatabase(
      path,
      version: 2, // Change the version number when altering the schema
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE pending_invoices('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'ticket TEXT, '
          'amount INTEGER, '
          'reference TEXT, '
          'userId TEXT, '
          'date_sold TEXT, '
          'token TEXT, ' // Add the token column
          'is_synced INTEGER DEFAULT 0' // Add the is_synced column with a default value
          ')',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute('ALTER TABLE pending_invoices ADD COLUMN token TEXT');
          db.execute('ALTER TABLE pending_invoices ADD COLUMN is_synced INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future<int> getInvoiceCount() async {
    final Database db = await _initDatabase();
    final int? count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM pending_invoices'),
    );
    return count ?? 0;
  }

  Future<void> insertInvoice(Map<String, dynamic> invoice) async {
    final db = await database;
    await db.insert('pending_invoices', invoice);

    print('Facture enregistrée localement: $invoice'); // Imprime le message chaque fois qu'une facture est enregistrée
  }

  Future<List<Map<String, dynamic>>> getPendingInvoices() async {
    final db = await database;
    return await db.query('pending_invoices');
  }

  Future<void> deleteInvoice(int id) async {
    final db = await database;
    await db.delete('pending_invoices', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateInvoiceAsSynced(int id) async {
    final db = await database;
    await db.update(
      'pending_invoices',
      {'is_synced': 1}, // Mettre à jour l'état de synchronisation à 1 pour marquer comme synchronisé
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> printAllInvoices() async {
    final invoices = await getPendingInvoices();
    invoices.forEach((invoice) {
      print('Facture locale: $invoice');
    });
  }

  Future<void> deleteAllInvoices() async {
    final Database db = await database;
    await db.delete('pending_invoices');
  }
}

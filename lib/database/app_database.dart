import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Tabel Produk Kasir PrekDuaDara
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get price => integer()();
  TextColumn get category => text()();
}

@DriftDatabase(tables: [Products])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase();

  @override
  int get schemaVersion => 1;

  // Query Tambah Produk
  Future<int> addProduct(ProductsCompanion entry) =>
      into(products).insert(entry);

  // Query Ambil Semua Produk
  Future<List<Product>> getAllProducts() => select(products).get();

  // Inisialisasi awal produk jika belum ada data (seeding offline)
  Future<void> seedInitialData() async {
    final existing = await getAllProducts();
    if (existing.isEmpty) {
      await addProduct(
        const ProductsCompanion(
          name: Value('Ayam Geprek Bakar + Es Teh'),
          price: Value(18000),
          category: Value('Geprek Bakar'),
        ),
      );
      await addProduct(
        const ProductsCompanion(
          name: Value('Ayam Geprek Biasa + Es Teh'),
          price: Value(17000),
          category: Value('Geprek Biasa'),
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}


/// Service singleton untuk menyimpan state keranjang / pesanan aktif
/// agar tidak hilang saat kasir berpindah halaman melalui AppDrawer atau navigasi lainnya.
class OrderStateService {
  static final OrderStateService _instance = OrderStateService._internal();
  factory OrderStateService() => _instance;
  OrderStateService._internal();

  /// Jumlah pesanan per menu (misal: {'Ayam Geprek Bakar + Es Teh': 2})
  static final Map<String, int> _itemCounts = {};

  /// Pilihan sambal per porsi untuk tiap menu (misal: {'Ayam Geprek Bakar + Es Teh': ['Sambal Bawang', 'Sambal Matah']})
  static final Map<String, List<String?>> _sambalChoices = {};

  static Map<String, int> get itemCounts => Map.unmodifiable(_itemCounts);

  static int getItemCount(String name) => _itemCounts[name] ?? 0;

  static void setItemCount(String name, int count) {
    if (count <= 0) {
      _itemCounts.remove(name);
      _sambalChoices.remove(name);
    } else {
      _itemCounts[name] = count;
      final currentList = _sambalChoices[name];
      if (currentList != null && currentList.length > count) {
        _sambalChoices[name] = currentList.sublist(0, count);
      }
    }
  }

  static void addItem(String name) {
    _itemCounts[name] = (_itemCounts[name] ?? 0) + 1;
  }

  static void removeItem(String name) {
    final current = _itemCounts[name] ?? 0;
    if (current > 1) {
      _itemCounts[name] = current - 1;
      final currentList = _sambalChoices[name];
      if (currentList != null && currentList.length > current - 1) {
        _sambalChoices[name] = currentList.sublist(0, current - 1);
      }
    } else {
      _itemCounts.remove(name);
      _sambalChoices.remove(name);
    }
  }

  static void setSambalChoices(String name, List<String?> choices) {
    _sambalChoices[name] = List<String?>.from(choices);
  }

  static List<String?>? getSambalChoices(String name) {
    final list = _sambalChoices[name];
    if (list != null) {
      return List<String?>.from(list);
    }
    return null;
  }

  static bool get hasActiveOrder => _itemCounts.values.any((c) => c > 0);

  static int get totalItemCount =>
      _itemCounts.values.fold(0, (sum, count) => sum + count);

  static void clearOrder() {
    _itemCounts.clear();
    _sambalChoices.clear();
  }
}

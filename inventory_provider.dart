import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/inventory_model.dart';
import 'client_provider.dart';
import 'appointment_provider.dart';

final inventoryProvider = FutureProvider<List<InventoryModel>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getInventory();
});

final lowStockInventoryProvider =
    FutureProvider<List<InventoryModel>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getInventory(lowStockOnly: true);
});

// Nuevo provider para productos que están por expirar
final expiringInventoryProvider =
    FutureProvider<List<InventoryModel>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getInventory(expiringOnly: true);
});

// Nuevo provider para productos por categoría
final inventoryByCategoryProvider =
    FutureProviderFamily<List<InventoryModel>, String>((ref, category) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getInventoryByCategory(category);
});

// Nuevo provider para productos por tipo de tratamiento
final inventoryByTreatmentTypeProvider =
    FutureProviderFamily<List<InventoryModel>, String>(
        (ref, treatmentType) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getInventoryByTreatmentType(treatmentType);
});

class InventoryNotifier
    extends StateNotifier<AsyncValue<List<InventoryModel>>> {
  final DatabaseService _dbService;
  final NotificationService _notificationService;
  bool _lowStockOnly = false;
  bool _expiringOnly = false;
  String? _categoryFilter;
  String? _treatmentTypeFilter;

  InventoryNotifier(this._dbService, this._notificationService)
      : super(const AsyncValue.loading()) {
    loadInventory();
  }

  Future<void> loadInventory() async {
    state = const AsyncValue.loading();
    try {
      List<InventoryModel> inventory;

      if (_categoryFilter != null) {
        inventory = await _dbService.getInventoryByCategory(_categoryFilter!);
      } else if (_treatmentTypeFilter != null) {
        inventory =
            await _dbService.getInventoryByTreatmentType(_treatmentTypeFilter!);
      } else {
        inventory = await _dbService.getInventory(
          lowStockOnly: _lowStockOnly,
          expiringOnly: _expiringOnly,
        );
      }

      state = AsyncValue.data(inventory);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void setLowStockFilter(bool lowStockOnly) {
    _lowStockOnly = lowStockOnly;
    _expiringOnly = false;
    _categoryFilter = null;
    _treatmentTypeFilter = null;
    loadInventory();
  }

  void setExpiringFilter(bool expiringOnly) {
    _expiringOnly = expiringOnly;
    _lowStockOnly = false;
    _categoryFilter = null;
    _treatmentTypeFilter = null;
    loadInventory();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    _lowStockOnly = false;
    _expiringOnly = false;
    _treatmentTypeFilter = null;
    loadInventory();
  }

  void setTreatmentTypeFilter(String? treatmentType) {
    _treatmentTypeFilter = treatmentType;
    _lowStockOnly = false;
    _expiringOnly = false;
    _categoryFilter = null;
    loadInventory();
  }

  void clearFilters() {
    _lowStockOnly = false;
    _expiringOnly = false;
    _categoryFilter = null;
    _treatmentTypeFilter = null;
    loadInventory();
  }

  Future<void> updateQuantity(String id, int newQuantity) async {
    try {
      await _dbService.updateInventoryQuantity(id, newQuantity);

      // Verificar si es necesario mostrar alerta de stock bajo
      final inventory = state.value ?? [];
      final item = inventory.firstWhere((i) => i.id == id);

      if (newQuantity <= item.minimumQuantity && newQuantity < item.quantity) {
        await _notificationService.showLowStockNotification(
            item.name, newQuantity);
      }

      loadInventory();
    } catch (e) {
      throw e;
    }
  }

  Future<String> addInventoryItem(InventoryModel item) async {
    try {
      final id = await _dbService.addInventoryItem(item);
      loadInventory();
      return id;
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateInventoryItem(InventoryModel item) async {
    try {
      await _dbService.updateInventoryItem(item);
      loadInventory();
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    try {
      await _dbService.deleteInventoryItem(id);
      loadInventory();
    } catch (e) {
      throw e;
    }
  }

  Future<void> addStock(String id, int amount) async {
    try {
      final inventory = state.value ?? [];
      final item = inventory.firstWhere((i) => i.id == id);

      // Crear ítem actualizado
      final updatedItem = item.addStock(amount);

      await _dbService.updateInventoryItem(updatedItem);
      loadInventory();
    } catch (e) {
      throw e;
    }
  }

  Future<void> reduceStock(String id, int amount) async {
    try {
      final inventory = state.value ?? [];
      final item = inventory.firstWhere((i) => i.id == id);

      // Verificar si hay suficiente stock
      if (amount > item.quantity) {
        throw Exception('No hay suficiente stock disponible');
      }

      // Crear ítem actualizado
      final updatedItem = item.reduceStock(amount);

      await _dbService.updateInventoryItem(updatedItem);

      // Verificar si es necesario mostrar alerta de stock bajo
      if (updatedItem.isLowStock) {
        await _notificationService.showLowStockNotification(
            updatedItem.name, updatedItem.quantity);
      }

      loadInventory();
    } catch (e) {
      throw e;
    }
  }

  // Método para reducir automáticamente el stock basado en un tratamiento
  Future<void> reduceStockForTreatment(String treatmentName) async {
    try {
      final inventory = state.value ?? [];

      // Filtrar productos que se usan en este tratamiento
      final relatedProducts = inventory
          .where((item) =>
              item.usedInTreatments != null &&
              item.usedInTreatments!.contains(treatmentName) &&
              item.usagePerTreatment != null &&
              item.usagePerTreatment! > 0)
          .toList();

      // Reducir el stock para cada producto
      for (var product in relatedProducts) {
        try {
          if (product.quantity >= product.usagePerTreatment!) {
            await reduceStock(product.id, product.usagePerTreatment!);
          } else {
            // Notificar que no hay suficiente producto
            await _notificationService
                .showInsufficientStockForTreatmentNotification(
                    product.name, treatmentName);
          }
        } catch (e) {
          // Capturar error individual sin detener el proceso
          print('Error reduciendo stock para ${product.name}: $e');
        }
      }

      loadInventory();
    } catch (e) {
      throw e;
    }
  }
}

final inventoryNotifierProvider =
    StateNotifierProvider<InventoryNotifier, AsyncValue<List<InventoryModel>>>(
        (ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return InventoryNotifier(dbService, notificationService);
});

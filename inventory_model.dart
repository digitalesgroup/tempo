import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  final String id;
  final String name;
  final String brand;
  final String category;
  final int quantity;
  final int minimumQuantity;
  final double costPrice;
  final double retailPrice;
  final String? barcode;
  final DateTime? expiryDate;
  final DateTime lastRestockDate;
  final String notes;
  final String? imageUrl;

  // Nuevos campos específicos para spa
  final String? treatmentType; // Facial, Corporal, Bronceado
  final List<String>? compatibleSkinTypes; // Para productos faciales
  final bool forSale; // Si es para uso en tratamientos o también para venta
  final List<String>? usedInTreatments; // Lista de tratamientos donde se usa
  final int? usagePerTreatment; // Cantidad aproximada usada por tratamiento

  InventoryModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.quantity,
    this.minimumQuantity = 5,
    required this.costPrice,
    required this.retailPrice,
    this.barcode,
    this.expiryDate,
    required this.lastRestockDate,
    this.notes = '',
    this.imageUrl,
    this.treatmentType,
    this.compatibleSkinTypes,
    this.forSale = true,
    this.usedInTreatments,
    this.usagePerTreatment,
  });

  factory InventoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? 0,
      minimumQuantity: data['minimumQuantity'] ?? 5,
      costPrice: (data['costPrice'] ?? 0).toDouble(),
      retailPrice: (data['retailPrice'] ?? 0).toDouble(),
      barcode: data['barcode'],
      expiryDate: data['expiryDate'] != null
          ? (data['expiryDate'] as Timestamp).toDate()
          : null,
      lastRestockDate: data['lastRestockDate'] != null
          ? (data['lastRestockDate'] as Timestamp).toDate()
          : DateTime.now(),
      notes: data['notes'] ?? '',
      imageUrl: data['imageUrl'],
      treatmentType: data['treatmentType'],
      compatibleSkinTypes: data['compatibleSkinTypes'] != null
          ? List<String>.from(data['compatibleSkinTypes'])
          : null,
      forSale: data['forSale'] ?? true,
      usedInTreatments: data['usedInTreatments'] != null
          ? List<String>.from(data['usedInTreatments'])
          : null,
      usagePerTreatment: data['usagePerTreatment'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'quantity': quantity,
      'minimumQuantity': minimumQuantity,
      'costPrice': costPrice,
      'retailPrice': retailPrice,
      'barcode': barcode,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'lastRestockDate': Timestamp.fromDate(lastRestockDate),
      'notes': notes,
      'imageUrl': imageUrl,
      'treatmentType': treatmentType,
      'compatibleSkinTypes': compatibleSkinTypes,
      'forSale': forSale,
      'usedInTreatments': usedInTreatments,
      'usagePerTreatment': usagePerTreatment,
    };
  }

  bool get isLowStock => quantity <= minimumQuantity;

  double get profit => retailPrice - costPrice;

  double get profitMargin => costPrice > 0 ? (profit / retailPrice) * 100 : 0;

  // Método para añadir stock
  InventoryModel addStock(int amount) {
    return copyWith(
      quantity: quantity + amount,
      lastRestockDate: DateTime.now(),
    );
  }

  // Método para reducir stock
  InventoryModel reduceStock(int amount) {
    if (amount > quantity) {
      throw Exception('No hay suficiente stock');
    }
    return copyWith(
      quantity: quantity - amount,
    );
  }

  // Método para calcular cuando se agotará el producto basado en uso
  int? estimatedDaysUntilStockout() {
    if (usagePerTreatment == null || usagePerTreatment == 0) {
      return null;
    }

    // Asumiendo un uso diario promedio
    final dailyUsage =
        usagePerTreatment! * 5; // Ejemplo: 5 tratamientos por día
    if (dailyUsage > 0) {
      return quantity ~/ dailyUsage; // División entera
    }
    return null;
  }

  InventoryModel copyWith({
    String? name,
    String? brand,
    String? category,
    int? quantity,
    int? minimumQuantity,
    double? costPrice,
    double? retailPrice,
    String? barcode,
    DateTime? expiryDate,
    DateTime? lastRestockDate,
    String? notes,
    String? imageUrl,
    String? treatmentType,
    List<String>? compatibleSkinTypes,
    bool? forSale,
    List<String>? usedInTreatments,
    int? usagePerTreatment,
  }) {
    return InventoryModel(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      costPrice: costPrice ?? this.costPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      barcode: barcode ?? this.barcode,
      expiryDate: expiryDate ?? this.expiryDate,
      lastRestockDate: lastRestockDate ?? this.lastRestockDate,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      treatmentType: treatmentType ?? this.treatmentType,
      compatibleSkinTypes: compatibleSkinTypes ?? this.compatibleSkinTypes,
      forSale: forSale ?? this.forSale,
      usedInTreatments: usedInTreatments ?? this.usedInTreatments,
      usagePerTreatment: usagePerTreatment ?? this.usagePerTreatment,
    );
  }
}

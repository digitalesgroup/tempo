// lib/models/treatment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TreatmentType {
  facial,
  body,
  tanning,
  massage,
  nails,
  hair,
  other,
}

class TreatmentModel {
  final String id;
  final String name;
  final String description;
  final TreatmentType type;
  final int duration; // en minutos
  final double price;
  final List<String> requiredProducts;
  final bool isActive;

  TreatmentModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.duration,
    required this.price,
    this.requiredProducts = const [],
    this.isActive = true,
  });

  factory TreatmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TreatmentModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: TreatmentType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => TreatmentType.other,
      ),
      duration: data['duration'] ?? 60,
      price: (data['price'] ?? 0).toDouble(),
      requiredProducts: List<String>.from(data['requiredProducts'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.toString(),
      'duration': duration,
      'price': price,
      'requiredProducts': requiredProducts,
      'isActive': isActive,
    };
  }

  // Cálculo del tiempo estimado en formato legible
  String get durationFormatted {
    final hours = duration ~/ 60;
    final minutes = duration % 60;

    if (hours > 0) {
      return '$hours h ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
}

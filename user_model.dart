// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  therapist,
  client,
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? photoUrl;
  final String? phone; // Nuevo campo de teléfono
  final DateTime createdAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl,
    this.phone, // Campo opcional
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == data['role'],
        orElse: () => UserRole.client,
      ),
      photoUrl: data['photoUrl'],
      phone: data['phone'], // Cargar el teléfono desde Firestore
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toString(),
      'photoUrl': photoUrl,
      'phone': phone, // Guardar el teléfono en Firestore
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? phone,
    bool? isActive,
    UserRole? role,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone, // Incluir el teléfono en el copyWith
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Para terapeutas, extendemos el modelo base
class TherapistModel extends UserModel {
  final String specialization;
  final List<String> services;
  final String schedule;

  TherapistModel({
    required super.id,
    required super.email,
    required super.name,
    super.photoUrl,
    super.phone, // Incluir el teléfono para terapeutas
    required super.createdAt,
    super.isActive,
    required this.specialization,
    required this.services,
    required this.schedule,
  }) : super(role: UserRole.therapist);

  factory TherapistModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TherapistModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      phone: data['phone'], // Cargar el teléfono
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      specialization: data['specialization'] ?? '',
      services: List<String>.from(data['services'] ?? []),
      schedule: data['schedule'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    final baseData = super.toFirestore();
    return {
      ...baseData,
      'specialization': specialization,
      'services': services,
      'schedule': schedule,
    };
  }

  TherapistModel copyWithTherapist({
    String? name,
    String? email,
    String? photoUrl,
    String? phone,
    String? specialization,
    List<String>? services,
    String? schedule,
    bool? isActive,
  }) {
    return TherapistModel(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone, // Incluir el teléfono
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      specialization: specialization ?? this.specialization,
      services: services ?? this.services,
      schedule: schedule ?? this.schedule,
    );
  }
}

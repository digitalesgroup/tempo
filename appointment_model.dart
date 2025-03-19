// lib/models/appointment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

class AppointmentModel {
  final String id;
  final String clientId;
  final String
      clientName; // Para mostrar en la UI sin necesidad de consultas adicionales
  final String therapistId;
  final String
      therapistName; // Para mostrar en la UI sin necesidad de consultas adicionales
  final String treatmentId;
  final String
      treatmentName; // Para mostrar en la UI sin necesidad de consultas adicionales
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentStatus status;
  final double price;
  final String notes;
  final bool isPaid;
  final String? paymentId; // Referencia a la transacción si está pagada

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.therapistId,
    required this.therapistName,
    required this.treatmentId,
    required this.treatmentName,
    required this.startTime,
    required this.endTime,
    this.status = AppointmentStatus.scheduled,
    required this.price,
    this.notes = '',
    this.isPaid = false,
    this.paymentId,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      therapistId: data['therapistId'] ?? '',
      therapistName: data['therapistName'] ?? '',
      treatmentId: data['treatmentId'] ?? '',
      treatmentName: data['treatmentName'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => AppointmentStatus.scheduled,
      ),
      price: (data['price'] ?? 0).toDouble(),
      notes: data['notes'] ?? '',
      isPaid: data['isPaid'] ?? false,
      paymentId: data['paymentId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'therapistId': therapistId,
      'therapistName': therapistName,
      'treatmentId': treatmentId,
      'treatmentName': treatmentName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status.toString(),
      'price': price,
      'notes': notes,
      'isPaid': isPaid,
      'paymentId': paymentId,
    };
  }

  AppointmentModel copyWith({
    String? clientId,
    String? clientName,
    String? therapistId,
    String? therapistName,
    String? treatmentId,
    String? treatmentName,
    DateTime? startTime,
    DateTime? endTime,
    AppointmentStatus? status,
    double? price,
    String? notes,
    bool? isPaid,
    String? paymentId,
    required String id,
  }) {
    return AppointmentModel(
      id: id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      therapistId: therapistId ?? this.therapistId,
      therapistName: therapistName ?? this.therapistName,
      treatmentId: treatmentId ?? this.treatmentId,
      treatmentName: treatmentName ?? this.treatmentName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      paymentId: paymentId ?? this.paymentId,
    );
  }

  // Método para verificar si dos citas se superponen
  bool overlaps(AppointmentModel other) {
    return (startTime.isBefore(other.endTime) &&
            endTime.isAfter(other.startTime)) ||
        (other.startTime.isBefore(endTime) && other.endTime.isAfter(startTime));
  }

  // Duración en minutos
  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }
}

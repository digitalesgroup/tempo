import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  payment,
  refund,
  productSale,
  expense,
  other,
}

enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  bankTransfer,
  mobilePayment,
  giftCard,
}

class TransactionModel {
  final String id;
  final String clientId;
  final String clientName; // Para UI sin consultas adicionales
  final List<String>
      appointmentIds; // Una transacción puede cubrir múltiples citas
  final TransactionType type;
  final PaymentMethod paymentMethod;
  final double amount;
  final double pendingAmount; // Para pagos parciales
  final DateTime date;
  final String notes;
  final String staffId;
  final String staffName; // Para UI

  TransactionModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.appointmentIds = const [],
    required this.type,
    required this.paymentMethod,
    required this.amount,
    this.pendingAmount = 0,
    required this.date,
    this.notes = '',
    required this.staffId,
    required this.staffName,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      appointmentIds: List<String>.from(data['appointmentIds'] ?? []),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => TransactionType.other,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == data['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      amount: (data['amount'] ?? 0).toDouble(),
      pendingAmount: (data['pendingAmount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] ?? '',
      staffId: data['staffId'] ?? '',
      staffName: data['staffName'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'appointmentIds': appointmentIds,
      'type': type.toString(),
      'paymentMethod': paymentMethod.toString(),
      'amount': amount,
      'pendingAmount': pendingAmount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'staffId': staffId,
      'staffName': staffName,
    };
  }

  // Método para verificar si hay saldo pendiente
  bool get hasPendingAmount => pendingAmount > 0;

  // Método para calcular el monto pagado
  double get paidAmount => amount - pendingAmount;
}

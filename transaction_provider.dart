// lib/providers/transaction_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/transaction_model.dart';
import 'client_provider.dart';
import '../models/appointment_model.dart';

final transactionsProvider =
    FutureProvider.family<List<TransactionModel>, Map<String, dynamic>>(
        (ref, params) async {
  final dbService = ref.watch(databaseServiceProvider);

  return await dbService.getTransactions(
    clientId: params['clientId'],
    startDate: params['startDate'],
    endDate: params['endDate'],
  );
});

final transactionsByClientProvider =
    FutureProvider.family<List<TransactionModel>, String>(
        (ref, clientId) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getTransactions(clientId: clientId);
});

class TransactionsNotifier
    extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final DatabaseService _dbService;
  String? _clientId;
  DateTime? _startDate;
  DateTime? _endDate;

  TransactionsNotifier(this._dbService) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = const AsyncValue.loading();
    try {
      final transactions = await _dbService.getTransactions(
        clientId: _clientId,
        startDate: _startDate,
        endDate: _endDate,
      );
      state = AsyncValue.data(transactions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void setFilters({String? clientId, DateTime? startDate, DateTime? endDate}) {
    _clientId = clientId;
    _startDate = startDate;
    _endDate = endDate;
    loadTransactions();
  }

  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      final id = await _dbService.addTransaction(transaction);
      loadTransactions();
      return id;
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _dbService.updateTransaction(transaction);
      loadTransactions();
    } catch (e) {
      throw e;
    }
  }

  // Para pagos parciales
  Future<void> registerPartialPayment(
      TransactionModel transaction, double paymentAmount) async {
    try {
      if (transaction.pendingAmount <= 0) {
        throw Exception('Esta transacción ya está completamente pagada');
      }

      if (paymentAmount > transaction.pendingAmount) {
        throw Exception('El monto de pago excede la cantidad pendiente');
      }

      // Calcular nuevo monto pendiente
      final newPendingAmount = transaction.pendingAmount - paymentAmount;

      // Actualizar transacción
      final updatedTransaction = TransactionModel(
        id: transaction.id,
        clientId: transaction.clientId,
        clientName: transaction.clientName,
        appointmentIds: transaction.appointmentIds,
        type: transaction.type,
        paymentMethod: transaction.paymentMethod,
        amount: transaction.amount,
        pendingAmount: newPendingAmount,
        date: transaction.date,
        notes: transaction.notes,
        staffId: transaction.staffId,
        staffName: transaction.staffName,
      );

      await _dbService.updateTransaction(updatedTransaction);

      // Si se ha pagado completamente, actualizar el estado de las citas
      if (newPendingAmount <= 0 && transaction.appointmentIds.isNotEmpty) {
        for (final appointmentId in transaction.appointmentIds) {
          await _dbService.updateAppointment(
            AppointmentModel(
              id: appointmentId,
              clientId: '', // Estos campos se rellenarán en la capa de servicio
              clientName: '',
              therapistId: '',
              therapistName: '',
              treatmentId: '',
              treatmentName: '',
              startTime:
                  DateTime.now(), // Datos temporales que serán reemplazados
              endTime: DateTime.now(),
              price: 0,
              isPaid: true,
              paymentId: transaction.id,
            ),
          );
        }
      }

      loadTransactions();
    } catch (e) {
      throw e;
    }
  }
}

final transactionsNotifierProvider = StateNotifierProvider<TransactionsNotifier,
    AsyncValue<List<TransactionModel>>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return TransactionsNotifier(dbService);
});

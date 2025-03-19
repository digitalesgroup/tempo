// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/client_model.dart';
import '../models/appointment_model.dart';
import '../models/treatment_model.dart';
import '../models/transaction_model.dart';
import '../models/inventory_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // USUARIOS
  Future<List<UserModel>> getUsers({UserRole? role}) async {
    try {
      QuerySnapshot snapshot;
      if (role != null) {
        snapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: role.toString())
            .get();
      } else {
        snapshot = await _firestore.collection('users').get();
      }

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error en getUsers: $e');
      throw e;
    }
  }

  Future<UserModel?> getUser(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error en getUser: $e');
      throw e;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toFirestore());

      // Actualizar también en la colección específica
      String collectionName;
      switch (user.role) {
        case UserRole.admin:
          collectionName = 'administrators';
          break;
        case UserRole.therapist:
          collectionName = 'therapists';
          break;
        case UserRole.client:
        default:
          collectionName = 'clients';
          break;
      }

      await _firestore
          .collection(collectionName)
          .doc(user.id)
          .update(user.toFirestore());
    } catch (e) {
      print('Error en updateUser: $e');
      throw e;
    }
  }

  Future<void> deleteUser(String id, UserRole role) async {
    try {
      // Eliminar de la colección general
      await _firestore.collection('users').doc(id).delete();

      // Eliminar de la colección específica
      String collectionName;
      switch (role) {
        case UserRole.admin:
          collectionName = 'administrators';
          break;
        case UserRole.therapist:
          collectionName = 'therapists';
          break;
        case UserRole.client:
        default:
          collectionName = 'clients';
          // Para clientes, también eliminar detalles
          await _firestore.collection('client_details').doc(id).delete();
          break;
      }

      await _firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      print('Error en deleteUser: $e');
      throw e;
    }
  }

  // TERAPEUTAS
  Future<List<TherapistModel>> getTherapists() async {
    try {
      final snapshot = await _firestore.collection('therapists').get();
      return snapshot.docs
          .map((doc) => TherapistModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error en getTherapists: $e');
      throw e;
    }
  }

  // CLIENTES
  Future<List<ClientModel>> getClients() async {
    try {
      final snapshot = await _firestore.collection('client_details').get();
      return snapshot.docs
          .map((doc) => ClientModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error en getClients: $e');
      throw e;
    }
  }

  Future<ClientModel?> getClient(String id) async {
    try {
      final doc = await _firestore.collection('client_details').doc(id).get();
      if (!doc.exists) return null;
      return ClientModel.fromFirestore(doc);
    } catch (e) {
      print('Error en getClient: $e');
      throw e;
    }
  }

  Future<ClientModel?> getClientByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('client_details')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return ClientModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error en getClientByUserId: $e');
      throw e;
    }
  }

  Future<String> addClient(ClientModel client) async {
    try {
      // Si el cliente ya tiene un userId (es un usuario existente)
      if (client.userId.isNotEmpty && client.userId != 'pending') {
        await _firestore
            .collection('client_details')
            .doc(client.userId)
            .set(client.toFirestore());
        return client.userId;
      } else {
        // Crear un nuevo documento
        final docRef = await _firestore
            .collection('client_details')
            .add(client.toFirestore());
        return docRef.id;
      }
    } catch (e) {
      print('Error en addClient: $e');
      throw e;
    }
  }

  Future<void> updateClient(ClientModel client) async {
    try {
      await _firestore
          .collection('client_details')
          .doc(client.id)
          .update(client.toFirestore());
    } catch (e) {
      print('Error en updateClient: $e');
      throw e;
    }
  }

  Future<void> addTreatmentNote(String clientId, TreatmentNote note) async {
    try {
      final clientDoc =
          await _firestore.collection('client_details').doc(clientId).get();
      if (!clientDoc.exists) {
        throw Exception('Cliente no encontrado');
      }

      final client = ClientModel.fromFirestore(clientDoc);
      final notes = List<TreatmentNote>.from(client.treatmentNotes);
      notes.add(note);

      await _firestore.collection('client_details').doc(clientId).update({
        'treatmentNotes': notes.map((n) => n.toMap()).toList(),
        'lastVisit': Timestamp.fromDate(note.date),
        'visitCount': client.visitCount + 1,
      });
    } catch (e) {
      print('Error en addTreatmentNote: $e');
      throw e;
    }
  }

  // CITAS
  Future<List<AppointmentModel>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
    String? clientId,
    String? therapistId,
  }) async {
    try {
      Query query = _firestore.collection('appointments');

      if (startDate != null) {
        query = query.where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('startTime',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (clientId != null) {
        query = query.where('clientId', isEqualTo: clientId);
      }

      if (therapistId != null) {
        query = query.where('therapistId', isEqualTo: therapistId);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error en getAppointments: $e');
      throw e;
    }
  }

  Future<String> addAppointment(AppointmentModel appointment) async {
    try {
      final docRef = await _firestore
          .collection('appointments')
          .add(appointment.toFirestore());

      // Actualizar la última visita del cliente
      await _firestore
          .collection('client_details')
          .doc(appointment.clientId)
          .update({
        'lastVisit': Timestamp.fromDate(appointment.startTime),
      });

      return docRef.id;
    } catch (e) {
      print('Error en addAppointment: $e');
      throw e;
    }
  }

  Future<void> updateAppointment(AppointmentModel appointment) async {
    try {
      // Verificar si el ID es temporal
      if (appointment.id == 'temp-id' || appointment.id.isEmpty) {
        // Si es un ID temporal, crear una nueva cita en lugar de actualizar
        final docRef = await _firestore
            .collection('appointments')
            .add(appointment.toFirestore());

        // Actualizar la última visita del cliente
        await _firestore
            .collection('client_details')
            .doc(appointment.clientId)
            .update({
          'lastVisit': Timestamp.fromDate(appointment.startTime),
        });

        print('Cita creada con ID: ${docRef.id} (ID original era temporal)');
        return;
      }

      // Verificar si el documento existe antes de actualizarlo
      final docSnapshot =
          await _firestore.collection('appointments').doc(appointment.id).get();

      if (!docSnapshot.exists) {
        throw Exception(
            'No existe documento para actualizar: ${appointment.id}');
      }

      // Si el documento existe, actualizarlo
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .update(appointment.toFirestore());
    } catch (e) {
      print('Error en updateAppointment: $e');
      throw e;
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      await _firestore.collection('appointments').doc(id).delete();
    } catch (e) {
      print('Error en deleteAppointment: $e');
      throw e;
    }
  }

  // TRATAMIENTOS
  Future<List<TreatmentModel>> getTreatments({TreatmentType? type}) async {
    try {
      Query query = _firestore.collection('treatments');

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString());
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => TreatmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error en getTreatments: $e');
      throw e;
    }
  }

  Future<String> addTreatment(TreatmentModel treatment) async {
    try {
      final docRef = await _firestore
          .collection('treatments')
          .add(treatment.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error en addTreatment: $e');
      throw e;
    }
  }

  Future<void> updateTreatment(TreatmentModel treatment) async {
    try {
      await _firestore
          .collection('treatments')
          .doc(treatment.id)
          .update(treatment.toFirestore());
    } catch (e) {
      print('Error en updateTreatment: $e');
      throw e;
    }
  }

  Future<void> deleteTreatment(String id) async {
    try {
      await _firestore.collection('treatments').doc(id).delete();
    } catch (e) {
      print('Error en deleteTreatment: $e');
      throw e;
    }
  }

  // TRANSACCIONES
  Future<List<TransactionModel>> getTransactions({
    String? clientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('transactions');

      if (clientId != null) {
        query = query.where('clientId', isEqualTo: clientId);
      }

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error en getTransactions: $e');
      throw e;
    }
  }

  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      final docRef = await _firestore
          .collection('transactions')
          .add(transaction.toFirestore());

      // Si la transacción está vinculada a citas, actualizar el estado de pago de esas citas
      if (transaction.appointmentIds.isNotEmpty &&
          transaction.pendingAmount == 0) {
        for (final appointmentId in transaction.appointmentIds) {
          await _firestore
              .collection('appointments')
              .doc(appointmentId)
              .update({
            'isPaid': true,
            'paymentId': docRef.id,
          });
        }
      }

      return docRef.id;
    } catch (e) {
      print('Error en addTransaction: $e');
      throw e;
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toFirestore());

      // Actualizar el estado de pago de las citas vinculadas
      if (transaction.appointmentIds.isNotEmpty) {
        for (final appointmentId in transaction.appointmentIds) {
          await _firestore
              .collection('appointments')
              .doc(appointmentId)
              .update({
            'isPaid': transaction.pendingAmount == 0,
            'paymentId': transaction.id,
          });
        }
      }
    } catch (e) {
      print('Error en updateTransaction: $e');
      throw e;
    }
  }

  // INVENTARIO
  Future<List<InventoryModel>> getInventory(
      {bool? lowStockOnly, bool? expiringOnly}) async {
    try {
      final snapshot = await _firestore.collection('inventory').get();
      final items = snapshot.docs
          .map((doc) => InventoryModel.fromFirestore(doc))
          .toList();

      if (lowStockOnly == true) {
        return items.where((item) => item.isLowStock).toList();
      }

      if (expiringOnly == true) {
        final now = DateTime.now();
        // Filtrar productos que vencen dentro de 30 días
        return items
            .where((item) =>
                item.expiryDate != null &&
                item.expiryDate!.difference(now).inDays <= 30)
            .toList();
      }

      return items;
    } catch (e) {
      print('Error en getInventory: $e');
      throw e;
    }
  }

  Future<List<InventoryModel>> getInventoryByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('inventory')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs
          .map((doc) => InventoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error en getInventoryByCategory: $e');
      throw e;
    }
  }

  Future<List<InventoryModel>> getInventoryByTreatmentType(
      String treatmentType) async {
    try {
      final snapshot = await _firestore
          .collection('inventory')
          .where('treatmentType', isEqualTo: treatmentType)
          .get();

      return snapshot.docs
          .map((doc) => InventoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error en getInventoryByTreatmentType: $e');
      throw e;
    }
  }

  Future<List<InventoryModel>> getInventoryByUsedInTreatment(
      String treatmentName) async {
    try {
      // Firestore no permite consultas de array-contains directamente con campos anidados
      // por lo que debemos obtener todos y filtrar en el cliente
      final snapshot = await _firestore.collection('inventory').get();

      final items = snapshot.docs
          .map((doc) => InventoryModel.fromFirestore(doc))
          .where((item) =>
              item.usedInTreatments != null &&
              item.usedInTreatments!.contains(treatmentName))
          .toList();

      return items;
    } catch (e) {
      print('Error en getInventoryByUsedInTreatment: $e');
      throw e;
    }
  }

  Future<List<InventoryModel>> getExpiringInventory(
      {int daysThreshold = 30}) async {
    try {
      final snapshot = await _firestore.collection('inventory').get();
      final items = snapshot.docs
          .map((doc) => InventoryModel.fromFirestore(doc))
          .toList();

      final now = DateTime.now();
      return items
          .where((item) =>
              item.expiryDate != null &&
              item.expiryDate!.difference(now).inDays <= daysThreshold)
          .toList();
    } catch (e) {
      print('Error en getExpiringInventory: $e');
      throw e;
    }
  }

  Future<void> updateInventoryQuantity(String id, int newQuantity) async {
    try {
      await _firestore.collection('inventory').doc(id).update({
        'quantity': newQuantity,
        'lastRestockDate':
            newQuantity > 0 ? Timestamp.now() : FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error en updateInventoryQuantity: $e');
      throw e;
    }
  }

  Future<String> addInventoryItem(InventoryModel item) async {
    try {
      final docRef =
          await _firestore.collection('inventory').add(item.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error en addInventoryItem: $e');
      throw e;
    }
  }

  Future<void> updateInventoryItem(InventoryModel item) async {
    try {
      await _firestore
          .collection('inventory')
          .doc(item.id)
          .update(item.toFirestore());
    } catch (e) {
      print('Error en updateInventoryItem: $e');
      throw e;
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    try {
      await _firestore.collection('inventory').doc(id).delete();
    } catch (e) {
      print('Error en deleteInventoryItem: $e');
      throw e;
    }
  }

  // Método para reducir el inventario usado en un tratamiento específico
  Future<void> reduceInventoryForTreatment(String treatmentName) async {
    try {
      // Obtener todos los productos usados en este tratamiento
      final items = await getInventoryByUsedInTreatment(treatmentName);

      // Reducir el stock para cada producto según su usagePerTreatment
      for (final item in items) {
        if (item.usagePerTreatment != null && item.usagePerTreatment! > 0) {
          if (item.quantity >= item.usagePerTreatment!) {
            final newQuantity = item.quantity - item.usagePerTreatment!;
            await updateInventoryQuantity(item.id, newQuantity);
          }
        }
      }
    } catch (e) {
      print('Error en reduceInventoryForTreatment: $e');
      throw e;
    }
  }

  // lib/services/database_service.dart (continuación)

  // MÉTRICAS Y ESTADÍSTICAS
  Future<Map<String, dynamic>> getMonthlyStats(DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      // Obtener citas del mes
      final appointments = await getAppointments(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      // Obtener transacciones del mes
      final transactions = await getTransactions(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      // Calcular métricas
      final totalRevenue = transactions.fold<double>(0,
          (sum, t) => sum + (t.type == TransactionType.payment ? t.amount : 0));

      final totalExpenses = transactions.fold<double>(0,
          (sum, t) => sum + (t.type == TransactionType.expense ? t.amount : 0));

      final totalProfit = totalRevenue - totalExpenses;

      final completedAppointments = appointments
          .where((a) => a.status == AppointmentStatus.completed)
          .length;

      final cancelledAppointments = appointments
          .where((a) =>
              a.status == AppointmentStatus.cancelled ||
              a.status == AppointmentStatus.noShow)
          .length;

      // Clientes únicos atendidos este mes
      final uniqueClients = appointments
          .where((a) => a.status == AppointmentStatus.completed)
          .map((a) => a.clientId)
          .toSet()
          .length;

      // Ingresos por tipo de tratamiento
      final revenueByTreatment = <String, double>{};
      for (final appointment in appointments) {
        if (appointment.status == AppointmentStatus.completed) {
          revenueByTreatment[appointment.treatmentName] =
              (revenueByTreatment[appointment.treatmentName] ?? 0) +
                  appointment.price;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalExpenses': totalExpenses,
        'totalProfit': totalProfit,
        'completedAppointments': completedAppointments,
        'cancelledAppointments': cancelledAppointments,
        'uniqueClients': uniqueClients,
        'revenueByTreatment': revenueByTreatment,
      };
    } catch (e) {
      print('Error en getMonthlyStats: $e');
      throw e;
    }
  }

  // Nuevo método para obtener estadísticas de inventario
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final allItems = await getInventory();

      // Total de productos
      final totalItems = allItems.length;

      // Productos con stock bajo
      final lowStockItems = allItems.where((item) => item.isLowStock).length;

      // Valor total del inventario (costo)
      final totalInventoryCost = allItems.fold<double>(
          0, (sum, item) => sum + (item.costPrice * item.quantity));

      // Valor total del inventario (venta)
      final totalInventoryValue = allItems.fold<double>(
          0, (sum, item) => sum + (item.retailPrice * item.quantity));

      // Ganancia potencial
      final potentialProfit = totalInventoryValue - totalInventoryCost;

      // Productos por categoría
      final itemsByCategory = <String, int>{};
      for (final item in allItems) {
        itemsByCategory[item.category] =
            (itemsByCategory[item.category] ?? 0) + 1;
      }

      // Productos por tipo de tratamiento
      final itemsByTreatmentType = <String, int>{};
      for (final item in allItems) {
        if (item.treatmentType != null) {
          itemsByTreatmentType[item.treatmentType!] =
              (itemsByTreatmentType[item.treatmentType!] ?? 0) + 1;
        }
      }

      // Productos próximos a vencer
      final now = DateTime.now();
      final expiringItems = allItems
          .where((item) =>
              item.expiryDate != null &&
              item.expiryDate!.difference(now).inDays <= 30)
          .length;

      return {
        'totalItems': totalItems,
        'lowStockItems': lowStockItems,
        'expiringItems': expiringItems,
        'totalInventoryCost': totalInventoryCost,
        'totalInventoryValue': totalInventoryValue,
        'potentialProfit': potentialProfit,
        'itemsByCategory': itemsByCategory,
        'itemsByTreatmentType': itemsByTreatmentType,
      };
    } catch (e) {
      print('Error en getInventoryStats: $e');
      throw e;
    }
  }
}

// lib/providers/appointment_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/appointment_model.dart';
import 'client_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  // Iniciamos el proceso de inicialización pero no esperamos

  service.initialize();
  return service;
});

final appointmentsProvider =
    FutureProvider.family<List<AppointmentModel>, Map<String, dynamic>>(
        (ref, params) async {
  final dbService = ref.watch(databaseServiceProvider);

  return await dbService.getAppointments(
    startDate: params['startDate'],
    endDate: params['endDate'],
    clientId: params['clientId'],
    therapistId: params['therapistId'],
  );
});

// Para el filtrado
final appointmentFilterProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'startDate': DateTime.now().subtract(const Duration(days: 7)),
    'endDate': DateTime.now().add(const Duration(days: 30)),
    'clientId': null,
    'therapistId': null,
    'status': null,
  };
});

final filteredAppointmentsProvider =
    Provider<AsyncValue<List<AppointmentModel>>>((ref) {
  final filters = ref.watch(appointmentFilterProvider);
  final appointmentsAsync = ref.watch(appointmentsProvider(filters));

  return appointmentsAsync.when(
    data: (appointments) {
      if (filters['status'] == null) {
        return AsyncValue.data(appointments);
      }

      return AsyncValue.data(appointments.where((appointment) {
        return appointment.status == filters['status'];
      }).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

class AppointmentsNotifier
    extends StateNotifier<AsyncValue<List<AppointmentModel>>> {
  final DatabaseService _dbService;
  final NotificationService _notificationService;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String? _clientId;
  String? _therapistId;

  AppointmentsNotifier(this._dbService, this._notificationService)
      : super(const AsyncValue.loading()) {
    _initializeNotificationService();
    loadAppointments();
  }

  // Método para inicializar el servicio de notificaciones de forma segura
  Future<void> _initializeNotificationService() async {
    try {
      final success = await _notificationService.initialize();
      print('Servicio de notificaciones inicializado: $success');
    } catch (e) {
      print('Error al inicializar el servicio de notificaciones: $e');
      // No propagamos el error para no bloquear el flujo principal
    }
  }

  Future<void> loadAppointments() async {
    state = const AsyncValue.loading();
    try {
      final appointments = await _dbService.getAppointments(
        startDate: _startDate,
        endDate: _endDate,
        clientId: _clientId,
        therapistId: _therapistId,
      );
      state = AsyncValue.data(appointments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    loadAppointments();
  }

  void setFilters({String? clientId, String? therapistId}) {
    _clientId = clientId;
    _therapistId = therapistId;
    loadAppointments();
  }

  // Método para programar notificación de forma segura
  Future<void> _safeScheduleNotification(AppointmentModel appointment) async {
    // Verifica que la fecha de la cita no sea pasada antes de intentar programar
    final now = DateTime.now();
    if (appointment.startTime.isBefore(now)) {
      print('No se programa notificación para cita pasada: ${appointment.id}');
      return;
    }

    try {
      await _notificationService.scheduleAppointmentReminder(appointment);
    } catch (e) {
      print('Error al programar notificación: $e');
      // No propagamos el error para no interrumpir el flujo principal
    }
  }

  // Método para cancelar notificación de forma segura
  Future<void> _safeCancelNotification(AppointmentModel appointment) async {
    try {
      await _notificationService.cancelAppointmentReminder(appointment);
    } catch (e) {
      print('Error al cancelar notificación: $e');
      // No propagamos el error para no interrumpir el flujo principal
    }
  }

  Future<String> addAppointment(AppointmentModel appointment) async {
    try {
      // Verificar si el ID es temporal o vacío
      if (appointment.id == 'temp-id' || appointment.id.isEmpty) {
        final id = await _dbService.addAppointment(appointment);

        // Solo programamos notificaciones si la adición fue exitosa
        final appointmentWithId = appointment.copyWith(id: id);

        // Programar notificación de forma segura
        await _safeScheduleNotification(appointmentWithId);

        // Refrescar la lista
        loadAppointments();
        return id;
      } else {
        // Si ya tiene ID, usar el método de actualización
        await updateAppointment(appointment);
        return appointment.id;
      }
    } catch (e) {
      print('Error en addAppointment: $e');
      throw e;
    }
  }

  Future<void> updateAppointment(AppointmentModel appointment) async {
    try {
      // Si el ID es temporal o vacío, esto se convierte en una operación de adición
      if (appointment.id == 'temp-id' || appointment.id.isEmpty) {
        await addAppointment(appointment.copyWith(id: ''));
        return;
      }

      // Intentar actualizar la cita
      await _dbService.updateAppointment(appointment);

      // Manejar recordatorios según el estado
      if (appointment.status == AppointmentStatus.cancelled ||
          appointment.status == AppointmentStatus.noShow) {
        await _safeCancelNotification(appointment);
      } else {
        await _safeScheduleNotification(appointment);
      }

      loadAppointments(); // Refrescar la lista
    } catch (e) {
      print('Error en updateAppointment: $e');
      throw e;
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      // Primero necesitamos obtener la cita para cancelar recordatorios
      final appointments = state.value ?? [];
      final appointment = appointments.firstWhere(
        (a) => a.id == id,
        orElse: () => throw Exception('Cita no encontrada con ID: $id'),
      );

      await _dbService.deleteAppointment(id);
      await _safeCancelNotification(appointment);

      loadAppointments(); // Refrescar la lista
    } catch (e) {
      print('Error en deleteAppointment: $e');
      throw e;
    }
  }

  // Para arrastrar y soltar citas
  Future<void> moveAppointment(String id, DateTime newStartTime) async {
    try {
      final appointments = state.value ?? [];
      final appointment = appointments.firstWhere((a) => a.id == id);

      // Calcular la duración de la cita original
      final duration = appointment.endTime.difference(appointment.startTime);

      // Calcular nuevo tiempo de finalización
      final newEndTime = newStartTime.add(duration);

      // Crear cita actualizada
      final updatedAppointment = appointment.copyWith(
        startTime: newStartTime,
        endTime: newEndTime,
        id: appointment.id, // Asegurarse de mantener el ID original
      );

      // Verificar si hay conflictos
      final hasConflict = appointments.any((a) =>
          a.id != id &&
          a.therapistId == updatedAppointment.therapistId &&
          a.overlaps(updatedAppointment));

      if (hasConflict) {
        throw Exception('Hay un conflicto de horario con otra cita');
      }

      await _dbService.updateAppointment(updatedAppointment);

      // Actualizar notificaciones
      await _safeScheduleNotification(updatedAppointment);

      loadAppointments(); // Refrescar la lista
    } catch (e) {
      print('Error en moveAppointment: $e');
      throw e;
    }
  }
}

final appointmentsNotifierProvider = StateNotifierProvider<AppointmentsNotifier,
    AsyncValue<List<AppointmentModel>>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return AppointmentsNotifier(dbService, notificationService);
});

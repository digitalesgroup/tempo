// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/appointment_model.dart';

class NotificationService {
  // Patrón Singleton para evitar múltiples instancias
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Usa lazy initialization con un Completer para controlar el estado de inicialización
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Completer<bool> _initCompleter = Completer<bool>();
  Future<bool> get isInitialized => _initCompleter.future;
  bool _hasInitializationStarted = false;

  Future<bool> initialize() async {
    // Si ya está completado, devuelve el resultado
    if (_initCompleter.isCompleted) {
      return await isInitialized;
    }

    // Si ya se inició la inicialización pero no completó, espera a que termine
    if (_hasInitializationStarted) {
      return await isInitialized;
    }

    _hasInitializationStarted = true;

    try {
      tz_data.initializeTimeZones();

      try {
        tz.setLocalLocation(tz.getLocation('America/Guayaquil'));
      } catch (e) {
        print('Error configurando zona horaria: $e');
        // Fallback a UTC si hay error
        tz.setLocalLocation(tz.UTC);
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final success = await _notifications.initialize(initSettings) ?? false;

      // Verificar si las notificaciones programadas están soportadas
      try {
        final androidDetails = await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.getActiveNotifications();
        print(
            'Soporte de notificaciones verificado: ${androidDetails != null}');
      } catch (e) {
        print('Error verificando soporte de notificaciones: $e');
      }

      print('Inicialización de notificaciones completada. Éxito: $success');
      _initCompleter.complete(success);
      return success;
    } catch (e) {
      print('Error en initialize: $e');
      _initCompleter.complete(false);
      return false;
    }
  }

  Future<void> scheduleAppointmentReminder(AppointmentModel appointment) async {
    // Asegurar que está inicializado
    final initialized = await initialize();
    if (!initialized) {
      print('No se pudo enviar notificación, el servicio no está inicializado');
      return;
    }

    try {
      // Validar que el ID no sea provisional
      if (appointment.id == 'temp-id' || appointment.id.isEmpty) {
        print('No se puede programar recordatorio para cita con ID temporal');
        return;
      }

      // Verificar que la fecha no sea en el pasado
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = tz.TZDateTime.from(
        appointment.startTime.subtract(const Duration(hours: 24)),
        tz.local,
      );

      if (scheduledTime.isBefore(now)) {
        print('No se puede programar recordatorio en el pasado');
        // Mostrar notificación inmediata para citas próximas en vez de fallar
        if (appointment.startTime.isAfter(DateTime.now())) {
          await _showImmediateAppointmentNotification(appointment);
        }
        return;
      }

      try {
        await _tryScheduleZonedNotification(appointment);
      } catch (e) {
        print('Error programando notificación zonificada: $e');
        // Intentar mostrar notificación inmediata como alternativa
        await _showImmediateAppointmentNotification(appointment);
      }
    } catch (e) {
      print('Error en scheduleAppointmentReminder: $e');
    }
  }

  // Método privado para intentar programar notificaciones zonificadas
  Future<void> _tryScheduleZonedNotification(
      AppointmentModel appointment) async {
    final initialized = await initialize();
    if (!initialized) return;

    try {
      // Programar recordatorio para 24 horas antes
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = tz.TZDateTime.from(
        appointment.startTime.subtract(const Duration(hours: 24)),
        tz.local,
      );

      // Verificar que la fecha no sea en el pasado
      if (scheduledTime.isBefore(now)) {
        print('No se puede programar recordatorio en el pasado');
        return; // No programar si es en el pasado
      }

      const androidDetails = AndroidNotificationDetails(
        'appointment_reminder',
        'Recordatorios de Citas',
        channelDescription: 'Notificaciones para próximas citas',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        appointment.id.hashCode,
        'Próxima Cita',
        'Recordatorio: Tienes una cita de ${appointment.treatmentName}...',
        scheduledTime,
        notificationDetails,
        // Añade esta línea:
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print(
          'Notificación programada exitosamente para: ${scheduledTime.toString()}');
    } catch (e) {
      print('Error en _tryScheduleZonedNotification: $e');
      throw e; // Relanzar para manejo en el llamador
    }
  }

  // Método para mostrar notificación inmediata como fallback
  Future<void> _showImmediateAppointmentNotification(
      AppointmentModel appointment) async {
    final initialized = await initialize();
    if (!initialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'appointment_reminder_immediate',
        'Recordatorios de Citas (Inmediatos)',
        channelDescription: 'Notificaciones inmediatas para citas',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Formatear la fecha para la notificación
      final dateStr =
          '${appointment.startTime.day}/${appointment.startTime.month}/${appointment.startTime.year}';
      final timeStr =
          '${appointment.startTime.hour}:${appointment.startTime.minute.toString().padLeft(2, '0')}';

      await _notifications.show(
        appointment.id.hashCode,
        'Cita Programada',
        'Cita de ${appointment.treatmentName} con ${appointment.clientName} el $dateStr a las $timeStr',
        notificationDetails,
      );

      print('Notificación inmediata mostrada como alternativa a la programada');
    } catch (e) {
      print('Error en _showImmediateAppointmentNotification: $e');
    }
  }

  Future<void> cancelAppointmentReminder(AppointmentModel appointment) async {
    final initialized = await initialize();
    if (!initialized) return;

    try {
      await _notifications.cancel(appointment.id.hashCode);
      await _notifications.cancel(appointment.id.hashCode + 1);
      print('Recordatorios cancelados para la cita ${appointment.id}');
    } catch (e) {
      print('Error en cancelAppointmentReminder: $e');
    }
  }

  Future<void> showLowStockNotification(
      String productName, int quantity) async {
    final initialized = await initialize();
    if (!initialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'low_stock',
        'Alertas de Stock Bajo',
        channelDescription: 'Notificaciones para productos con poco stock',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        productName.hashCode,
        'Stock Bajo',
        'El producto $productName tiene solo $quantity unidades disponibles',
        notificationDetails,
      );
    } catch (e) {
      print('Error en showLowStockNotification: $e');
    }
  }

  Future<void> showInsufficientStockForTreatmentNotification(
      String name, String treatmentName) async {
    final initialized = await initialize();
    if (!initialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'insufficient_stock',
        'Alertas de Stock Insuficiente',
        channelDescription:
            'Notificaciones para productos con stock insuficiente para tratamientos',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        name.hashCode,
        'Stock Insuficiente',
        'El producto $name tiene stock insuficiente para el tratamiento $treatmentName',
        notificationDetails,
      );
    } catch (e) {
      print('Error en showInsufficientStockForTreatmentNotification: $e');
    }
  }
}

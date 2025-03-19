import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modelo para las preferencias de notificación
class NotificationPreferences {
  final bool enableEmailNotifications;
  final bool enablePushNotifications;
  final bool enableSMSNotifications;
  final bool appointmentReminders;
  final bool marketingNotifications;

  NotificationPreferences({
    this.enableEmailNotifications = true,
    this.enablePushNotifications = true,
    this.enableSMSNotifications = false,
    this.appointmentReminders = true,
    this.marketingNotifications = false,
  });

  // Copia con parámetros modificados
  NotificationPreferences copyWith({
    bool? enableEmailNotifications,
    bool? enablePushNotifications,
    bool? enableSMSNotifications,
    bool? appointmentReminders,
    bool? marketingNotifications,
  }) {
    return NotificationPreferences(
      enableEmailNotifications:
          enableEmailNotifications ?? this.enableEmailNotifications,
      enablePushNotifications:
          enablePushNotifications ?? this.enablePushNotifications,
      enableSMSNotifications:
          enableSMSNotifications ?? this.enableSMSNotifications,
      appointmentReminders: appointmentReminders ?? this.appointmentReminders,
      marketingNotifications:
          marketingNotifications ?? this.marketingNotifications,
    );
  }
}

// Provider para las preferencias de notificación
final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferences>((ref) {
  return NotificationPreferencesNotifier();
});

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferences> {
  NotificationPreferencesNotifier() : super(NotificationPreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    state = NotificationPreferences(
      enableEmailNotifications:
          prefs.getBool('enableEmailNotifications') ?? true,
      enablePushNotifications: prefs.getBool('enablePushNotifications') ?? true,
      enableSMSNotifications: prefs.getBool('enableSMSNotifications') ?? false,
      appointmentReminders: prefs.getBool('appointmentReminders') ?? true,
      marketingNotifications: prefs.getBool('marketingNotifications') ?? false,
    );
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    state = preferences;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
        'enableEmailNotifications', preferences.enableEmailNotifications);
    await prefs.setBool(
        'enablePushNotifications', preferences.enablePushNotifications);
    await prefs.setBool(
        'enableSMSNotifications', preferences.enableSMSNotifications);
    await prefs.setBool(
        'appointmentReminders', preferences.appointmentReminders);
    await prefs.setBool(
        'marketingNotifications', preferences.marketingNotifications);
  }
}

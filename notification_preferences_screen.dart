import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_preferences_provider.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  late NotificationPreferences _preferences;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _preferences = ref.read(notificationPreferencesProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferencias de Notificación'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Canales de Notificación',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    title: 'Notificaciones por Correo',
                    value: _preferences.enableEmailNotifications,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences.copyWith(
                          enableEmailNotifications: value,
                        );
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Notificaciones Push',
                    value: _preferences.enablePushNotifications,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences.copyWith(
                          enablePushNotifications: value,
                        );
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Notificaciones SMS',
                    value: _preferences.enableSMSNotifications,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences.copyWith(
                          enableSMSNotifications: value,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipos de Notificación',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    title: 'Recordatorios de Citas',
                    value: _preferences.appointmentReminders,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences.copyWith(
                          appointmentReminders: value,
                        );
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Promociones y Marketing',
                    value: _preferences.marketingNotifications,
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences.copyWith(
                          marketingNotifications: value,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _savePreferences,
          child: _isSaving
              ? const CircularProgressIndicator()
              : const Text('Guardar Preferencias'),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
    );
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(notificationPreferencesProvider.notifier)
          .updatePreferences(_preferences);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferencias guardadas correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Regresar a configuración
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar preferencias: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

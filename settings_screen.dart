import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luxe_spa_management/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/dialogs/edit_profile_dialog.dart';
import 'notification_preferences_screen.dart';
import 'business_info_screen.dart';
import 'user_management_screen.dart';
import 'backup_screen.dart';
import 'theme_settings_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuario no encontrado'));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Sección de perfil de usuario
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perfil de Usuario',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editProfile(user),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Rol: ${user.role.toString().split('.').last}'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sección de ajustes de la aplicación
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajustes de la Aplicación',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Modo Oscuro'),
                        value: themeMode == ThemeMode.dark,
                        onChanged: (value) async {
                          // Añadimos un print para depuración
                          print('Switch toggled: $value');

                          // Llamamos directamente al método toggleTheme
                          await ref.read(themeProvider.notifier).toggleTheme();

                          // Añadimos un print para verificar el estado después del toggle
                          print(
                              'Tema actual después del toggle: ${ref.read(themeProvider) == ThemeMode.dark ? "oscuro" : "claro"}');
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Tema y Apariencia'),
                        trailing: const Icon(Icons.palette),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ThemeSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Idioma'),
                        trailing: DropdownButton<Locale>(
                          value: locale,
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(localeProvider.notifier)
                                  .setLocale(value);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: Locale('es', 'ES'),
                              child: Text('Español'),
                            ),
                            DropdownMenuItem(
                              value: Locale('en', 'US'),
                              child: Text('Inglés'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Preferencias de Notificación'),
                        trailing: const Icon(Icons.notifications),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationPreferencesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sección de ajustes del sistema (solo para administradores)
              if (user.role == UserRole.admin)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajustes del Sistema',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Gestión de Usuarios'),
                          trailing: const Icon(Icons.people),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const UserManagementScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Información del Negocio'),
                          trailing: const Icon(Icons.business),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BusinessInfoScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Respaldo y Exportación de Datos'),
                          trailing: const Icon(Icons.backup),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const BackupScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Botón de cerrar sesión
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Error al cargar información del usuario')),
      ),
    );
  }

  void _editProfile(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(user: user),
    ).then((wasUpdated) {
      if (wasUpdated == true) {
        // Refrescar datos del usuario
        ref.refresh(currentUserProvider);
      }
    });
  }
}

// lib/widgets/common/dashboard_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class DashboardLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const DashboardLayout({
    Key? key,
    required this.child,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: Row(
        children: [
          // Panel lateral fijo
          Container(
            width: 250,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Logo y nombre del spa
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primary,
                  child: const Row(
                    children: [
                      Icon(Icons.spa, color: Colors.white, size: 32),
                      SizedBox(width: 16),
                      Text(
                        'Luxe Spa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildNavItem(
                        context,
                        'Inicio',
                        Icons.dashboard,
                        '/dashboard',
                        currentRoute,
                      ),
                      _buildNavItem(
                        context,
                        'Clientes',
                        Icons.people,
                        '/clients',
                        currentRoute,
                      ),
                      _buildNavItem(
                        context,
                        'Citas',
                        Icons.calendar_today,
                        '/appointments',
                        currentRoute,
                      ),
                      _buildNavItem(
                        context,
                        'Tratamientos',
                        Icons.spa,
                        '/treatments',
                        currentRoute,
                      ),
                      // Opción de Terapeutas, solo visible para administradores
                      isAdmin.when(
                        data: (isAdmin) => isAdmin
                            ? _buildNavItem(
                                context,
                                'Terapeutas',
                                Icons.people_alt,
                                '/therapists',
                                currentRoute,
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      _buildNavItem(
                        context,
                        'Finanzas',
                        Icons.attach_money,
                        '/finances',
                        currentRoute,
                      ),
                      isAdmin.when(
                        data: (isAdmin) => isAdmin ||
                                currentUser.value?.role == UserRole.therapist
                            ? _buildNavItem(
                                context,
                                'Inventario',
                                Icons.inventory,
                                '/inventory',
                                currentRoute,
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      _buildNavItem(
                        context,
                        'Configuración',
                        Icons.settings,
                        '/settings',
                        currentRoute,
                      ),
                    ],
                  ),
                ),
                // Perfil del usuario abajo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: currentUser.when(
                    data: (user) => user != null
                        ? Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name.substring(0, 1)
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      user.role.toString().split('.').last,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout),
                                onPressed: () => ref
                                    .read(authNotifierProvider.notifier)
                                    .signOut(),
                              ),
                            ],
                          )
                        : const Text('No conectado'),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Error'),
                  ),
                ),
              ],
            ),
          ),
          // Contenido principal
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    String currentRoute,
  ) {
    final isSelected = route == currentRoute;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
        selected: isSelected,
        onTap: () {
          context.go(route);
        },
      ),
    );
  }
}

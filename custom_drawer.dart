// lib/widgets/common/custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/appointments/appointment_screen.dart';
import '../../screens/clients/client_screen.dart';
import '../../screens/finances/finance_screen.dart';
import '../../screens/inventory/inventory_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../models/user_model.dart';

class CustomDrawer extends ConsumerWidget {
  final int currentIndex;

  const CustomDrawer({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.spa,
                    size: 30,
                    color: Color(0xFF6A8CAF),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Luxe Spa Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                userRole.when(
                  data: (role) => Text(
                    'Role: ${role.toString().split('.').last}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  loading: () => const SizedBox(height: 14),
                  error: (_, __) => const SizedBox(height: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isSelected: currentIndex == 0,
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => DashboardScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Appointments',
                  isSelected: currentIndex == 1,
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AppointmentsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people,
                  title: 'Clients',
                  isSelected: currentIndex == 2,
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const ClientsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.attach_money,
                  title: 'Finances',
                  isSelected: currentIndex == 3,
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const FinancesScreen(),
                      ),
                    );
                  },
                ),
                userRole.when(
                  data: (role) =>
                      (role == UserRole.admin || role == UserRole.therapist)
                          ? _buildDrawerItem(
                              context,
                              icon: Icons.inventory,
                              title: 'Inventory',
                              isSelected: currentIndex == 4,
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const InventoryScreen(),
                                  ),
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  isSelected: currentIndex == 5,
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '© 2025 Luxe Spa Management',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
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
      onTap: onTap,
      tileColor: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
          : null,
    );
  }
}

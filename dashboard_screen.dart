import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Ajusta o corrige estos imports según tu proyecto
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/specialized/stats_display.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../models/transaction_model.dart';

// Provider para controlar qué métricas mostrar en el dashboard
final dashboardMetricsProvider = StateProvider<Set<String>>((ref) {
  return {
    'appointments',
    'revenue',
    'clients',
    'lowStock',
  };
});

class DashboardScreen extends ConsumerWidget {
  // Creamos mapas “fijos” fuera de build, de modo que no cambie la identidad en cada render
  final Map<String, dynamic> todayParams;
  final Map<String, dynamic> monthParams;

  DashboardScreen({Key? key})
      : todayParams = {
          'startDate': DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
          'endDate': DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            23,
            59,
            59,
          ),
        },
        monthParams = {
          'startDate': DateTime(
            DateTime.now().year,
            DateTime.now().month,
            1,
          ),
          'endDate': DateTime(
            DateTime.now().year,
            DateTime.now().month + 1,
            0,
            23,
            59,
            59,
          ),
        },
        super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);

    // Observa los providers usando los mapas fijos
    final todayAppointments = ref.watch(appointmentsProvider(todayParams));
    final lowStockItems = ref.watch(lowStockInventoryProvider);
    final allClients = ref.watch(clientsProvider);
    final monthlyTransactions = ref.watch(transactionsProvider(monthParams));

    final selectedMetrics = ref.watch(dashboardMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showMetricsSettings(context, ref),
          ),
        ],
      ),
      body: userRole.when(
        data: (role) => RefreshIndicator(
          onRefresh: () async {
            // Al refrescar, usamos EXACTAMENTE los mismos mapas
            ref.refresh(appointmentsProvider(todayParams));
            ref.refresh(lowStockInventoryProvider);
            ref.refresh(clientsProvider);
            ref.refresh(transactionsProvider(monthParams));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedMetrics.contains('stats')) const StatsDisplay(),
                const SizedBox(height: 16),

                // Citas de Hoy
                if (selectedMetrics.contains('appointments'))
                  _buildSection(
                    context,
                    title: "Citas de Hoy",
                    content: todayAppointments.when(
                      data: (appointments) => appointments.isEmpty
                          ? const Center(
                              child: Text('No hay citas programadas para hoy'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: appointments.length,
                              itemBuilder: (context, index) {
                                final appointment = appointments[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                        appointment.clientName.isNotEmpty
                                            ? appointment.clientName[0]
                                                .toUpperCase()
                                            : '?',
                                      ),
                                    ),
                                    title: Text(
                                      '${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')} - ${appointment.clientName}',
                                    ),
                                    subtitle: Text(
                                      'Tratamiento: ${appointment.treatmentName}',
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        appointment.status
                                            .toString()
                                            .split('.')
                                            .last,
                                      ),
                                      backgroundColor:
                                          _getStatusColor(appointment.status),
                                    ),
                                  ),
                                );
                              },
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(
                        child: Text('Error al cargar citas'),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Ingresos del Mes
                if (selectedMetrics.contains('revenue'))
                  _buildSection(
                    context,
                    title: "Ingresos del Mes",
                    content: monthlyTransactions.when(
                      data: (transactions) {
                        final totalRevenue = transactions.fold<double>(
                          0,
                          (sum, t) =>
                              sum +
                              (t.type == TransactionType.payment
                                  ? t.amount
                                  : 0),
                        );

                        final totalExpenses = transactions.fold<double>(
                          0,
                          (sum, t) =>
                              sum +
                              (t.type == TransactionType.expense
                                  ? t.amount
                                  : 0),
                        );

                        final totalProfit = totalRevenue - totalExpenses;

                        return Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                title: 'Ingresos',
                                value: '\$${totalRevenue.toStringAsFixed(2)}',
                                icon: Icons.arrow_upward,
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                title: 'Gastos',
                                value: '\$${totalExpenses.toStringAsFixed(2)}',
                                icon: Icons.arrow_downward,
                                color: Colors.red,
                              ),
                            ),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                title: 'Beneficio',
                                value: '\$${totalProfit.toStringAsFixed(2)}',
                                icon: Icons.account_balance,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(
                        child: Text('Error al cargar datos financieros'),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Clientes Activos
                if (selectedMetrics.contains('clients'))
                  _buildSection(
                    context,
                    title: "Clientes Activos",
                    content: allClients.when(
                      data: (clients) => _buildMetricCard(
                        context,
                        title: 'Total de Clientes',
                        value: clients.length.toString(),
                        icon: Icons.people,
                        color: Colors.purple,
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(
                        child: Text('Error al cargar clientes'),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Productos con Stock Bajo
                if (selectedMetrics.contains('lowStock') &&
                    (role == UserRole.admin || role == UserRole.therapist))
                  _buildSection(
                    context,
                    title: 'Productos con Stock Bajo',
                    content: lowStockItems.when(
                      data: (items) => items.isEmpty
                          ? const Center(
                              child: Text('No hay productos con stock bajo'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(item.name),
                                    subtitle: Text(
                                      '${item.brand} - ${item.category}',
                                    ),
                                    trailing: Text(
                                      '${item.quantity} / ${item.minimumQuantity}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(
                        child: Text('Error al cargar inventario'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Error al cargar el rol de usuario')),
      ),
    );
  }

  // Color del chip según estado de la cita
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.amber;
      case AppointmentStatus.completed:
        return Colors.teal;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // Sección con título + contenido
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            content,
          ],
        ),
      ),
    );
  }

  // Tarjeta de métrica (Ingresos, Gastos, etc.)
  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para configurar métricas del Dashboard
  void _showMetricsSettings(BuildContext context, WidgetRef ref) {
    final selectedMetrics = ref.read(dashboardMetricsProvider);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text('Configurar Métricas del Dashboard'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('Estadísticas Generales'),
                  value: selectedMetrics.contains('stats'),
                  onChanged: (value) {
                    setLocalState(() {
                      if (value == true) {
                        selectedMetrics.add('stats');
                      } else {
                        selectedMetrics.remove('stats');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Citas del Día'),
                  value: selectedMetrics.contains('appointments'),
                  onChanged: (value) {
                    setLocalState(() {
                      if (value == true) {
                        selectedMetrics.add('appointments');
                      } else {
                        selectedMetrics.remove('appointments');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Ingresos'),
                  value: selectedMetrics.contains('revenue'),
                  onChanged: (value) {
                    setLocalState(() {
                      if (value == true) {
                        selectedMetrics.add('revenue');
                      } else {
                        selectedMetrics.remove('revenue');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Clientes'),
                  value: selectedMetrics.contains('clients'),
                  onChanged: (value) {
                    setLocalState(() {
                      if (value == true) {
                        selectedMetrics.add('clients');
                      } else {
                        selectedMetrics.remove('clients');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Productos con Stock Bajo'),
                  value: selectedMetrics.contains('lowStock'),
                  onChanged: (value) {
                    setLocalState(() {
                      if (value == true) {
                        selectedMetrics.add('lowStock');
                      } else {
                        selectedMetrics.remove('lowStock');
                      }
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(dashboardMetricsProvider.notifier).state =
                      Set.from(selectedMetrics);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

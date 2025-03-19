// lib/widgets/specialized/stats_display.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/transaction_model.dart';

class StatsDisplay extends ConsumerWidget {
  const StatsDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final monthlyAppointments = ref.watch(appointmentsProvider({
      'startDate': startOfMonth,
      'endDate': endOfMonth,
    }));

    final monthlyTransactions = ref.watch(transactionsProvider({
      'startDate': startOfMonth,
      'endDate': endOfMonth,
    }));

    final allClients = ref.watch(clientsProvider);
    final lowStockItems = ref.watch(lowStockInventoryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen Mensual: ${DateFormat.MMMM('es').format(now)} ${now.year}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildStatCard(
                  context,
                  title: 'Citas',
                  value: monthlyAppointments.when(
                    data: (appointments) => appointments.length.toString(),
                    loading: () => '...',
                    error: (_, __) => 'Error',
                  ),
                  icon: Icons.calendar_today,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  context,
                  title: 'Ingresos',
                  value: monthlyTransactions.when(
                    data: (transactions) {
                      final totalRevenue = transactions.fold<double>(
                        0,
                        (sum, transaction) =>
                            sum +
                            (transaction.type == TransactionType.payment
                                ? transaction.amount
                                : 0),
                      );
                      return '\$${totalRevenue.toStringAsFixed(2)}';
                    },
                    loading: () => '...',
                    error: (_, __) => 'Error',
                  ),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                _buildStatCard(
                  context,
                  title: 'Clientes',
                  value: allClients.when(
                    data: (clients) => clients.length.toString(),
                    loading: () => '...',
                    error: (_, __) => 'Error',
                  ),
                  icon: Icons.people,
                  color: Colors.purple,
                ),
                _buildStatCard(
                  context,
                  title: 'Stock Bajo',
                  value: lowStockItems.when(
                    data: (items) => items.length.toString(),
                    loading: () => '...',
                    error: (_, __) => 'Error',
                  ),
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 180,
      child: Card(
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../widgets/common/custom_dialog.dart';
import '../../widgets/specialized/transaction_form.dart';
import '../../widgets/specialized/partial_payment_form.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class FinancesScreen extends ConsumerStatefulWidget {
  const FinancesScreen({super.key});

  @override
  ConsumerState<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends ConsumerState<FinancesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _startDate;
  late DateTime _endDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'hoy'; // Ahora 'hoy' es el valor predeterminado

  @override
  void initState() {
    super.initState();

    // Inicializar con el día actual (hoy)
    final now = DateTime.now();
    _startDate =
        DateTime(now.year, now.month, now.day); // Inicio del día actual
    _endDate = now; // Hasta ahora (final del día actual)

    _tabController = TabController(length: 2, vsync: this);

    // Inicializar el filtro con el rango de fechas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsNotifierProvider.notifier).setFilters(
            startDate: _startDate,
            endDate: _endDate,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _selectDateRange() {
    // En lugar del showDateRangePicker predeterminado, mostraremos nuestro popup personalizado
    showCustomDateRangePicker(
      context: context,
      initialStartDate: _startDate,
      initialEndDate: _endDate,
      onApply: (start, end) {
        setState(() {
          _startDate = start;
          _endDate = end;
          _activeFilter = 'personalizado';
        });

        ref.read(transactionsNotifierProvider.notifier).setFilters(
              startDate: _startDate,
              endDate: _endDate,
            );
      },
    );
  }

  // Selector de fechas personalizado como popup
  Future<void> showCustomDateRangePicker({
    required BuildContext context,
    required DateTime initialStartDate,
    required DateTime initialEndDate,
    required Function(DateTime, DateTime) onApply,
  }) async {
    DateTime startDate = initialStartDate;
    DateTime endDate = initialEndDate;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Container(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seleccionar período',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fechas predefinidas rápidas
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickDateChip(
                          context: context,
                          label: 'Hoy',
                          onTap: () {
                            final now = DateTime.now();
                            setStateDialog(() {
                              startDate =
                                  DateTime(now.year, now.month, now.day);
                              endDate = DateTime(
                                  now.year, now.month, now.day, 23, 59, 59);
                            });
                          },
                        ),
                        _buildQuickDateChip(
                          context: context,
                          label: 'Ayer',
                          onTap: () {
                            final yesterday = DateTime.now()
                                .subtract(const Duration(days: 1));
                            setStateDialog(() {
                              startDate = DateTime(yesterday.year,
                                  yesterday.month, yesterday.day);
                              endDate = DateTime(yesterday.year,
                                  yesterday.month, yesterday.day, 23, 59, 59);
                            });
                          },
                        ),
                        _buildQuickDateChip(
                          context: context,
                          label: 'Esta semana',
                          onTap: () {
                            final now = DateTime.now();
                            setStateDialog(() {
                              startDate =
                                  now.subtract(Duration(days: now.weekday - 1));
                              startDate = DateTime(startDate.year,
                                  startDate.month, startDate.day);
                              endDate = now;
                            });
                          },
                        ),
                        _buildQuickDateChip(
                          context: context,
                          label: 'Este mes',
                          onTap: () {
                            final now = DateTime.now();
                            setStateDialog(() {
                              startDate = DateTime(now.year, now.month, 1);
                              endDate = now;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Selección de fechas
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateSelector(
                            context: context,
                            label: 'Desde',
                            date: startDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  startDate = picked;
                                  if (startDate.isAfter(endDate)) {
                                    endDate = DateTime(
                                        startDate.year,
                                        startDate.month,
                                        startDate.day,
                                        23,
                                        59,
                                        59);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateSelector(
                            context: context,
                            label: 'Hasta',
                            date: endDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  endDate = DateTime(picked.year, picked.month,
                                      picked.day, 23, 59, 59);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onApply(startDate, endDate);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Aplicar'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Widget para selección rápida de fechas
  Widget _buildQuickDateChip({
    required BuildContext context,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  // Widget para selector de fecha individual
  Widget _buildDateSelector({
    required BuildContext context,
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para establecer filtros rápidos de fecha
  void _setDateFilter(String filter) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (filter) {
      case 'hoy':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        break;
      case 'ayer':
        // Mejor manejo del caso "ayer"
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(
            yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);
        break;
      case 'semana':
        // Inicio de la semana (lunes)
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'mes':
        // Primer día del mes actual
        start = DateTime(now.year, now.month, 1);
        break;
      case 'trimestre':
        // Primer día del trimestre actual
        final currentQuarter = (now.month - 1) ~/ 3;
        start = DateTime(now.year, currentQuarter * 3 + 1, 1);
        break;
      case 'año':
        // Primer día del año actual
        start = DateTime(now.year, 1, 1);
        break;
      default:
        // Mantener el filtro personalizado actual
        return;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
      _activeFilter = filter;
    });

    ref.read(transactionsNotifierProvider.notifier).setFilters(
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  Future<void> _exportToExcel(List<TransactionModel> transactions) async {
    final excel = Excel.createExcel();
    final sheet = excel.sheets[excel.getDefaultSheet()];

    // Encabezados
    sheet!.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('Fecha');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value =
        TextCellValue('Cliente');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value =
        TextCellValue('Tipo');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value =
        TextCellValue('Método de Pago');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value =
        TextCellValue('Monto');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value =
        TextCellValue('Pendiente');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0)).value =
        TextCellValue('Notas');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0)).value =
        TextCellValue('Personal');

    // Datos
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
              .value =
          TextCellValue(
              '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
          .value = TextCellValue(transaction.clientName);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
          .value = TextCellValue(transaction.type.toString().split('.').last);
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1))
              .value =
          TextCellValue(transaction.paymentMethod.toString().split('.').last);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1))
          .value = DoubleCellValue(transaction.amount);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1))
          .value = DoubleCellValue(transaction.pendingAmount);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 1))
          .value = TextCellValue(transaction.notes);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: i + 1))
          .value = TextCellValue(transaction.staffName);
    }

    // Generar archivo
    final bytes = excel.encode();
    if (bytes != null) {
      final filename =
          'Transacciones_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$filename';
        final file = File(path);
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Archivo guardado en: $path')),
          );
        }
      }
    }
  }

  // Filtrar transacciones por búsqueda
  List<TransactionModel> _filterTransactions(
      List<TransactionModel> transactions) {
    if (_searchQuery.isEmpty) {
      return transactions;
    }

    return transactions.where((transaction) {
      final query = _searchQuery.toLowerCase();
      return transaction.clientName.toLowerCase().contains(query) ||
          transaction.staffName.toLowerCase().contains(query) ||
          transaction.type.toString().toLowerCase().contains(query) ||
          transaction.paymentMethod.toString().toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(transactionsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión Financiera'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transacciones'),
            Tab(text: 'Reportes'),
          ],
        ),
        actions: [
          // Solo dejamos el botón de exportar
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              if (transactionsState.value != null &&
                  transactionsState.value!.isNotEmpty) {
                _exportToExcel(transactionsState.value!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No hay datos para exportar')),
                );
              }
            },
            tooltip: 'Exportar a Excel',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña de Transacciones
          transactionsState.when(
            data: (transactions) {
              // Calcular totales (incluso si no hay transacciones, mostraremos 0)
              final totalRevenue = transactions.fold<double>(
                0,
                (sum, t) =>
                    sum + (t.type == TransactionType.payment ? t.amount : 0),
              );
              final totalExpenses = transactions.fold<double>(
                0,
                (sum, t) =>
                    sum + (t.type == TransactionType.expense ? t.amount : 0),
              );
              final totalProfit = totalRevenue - totalExpenses;
              final totalPending = transactions.fold<double>(
                0,
                (sum, t) => sum + t.pendingAmount,
              );

              // Filtrar transacciones por búsqueda
              final filteredTransactions = _filterTransactions(transactions);

              return Column(
                children: [
                  // Panel superior con 4 tarjetas de resumen
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade50,
                    child: Row(
                      children: [
                        // Ingresos
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Ingresos',
                            amount: totalRevenue,
                            color: Colors.green,
                            icon: Icons.arrow_upward,
                          ),
                        ),
                        // Gastos
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Gastos',
                            amount: totalExpenses,
                            color: Colors.red,
                            icon: Icons.arrow_downward,
                          ),
                        ),
                        // Beneficio
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Beneficio',
                            amount: totalProfit,
                            color: Colors.blue,
                            icon: Icons.account_balance,
                          ),
                        ),
                        // Nueva tarjeta: Cobros Pendientes
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Cobros Pendientes',
                            amount: totalPending,
                            color: Colors.orange,
                            icon: Icons.payments,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Período seleccionado (ahora como un widget clickeable para abrir el selector de fechas)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _selectDateRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.date_range, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Período: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (totalPending > 0)
                          Chip(
                            label: Text(
                              'Pendiente: \$${totalPending.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.orange,
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                  ),

                  // Filtros rápidos de fecha
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Personalizado'),
                            selected: _activeFilter == 'personalizado',
                            showCheckmark: false,
                            backgroundColor: Colors.grey.shade200,
                            selectedColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            side: BorderSide(
                              color: _activeFilter == 'personalizado'
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                            ),
                            labelStyle: TextStyle(
                              color: _activeFilter == 'personalizado'
                                  ? Theme.of(context).primaryColor
                                  : Colors.black,
                              fontWeight: _activeFilter == 'personalizado'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                _selectDateRange();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildDateFilterChip('Hoy', 'hoy'),
                          const SizedBox(width: 8),
                          _buildDateFilterChip('Ayer', 'ayer'),
                          const SizedBox(width: 8),
                          _buildDateFilterChip('Esta Semana', 'semana'),
                          const SizedBox(width: 8),
                          _buildDateFilterChip('Este Mes', 'mes'),
                          const SizedBox(width: 8),
                          _buildDateFilterChip('Este Trimestre', 'trimestre'),
                          const SizedBox(width: 8),
                          _buildDateFilterChip('Este Año', 'año'),
                        ],
                      ),
                    ),
                  ),

                  // Título y búsqueda
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transacciones de Ingresos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Barra de búsqueda movida aquí
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar transacciones...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Encabezados de tabla
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(width: 36), // Espacio para icono
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Fecha',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text(
                              'Cliente',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Tipo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text(
                              'Método de Pago',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Monto',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Pendiente',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Personal',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Lista de transacciones
                  Expanded(
                    child: filteredTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay transacciones para el período seleccionado',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                Text(
                                  '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = filteredTransactions[index];
                              return InkWell(
                                onTap: () =>
                                    _showTransactionDetails(transaction),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade200),
                                    ),
                                    color: index % 2 == 0
                                        ? Colors.grey.shade50
                                        : Colors.white,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      // Icono de tipo
                                      SizedBox(
                                        width: 36,
                                        child: Center(
                                          child: CircleAvatar(
                                            radius: 14,
                                            backgroundColor:
                                                _getTransactionTypeColor(
                                                    transaction.type),
                                            child: Icon(
                                              _getTransactionTypeIcon(
                                                  transaction.type),
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Fecha
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          DateFormat('dd/MM/yyyy')
                                              .format(transaction.date),
                                        ),
                                      ),

                                      // Cliente
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          transaction.clientName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      // Tipo
                                      SizedBox(
                                        width: 100,
                                        child: _buildTypeTag(transaction.type),
                                      ),

                                      // Método de pago
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          _getPaymentMethodName(
                                              transaction.paymentMethod),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      // Monto
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          '\$${transaction.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: _getTransactionTypeColor(
                                                transaction.type),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),

                                      // Pendiente (ahora con espacio adecuado)
                                      SizedBox(
                                        width: 100,
                                        child: transaction.pendingAmount > 0
                                            ? Text(
                                                '\$${transaction.pendingAmount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.right,
                                              )
                                            : const Text(
                                                '-',
                                                textAlign: TextAlign.right,
                                              ),
                                      ),

                                      // Personal (ahora con espacio adecuado)
                                      Expanded(
                                        child: Text(
                                          transaction.staffName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
              child: Text('Error al cargar transacciones'),
            ),
          ),

          // Pestaña de reportes
          transactionsState.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Center(
                  child: Text('No hay datos para generar reportes'),
                );
              }

              // Placeholder de reportes
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Reportes Financieros',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aquí se mostrarían gráficos y métricas avanzadas',
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_download),
                      label: const Text('Exportar Reportes'),
                      onPressed: () {
                        if (transactions.isNotEmpty) {
                          _exportToExcel(transactions);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
              child: Text('Error al cargar datos'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget para los chips de filtro de fecha
  Widget _buildDateFilterChip(String label, String filter) {
    final isActive = _activeFilter == filter;

    return FilterChip(
      label: Text(label),
      selected: isActive,
      showCheckmark: false,
      backgroundColor: Colors.grey.shade200,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
      side: BorderSide(
        color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
      ),
      labelStyle: TextStyle(
        color: isActive ? Theme.of(context).primaryColor : Colors.black,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          _setDateFilter(filter);
        }
      },
    );
  }

  // Widget para tipo de transacción
  Widget _buildTypeTag(TransactionType type) {
    String label;
    Color color;

    switch (type) {
      case TransactionType.payment:
        label = 'Pago';
        color = Colors.green;
        break;
      case TransactionType.refund:
        label = 'Reembolso';
        color = Colors.orange;
        break;
      case TransactionType.expense:
        label = 'Gasto';
        color = Colors.red;
        break;
      case TransactionType.productSale:
        label = 'Venta';
        color = Colors.blue;
        break;
      case TransactionType.other:
      default:
        label = 'Otro';
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Obtener nombre del método de pago
  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentMethod.debitCard:
        return 'Tarjeta de Débito';
      case PaymentMethod.bankTransfer:
        return 'Transferencia';
      case PaymentMethod.mobilePayment:
        return 'Pago Móvil';
      case PaymentMethod.giftCard:
        return 'Tarjeta de Regalo';
      default:
        return 'Desconocido';
    }
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalles de la Transacción'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem(
                'Fecha',
                DateFormat('dd/MM/yyyy').format(transaction.date),
              ),
              _buildDetailItem('Cliente', transaction.clientName),
              _buildDetailItem(
                'Tipo',
                transaction.type.toString().split('.').last,
              ),
              _buildDetailItem(
                'Método de Pago',
                transaction.paymentMethod.toString().split('.').last,
              ),
              _buildDetailItem(
                'Monto',
                '\$${transaction.amount.toStringAsFixed(2)}',
              ),
              if (transaction.pendingAmount > 0)
                _buildDetailItem(
                  'Pendiente',
                  '\$${transaction.pendingAmount.toStringAsFixed(2)}',
                ),
              if (transaction.appointmentIds.isNotEmpty)
                _buildDetailItem(
                  'Citas Asociadas',
                  transaction.appointmentIds.join(', '),
                ),
              if (transaction.notes.isNotEmpty)
                _buildDetailItem('Notas', transaction.notes),
              _buildDetailItem('Registrado por', transaction.staffName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
          if (transaction.pendingAmount > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showRegisterPartialPaymentDialog(transaction);
              },
              child: const Text('Registrar Pago Parcial'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => FullScreenDialog(
        title: 'Nueva Transacción',
        content: TransactionForm(
          onSave: (transaction) async {
            try {
              showDialog(
                context: ctx,
                barrierDismissible: false,
                builder: (loadingCtx) => const AlertDialog(
                  content: SizedBox(
                    height: 100,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Guardando transacción...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              final id = await ref
                  .read(transactionsNotifierProvider.notifier)
                  .addTransaction(transaction);

              Navigator.of(ctx).pop(); // cierra el loading
              Navigator.of(ctx).pop(); // cierra el formulario

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Transacción #${id.substring(0, 8)} guardada correctamente',
                  ),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: 'VER DETALLES',
                    textColor: Colors.white,
                    onPressed: () {
                      _showTransactionDetails(
                        TransactionModel(
                          id: id,
                          clientId: transaction.clientId,
                          clientName: transaction.clientName,
                          appointmentIds: transaction.appointmentIds,
                          type: transaction.type,
                          paymentMethod: transaction.paymentMethod,
                          amount: transaction.amount,
                          pendingAmount: transaction.pendingAmount,
                          date: transaction.date,
                          notes: transaction.notes,
                          staffId: transaction.staffId,
                          staffName: transaction.staffName,
                        ),
                      );
                    },
                  ),
                ),
              );
            } catch (e) {
              Navigator.of(ctx).pop(); // cierra el loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al guardar la transacción: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showRegisterPartialPaymentDialog(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Pago Parcial'),
        content: PartialPaymentForm(
          transaction: transaction,
          onSave: (amount, paymentMethod) async {
            try {
              showDialog(
                context: ctx,
                barrierDismissible: false,
                builder: (loadingCtx) => const AlertDialog(
                  content: SizedBox(
                    height: 100,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Procesando pago...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              await ref
                  .read(transactionsNotifierProvider.notifier)
                  .registerPartialPayment(transaction, amount);

              Navigator.of(ctx).pop(); // cierra el loading
              Navigator.of(ctx).pop(); // cierra el form

              ref
                  .read(transactionsNotifierProvider.notifier)
                  .loadTransactions();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pago parcial registrado correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al registrar el pago: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Color _getTransactionTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.payment:
        return Colors.green;
      case TransactionType.refund:
        return Colors.orange;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.productSale:
        return Colors.blue;
      case TransactionType.other:
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.payment:
        return Icons.payment;
      case TransactionType.refund:
        return Icons.money_off;
      case TransactionType.expense:
        return Icons.shopping_cart;
      case TransactionType.productSale:
        return Icons.shopping_bag;
      case TransactionType.other:
      default:
        return Icons.help_outline;
    }
  }
}

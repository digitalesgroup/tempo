// lib/widgets/specialized/transaction_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../../models/client_model.dart';
import '../../providers/client_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/appointment_model.dart';

class TransactionForm extends ConsumerStatefulWidget {
  final ClientModel? selectedClient;
  final Function(TransactionModel transaction) onSave;

  const TransactionForm({
    super.key,
    this.selectedClient,
    required this.onSave,
  });

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  late ClientModel? _selectedClient;

  TransactionType _selectedType = TransactionType.payment;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  final _amountController = TextEditingController();
  final _pendingAmountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isPartialPayment = false;
  bool _isLoading = false;

  // Citas disponibles/pendientes de pago para el cliente
  List<AppointmentModel> _availableAppointments = [];
  // Citas que el usuario selecciona para este pago
  List<AppointmentModel> _selectedAppointments = [];

  String? _clientSearchQuery = '';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedClient = widget.selectedClient;

    // Si ya hay un cliente preseleccionado, cargamos sus citas
    if (_selectedClient != null) {
      _loadClientAppointments();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _pendingAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Cargar citas del cliente sin filtrar por rango (o con un rango “fijo”)
  Future<void> _loadClientAppointments() async {
    if (_selectedClient == null) return;

    setState(() {
      _isLoading = true;
      _availableAppointments = [];
    });

    try {
      // Obtener directamente el servicio de base de datos
      final dbService = ref.read(databaseServiceProvider);

      // Realizar la consulta directamente sin usar el provider de filtros
      final appointments = await dbService.getAppointments(
        clientId: _selectedClient!.id,
        // Opcional: puedes añadir rangos de fecha para limitar resultados
        startDate:
            DateTime.now().subtract(const Duration(days: 365)), // Último año
        endDate: DateTime.now().add(const Duration(days: 365)), // Próximo año
      );

      if (!mounted) return;

      setState(() {
        _availableAppointments =
            appointments.where((appt) => appt.isPaid == false).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error al cargar citas: $e');
    }
  }

  // Suma los precios de las citas seleccionadas
  double _calculateAppointmentsTotal() {
    return _selectedAppointments.fold(
      0,
      (sum, appointment) => sum + appointment.price,
    );
  }

  // Actualiza el monto de la transacción cuando el usuario (des)selecciona citas
  void _updateAmountFromAppointments() {
    final total = _calculateAppointmentsTotal();
    if (total > 0) {
      _amountController.text = total.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsState = ref.watch(filteredClientsProvider);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) SELECCIÓN DE CLIENTE (si no está preseleccionado)
            if (widget.selectedClient == null) ...[
              const Text(
                'Cliente',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Buscar cliente...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _clientSearchQuery = value.toLowerCase();
                  });
                  ref.read(clientSearchProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 8),
              clientsState.when(
                data: (clients) {
                  final filteredClients = _clientSearchQuery!.isEmpty
                      ? clients
                      : clients.where((client) {
                          final fullName = client.fullName.toLowerCase();
                          final phone = client.contactInfo.phone;
                          final email = client.contactInfo.email.toLowerCase();
                          return fullName.contains(_clientSearchQuery!) ||
                              phone.contains(_clientSearchQuery!) ||
                              email.contains(_clientSearchQuery!);
                        }).toList();

                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: filteredClients.isEmpty
                        ? const Center(
                            child: Text('No se encontraron clientes'),
                          )
                        : ListView.builder(
                            itemCount: filteredClients.length,
                            itemBuilder: (context, index) {
                              final client = filteredClients[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    client.fullName.isNotEmpty
                                        ? client.fullName[0].toUpperCase()
                                        : '?',
                                  ),
                                ),
                                title: Text(client.fullName),
                                subtitle: Text(client.contactInfo.phone),
                                selected: _selectedClient?.id == client.id,
                                onTap: () {
                                  setState(() {
                                    _selectedClient = client;
                                    _selectedAppointments = [];
                                  });
                                  _loadClientAppointments();
                                },
                              );
                            },
                          ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Error al cargar clientes'),
              ),
              if (_selectedClient != null) ...[
                const SizedBox(height: 8),
                Chip(
                  label: Text('Cliente: ${_selectedClient!.fullName}'),
                  onDeleted: () {
                    setState(() {
                      _selectedClient = null;
                      _selectedAppointments = [];
                      _availableAppointments = [];
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],

            // 2) TIPO DE TRANSACCIÓN
            const Text(
              'Tipo de Transacción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TransactionType>(
              value: _selectedType,
              validator: (value) =>
                  value == null ? 'Seleccione un tipo de transacción' : null,
              items: TransactionType.values.map((type) {
                String label;
                IconData icon;
                switch (type) {
                  case TransactionType.payment:
                    label = 'Pago';
                    icon = Icons.payment;
                    break;
                  case TransactionType.refund:
                    label = 'Reembolso';
                    icon = Icons.money_off;
                    break;
                  case TransactionType.expense:
                    label = 'Gasto';
                    icon = Icons.shopping_cart;
                    break;
                  case TransactionType.productSale:
                    label = 'Venta de Producto';
                    icon = Icons.shopping_bag;
                    break;
                  case TransactionType.other:
                  default:
                    label = 'Otro';
                    icon = Icons.help_outline;
                    break;
                }
                return DropdownMenuItem<TransactionType>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (type) {
                setState(() {
                  _selectedType = type!;
                  if (type != TransactionType.payment) {
                    _isPartialPayment = false;
                  }
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // 3) MÉTODO DE PAGO
            const Text(
              'Método de Pago',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PaymentMethod>(
              value: _selectedPaymentMethod,
              validator: (value) =>
                  value == null ? 'Seleccione un método de pago' : null,
              items: PaymentMethod.values.map((method) {
                String label;
                IconData icon;
                switch (method) {
                  case PaymentMethod.cash:
                    label = 'Efectivo';
                    icon = Icons.money;
                    break;
                  case PaymentMethod.creditCard:
                    label = 'Tarjeta de Crédito';
                    icon = Icons.credit_card;
                    break;
                  case PaymentMethod.debitCard:
                    label = 'Tarjeta de Débito';
                    icon = Icons.credit_card;
                    break;
                  case PaymentMethod.bankTransfer:
                    label = 'Transferencia Bancaria';
                    icon = Icons.account_balance;
                    break;
                  case PaymentMethod.mobilePayment:
                    label = 'Pago Móvil';
                    icon = Icons.phone_android;
                    break;
                  case PaymentMethod.giftCard:
                    label = 'Tarjeta de Regalo';
                    icon = Icons.card_giftcard;
                    break;
                }
                return DropdownMenuItem<PaymentMethod>(
                  value: method,
                  child: Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (method) {
                setState(() {
                  _selectedPaymentMethod = method!;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // 4) CITAS RELACIONADAS (solo si es Payment y hay cliente)
            if (_selectedClient != null &&
                _selectedType == TransactionType.payment) ...[
              const Text(
                'Citas Relacionadas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_availableAppointments.isEmpty)
                Card(
                  color: Colors.grey.shade100,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 8),
                        Text('No hay citas pendientes de pago'),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  color: Colors.blue.shade50,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Seleccione las citas a pagar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.select_all),
                              label: const Text('Seleccionar todas'),
                              onPressed: () {
                                setState(() {
                                  if (_selectedAppointments.length ==
                                      _availableAppointments.length) {
                                    _selectedAppointments.clear();
                                  } else {
                                    _selectedAppointments =
                                        List.from(_availableAppointments);
                                  }
                                  _updateAmountFromAppointments();
                                });
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        ..._availableAppointments.map((appointment) {
                          final isSelected =
                              _selectedAppointments.contains(appointment);
                          return CheckboxListTile(
                            title: Text(
                              '${DateFormat('dd/MM/yyyy HH:mm').format(appointment.startTime)} - ${appointment.treatmentName}',
                            ),
                            subtitle: Text(
                                '\$${appointment.price.toStringAsFixed(2)}'),
                            value: isSelected,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedAppointments.add(appointment);
                                } else {
                                  _selectedAppointments.remove(appointment);
                                }
                                _updateAmountFromAppointments();
                              });
                            },
                            secondary: Icon(
                              Icons.event,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                          );
                        }).toList(),
                        if (_selectedAppointments.isNotEmpty) ...[
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total seleccionado:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '\$${_calculateAppointmentsTotal().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // 5) MONTO
            const Text(
              'Monto (\$)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese un monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingrese un monto válido';
                }
                return null;
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '0.00',
                prefixText: '\$ ',
                suffixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),

            // 6) PAGO PARCIAL (solo si es Payment)
            if (_selectedType == TransactionType.payment) ...[
              Card(
                color: _isPartialPayment
                    ? Colors.amber.shade50
                    : Colors.grey.shade50,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _isPartialPayment,
                            activeColor: Colors.amber,
                            onChanged: (value) {
                              setState(() {
                                _isPartialPayment = value ?? false;
                                if (!_isPartialPayment) {
                                  _pendingAmountController.clear();
                                }
                              });
                            },
                          ),
                          const Text(
                            'Pago Parcial',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (_isPartialPayment)
                            const Icon(Icons.info_outline, color: Colors.amber),
                        ],
                      ),
                      if (_isPartialPayment) ...[
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Monto Pendiente (\$)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _pendingAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (!_isPartialPayment) return null;
                            if (value == null || value.isEmpty) {
                              return 'Ingrese el monto pendiente';
                            }
                            final pending = double.tryParse(value);
                            if (pending == null || pending < 0) {
                              return 'Monto pendiente inválido';
                            }
                            final total = double.tryParse(
                                  _amountController.text,
                                ) ??
                                0.0;
                            if (pending >= total) {
                              return 'El monto pendiente debe ser menor que el total';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '0.00',
                            prefixText: '\$ ',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 7) NOTAS
            const Text(
              'Notas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Añadir notas (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // 8) BOTONES
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _saveTransaction,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un cliente')),
      );
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    double pendingAmount = 0;
    if (_isPartialPayment) {
      pendingAmount = double.parse(_pendingAmountController.text.trim());
    }

    // Obtener user actual para staffId/staffName
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al usuario')),
      );
      return;
    }

    final transaction = TransactionModel(
      id: '', // Se generará en la base
      clientId: _selectedClient!.id,
      clientName: _selectedClient!.fullName,
      appointmentIds: _selectedAppointments.map((a) => a.id).toList(),
      type: _selectedType,
      paymentMethod: _selectedPaymentMethod,
      amount: amount,
      pendingAmount: pendingAmount,
      date: DateTime.now(),
      notes: _notesController.text.trim(),
      staffId: currentUser.id,
      staffName: currentUser.name,
    );

    widget.onSave(transaction);
  }
}

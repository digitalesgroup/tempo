// lib/widgets/specialized/partial_payment_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';

class PartialPaymentForm extends ConsumerStatefulWidget {
  final TransactionModel transaction;
  final Function(double amount, PaymentMethod method) onSave;

  const PartialPaymentForm({
    super.key,
    required this.transaction,
    required this.onSave,
  });

  @override
  ConsumerState<PartialPaymentForm> createState() => _PartialPaymentFormState();
}

class _PartialPaymentFormState extends ConsumerState<PartialPaymentForm> {
  final _amountController = TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Sugerir el monto pendiente como valor por defecto
    _amountController.text =
        widget.transaction.pendingAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Información de la transacción original
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de la transacción',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Cliente', widget.transaction.clientName),
                    _buildInfoRow('Monto Original',
                        '\$${widget.transaction.amount.toStringAsFixed(2)}'),
                    _buildInfoRow('Monto Pendiente',
                        '\$${widget.transaction.pendingAmount.toStringAsFixed(2)}'),
                    if (widget.transaction.appointmentIds.isNotEmpty)
                      _buildInfoRow('Citas Vinculadas',
                          widget.transaction.appointmentIds.length.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Monto a pagar
            const Text(
              'Monto a Pagar (\$)',
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
                if (amount > widget.transaction.pendingAmount) {
                  return 'El monto no puede ser mayor que el pendiente';
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

            // Método de pago
            const Text(
              'Método de Pago',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PaymentMethod>(
              value: _selectedPaymentMethod,
              validator: (value) {
                if (value == null) {
                  return 'Seleccione un método de pago';
                }
                return null;
              },
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

            const SizedBox(height: 24),

            // Información importante
            if (widget.transaction.pendingAmount > 0)
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade800),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información Importante',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'El monto pendiente actual es de \$${widget.transaction.pendingAmount.toStringAsFixed(2)}. ' +
                                  (widget.transaction.appointmentIds.isNotEmpty
                                      ? 'Las citas vinculadas se marcarán como pagadas cuando se complete el pago total.'
                                      : ''),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.payment),
                  label: const Text('Registrar Pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: _processPartialPayment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _processPartialPayment() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Obtener monto del pago
    final amountText = _amountController.text.trim();
    final amount = double.parse(amountText);

    // Verificar si es el último pago
    final isFullPayment = amount >= widget.transaction.pendingAmount;

    // Confirmar la acción
    bool shouldProceed = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar Pago'),
            content: Text(
              isFullPayment
                  ? 'Este pago completará el saldo pendiente de la transacción. ' +
                      (widget.transaction.appointmentIds.isNotEmpty
                          ? 'Las citas vinculadas se marcarán como pagadas.'
                          : '')
                  : 'Se registrará un pago parcial de \$${amount.toStringAsFixed(2)}. ' +
                      'Quedarán pendientes \$${(widget.transaction.pendingAmount - amount).toStringAsFixed(2)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(isFullPayment
                    ? 'Completar Pago'
                    : 'Registrar Pago Parcial'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldProceed) return;

    // Procesar el pago
    widget.onSave(amount, _selectedPaymentMethod);
  }
}

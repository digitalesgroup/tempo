import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/treatment_provider.dart';
import '../../../models/treatment_model.dart';

class TreatmentsScreen extends ConsumerWidget {
  const TreatmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatmentsAsync = ref.watch(treatmentsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Tratamientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditTreatmentDialog(context, ref),
          ),
        ],
      ),
      body: treatmentsAsync.when(
        data: (treatments) {
          if (treatments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay tratamientos registrados'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir Tratamiento'),
                    onPressed: () => _showAddEditTreatmentDialog(context, ref),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: treatments.length,
            itemBuilder: (context, index) {
              final treatment = treatments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  leading: Icon(
                    _getTreatmentIcon(treatment.type),
                    color: treatment.isActive ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    treatment.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: treatment.isActive ? null : Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    '${_getTreatmentTypeName(treatment.type)} - ${treatment.durationFormatted} - \$${treatment.price.toStringAsFixed(2)}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Descripción: ${treatment.description}'),
                          const SizedBox(height: 8),
                          if (treatment.requiredProducts.isNotEmpty) ...[
                            const Text(
                              'Productos requeridos:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              children: treatment.requiredProducts
                                  .map(
                                    (product) => Chip(
                                      label: Text(product),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: Icon(
                                  treatment.isActive
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                label: Text(
                                  treatment.isActive ? 'Desactivar' : 'Activar',
                                ),
                                onPressed: () => _toggleTreatmentStatus(
                                  context,
                                  ref,
                                  treatment.id,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('Editar'),
                                onPressed: () => _showAddEditTreatmentDialog(
                                  context,
                                  ref,
                                  treatment,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete),
                                label: const Text('Eliminar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => _confirmDeleteTreatment(
                                  context,
                                  ref,
                                  treatment,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Error al cargar tratamientos'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditTreatmentDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getTreatmentIcon(TreatmentType type) {
    switch (type) {
      case TreatmentType.facial:
        return Icons.face;
      case TreatmentType.body:
        return Icons.accessibility;
      case TreatmentType.tanning:
        return Icons.wb_sunny;
      case TreatmentType.massage:
        return Icons.spa;
      case TreatmentType.nails:
        return Icons.brush;
      case TreatmentType.hair:
        return Icons.cut;
      case TreatmentType.other:
      default:
        return Icons.category;
    }
  }

  String _getTreatmentTypeName(TreatmentType type) {
    switch (type) {
      case TreatmentType.facial:
        return 'Facial';
      case TreatmentType.body:
        return 'Corporal';
      case TreatmentType.tanning:
        return 'Bronceado';
      case TreatmentType.massage:
        return 'Masaje';
      case TreatmentType.nails:
        return 'Uñas';
      case TreatmentType.hair:
        return 'Cabello';
      case TreatmentType.other:
      default:
        return 'Otro';
    }
  }

  void _showAddEditTreatmentDialog(
    BuildContext context,
    WidgetRef ref, [
    TreatmentModel? treatment,
  ]) {
    showDialog(
      context: context,
      builder: (ctx) => TreatmentFormDialog(
        treatment: treatment,
        onSave: (newTreatment) async {
          try {
            if (treatment == null) {
              // Añadir nuevo tratamiento
              await ref
                  .read(treatmentsNotifierProvider.notifier)
                  .addTreatment(newTreatment);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tratamiento añadido correctamente'),
                  ),
                );
              }
            } else {
              // Actualizar tratamiento existente
              await ref
                  .read(treatmentsNotifierProvider.notifier)
                  .updateTreatment(newTreatment);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tratamiento actualizado correctamente'),
                  ),
                );
              }
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  void _toggleTreatmentStatus(
    BuildContext context,
    WidgetRef ref,
    String treatmentId,
  ) async {
    try {
      await ref
          .read(treatmentsNotifierProvider.notifier)
          .toggleTreatmentStatus(treatmentId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estado del tratamiento actualizado'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _confirmDeleteTreatment(
    BuildContext context,
    WidgetRef ref,
    TreatmentModel treatment,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Está seguro de que desea eliminar el tratamiento "${treatment.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(treatmentsNotifierProvider.notifier)
                    .deleteTreatment(treatment.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tratamiento eliminado correctamente'),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class TreatmentFormDialog extends ConsumerStatefulWidget {
  final TreatmentModel? treatment;
  final Function(TreatmentModel) onSave;

  const TreatmentFormDialog({
    super.key,
    this.treatment,
    required this.onSave,
  });

  @override
  ConsumerState<TreatmentFormDialog> createState() =>
      _TreatmentFormDialogState();
}

class _TreatmentFormDialogState extends ConsumerState<TreatmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  final _productController = TextEditingController();

  TreatmentType _selectedType = TreatmentType.facial;
  final List<String> _requiredProducts = [];

  @override
  void initState() {
    super.initState();
    if (widget.treatment != null) {
      _nameController.text = widget.treatment!.name;
      _descriptionController.text = widget.treatment!.description;
      _durationController.text = widget.treatment!.duration.toString();
      _priceController.text = widget.treatment!.price.toString();
      _selectedType = widget.treatment!.type;
      _requiredProducts.addAll(widget.treatment!.requiredProducts);
    } else {
      _durationController.text = '60'; // Default duration
      _priceController.text = '0.00'; // Default price
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _productController.dispose();
    super.dispose();
  }

  void _addProduct() {
    final product = _productController.text.trim();
    if (product.isNotEmpty) {
      setState(() {
        _requiredProducts.add(product);
        _productController.clear();
      });
    }
  }

  void _removeProduct(String product) {
    setState(() {
      _requiredProducts.remove(product);
    });
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final duration = int.tryParse(_durationController.text) ?? 60;
      final price = double.tryParse(_priceController.text) ?? 0.0;

      final treatmentModel = TreatmentModel(
        id: widget.treatment?.id ?? '',
        name: name,
        description: description,
        type: _selectedType,
        duration: duration,
        price: price,
        requiredProducts: _requiredProducts,
        isActive: widget.treatment?.isActive ?? true,
      );

      widget.onSave(treatmentModel);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.treatment == null
          ? 'Añadir Nuevo Tratamiento'
          : 'Editar Tratamiento'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TreatmentType>(
                decoration: const InputDecoration(
                  labelText: 'Tipo *',
                  border: OutlineInputBorder(),
                ),
                value: _selectedType,
                items: TreatmentType.values.map((type) {
                  return DropdownMenuItem<TreatmentType>(
                    value: type,
                    child: Text(_getTreatmentTypeName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duración (minutos) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio *',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Productos Requeridos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _productController,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addProduct,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_requiredProducts.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _requiredProducts
                      .map(
                        (product) => Chip(
                          label: Text(product),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeProduct(product),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  String _getTreatmentTypeName(TreatmentType type) {
    switch (type) {
      case TreatmentType.facial:
        return 'Facial';
      case TreatmentType.body:
        return 'Corporal';
      case TreatmentType.tanning:
        return 'Bronceado';
      case TreatmentType.massage:
        return 'Masaje';
      case TreatmentType.nails:
        return 'Uñas';
      case TreatmentType.hair:
        return 'Cabello';
      case TreatmentType.other:
      default:
        return 'Otro';
    }
  }
}

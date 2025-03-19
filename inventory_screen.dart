import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_model.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  bool _showLowStockOnly = false;
  bool _showExpiringOnly = false;
  String? _selectedCategory;
  String? _selectedTreatmentType;

  final List<String> _categories = [
    'Todos',
    'Productos Faciales',
    'Productos Corporales',
    'Productos para Bronceado',
    'Aceites Esenciales',
    'Mascarillas',
    'Exfoliantes',
    'Cremas Hidratantes',
    'Equipamiento',
    'Accesorios',
    'Otros'
  ];

  final List<String> _treatmentTypes = [
    'Todos',
    'Facial',
    'Corporal',
    'Bronceado',
    'Varios'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryNotifierProvider.notifier).loadInventory();
    });
  }

  void _toggleLowStockFilter() {
    setState(() {
      _showLowStockOnly = !_showLowStockOnly;
      _showExpiringOnly = false;
      _selectedCategory = null;
      _selectedTreatmentType = null;
    });

    ref
        .read(inventoryNotifierProvider.notifier)
        .setLowStockFilter(_showLowStockOnly);
  }

  void _toggleExpiringFilter() {
    setState(() {
      _showExpiringOnly = !_showExpiringOnly;
      _showLowStockOnly = false;
      _selectedCategory = null;
      _selectedTreatmentType = null;
    });

    ref
        .read(inventoryNotifierProvider.notifier)
        .setExpiringFilter(_showExpiringOnly);
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category == 'Todos' ? null : category;
      _selectedTreatmentType = null;
      _showLowStockOnly = false;
      _showExpiringOnly = false;
    });

    ref
        .read(inventoryNotifierProvider.notifier)
        .setCategoryFilter(_selectedCategory);
  }

  void _selectTreatmentType(String? treatmentType) {
    setState(() {
      _selectedTreatmentType = treatmentType == 'Todos' ? null : treatmentType;
      _selectedCategory = null;
      _showLowStockOnly = false;
      _showExpiringOnly = false;
    });

    ref
        .read(inventoryNotifierProvider.notifier)
        .setTreatmentTypeFilter(_selectedTreatmentType);
  }

  void _clearFilters() {
    setState(() {
      _showLowStockOnly = false;
      _showExpiringOnly = false;
      _selectedCategory = null;
      _selectedTreatmentType = null;
      _searchQuery = '';
    });

    ref.read(inventoryNotifierProvider.notifier).clearFilters();
  }

  void _showUpdateQuantityDialog(InventoryModel item) {
    final controller = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Actualizar cantidad de ${item.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nueva Cantidad',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = int.tryParse(controller.text);
              if (newQuantity != null && newQuantity >= 0) {
                ref.read(inventoryNotifierProvider.notifier).updateQuantity(
                      item.id,
                      newQuantity,
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showAddStockDialog(InventoryModel item) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Añadir stock a ${item.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Cantidad a añadir',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                ref.read(inventoryNotifierProvider.notifier).addStock(
                      item.id,
                      amount,
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _showReduceStockDialog(InventoryModel item) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reducir stock de ${item.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Cantidad a reducir',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                try {
                  ref.read(inventoryNotifierProvider.notifier).reduceStock(
                        item.id,
                        amount,
                      );
                  Navigator.of(ctx).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Reducir'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final categoryController = TextEditingController();
    final quantityController = TextEditingController();
    final minimumQuantityController = TextEditingController(text: '5');
    final costPriceController = TextEditingController();
    final retailPriceController = TextEditingController();
    final notesController = TextEditingController();
    final barcodeController = TextEditingController();
    final usagePerTreatmentController = TextEditingController();

    DateTime? selectedExpiryDate;
    String? selectedCategory;
    String? selectedTreatmentType;
    bool forSale = true;
    List<String> selectedTreatments = [];
    List<String> selectedSkinTypes = [];

    final skinTypes = [
      'Normal',
      'Seca',
      'Grasa',
      'Mixta',
      'Sensible',
      'Madura',
      'Con Acné'
    ];

    final treatments = [
      'Limpieza Facial',
      'Hidratación Profunda',
      'Tratamiento Anti-Edad',
      'Masaje Facial',
      'Masaje Corporal',
      'Tratamiento Reductor',
      'Exfoliación Corporal',
      'Bronceado',
      'Manicura',
      'Pedicura'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Añadir Nuevo Producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre*',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: brandController,
                  decoration: const InputDecoration(
                    labelText: 'Marca*',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Categoría*',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedCategory,
                  items: _categories.where((c) => c != 'Todos').map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value;
                      categoryController.text = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad*',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: minimumQuantityController,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad Mínima*',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Precio Costo*',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: retailPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Precio Venta*',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de Barras (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Fecha de Vencimiento (opcional)'),
                  subtitle: Text(
                    selectedExpiryDate == null
                        ? 'No seleccionada'
                        : DateFormat('dd/MM/yyyy').format(selectedExpiryDate!),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedExpiryDate = picked;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Disponible para Venta'),
                  value: forSale,
                  onChanged: (value) {
                    setDialogState(() {
                      forSale = value ?? true;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Tratamiento',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedTreatmentType,
                  items: _treatmentTypes.where((t) => t != 'Todos').map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedTreatmentType = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (selectedTreatmentType == 'Facial') ...[
                  const Text('Tipos de Piel Compatibles:'),
                  Wrap(
                    spacing: 6,
                    children: skinTypes.map((type) {
                      return FilterChip(
                        label: Text(type),
                        selected: selectedSkinTypes.contains(type),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedSkinTypes.add(type);
                            } else {
                              selectedSkinTypes.remove(type);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Usado en Tratamientos:'),
                Wrap(
                  spacing: 6,
                  children: treatments.map((treatment) {
                    return FilterChip(
                      label: Text(treatment),
                      selected: selectedTreatments.contains(treatment),
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedTreatments.add(treatment);
                          } else {
                            selectedTreatments.remove(treatment);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (selectedTreatments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: usagePerTreatmentController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad usada por tratamiento (unidades)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validar campos requeridos
                if (nameController.text.isEmpty ||
                    brandController.text.isEmpty ||
                    categoryController.text.isEmpty ||
                    quantityController.text.isEmpty ||
                    costPriceController.text.isEmpty ||
                    retailPriceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Por favor complete todos los campos requeridos'),
                    ),
                  );
                  return;
                }

                // Convertir valores
                final quantity = int.tryParse(quantityController.text) ?? 0;
                final minimumQuantity =
                    int.tryParse(minimumQuantityController.text) ?? 5;
                final costPrice =
                    double.tryParse(costPriceController.text) ?? 0.0;
                final retailPrice =
                    double.tryParse(retailPriceController.text) ?? 0.0;
                final usagePerTreatment = selectedTreatments.isNotEmpty
                    ? int.tryParse(usagePerTreatmentController.text)
                    : null;

                // Crear modelo de inventario
                final newItem = InventoryModel(
                  id: '', // El ID se generará automáticamente en el backend
                  name: nameController.text.trim(),
                  brand: brandController.text.trim(),
                  category: categoryController.text.trim(),
                  quantity: quantity,
                  minimumQuantity: minimumQuantity,
                  costPrice: costPrice,
                  retailPrice: retailPrice,
                  barcode: barcodeController.text.isEmpty
                      ? null
                      : barcodeController.text.trim(),
                  expiryDate: selectedExpiryDate,
                  lastRestockDate: DateTime.now(),
                  notes: notesController.text.trim(),
                  treatmentType: selectedTreatmentType,
                  compatibleSkinTypes:
                      selectedSkinTypes.isEmpty ? null : selectedSkinTypes,
                  forSale: forSale,
                  usedInTreatments:
                      selectedTreatments.isEmpty ? null : selectedTreatments,
                  usagePerTreatment: usagePerTreatment,
                );

                // Añadir al inventario y cerrar diálogo
                ref
                    .read(inventoryNotifierProvider.notifier)
                    .addInventoryItem(newItem)
                    .then((_) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Producto añadido correctamente')),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${error.toString()}')),
                  );
                });
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(InventoryModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.imageUrl != null)
                Image.network(
                  item.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              Text('Marca: ${item.brand}'),
              Text('Categoría: ${item.category}'),
              Text('Cantidad: ${item.quantity}'),
              Text('Cantidad mínima: ${item.minimumQuantity}'),
              Text('Precio de costo: \$${item.costPrice.toStringAsFixed(2)}'),
              Text('Precio de venta: \$${item.retailPrice.toStringAsFixed(2)}'),
              Text(
                  'Ganancia: \$${item.profit.toStringAsFixed(2)} (${item.profitMargin.toStringAsFixed(2)}%)'),
              if (item.barcode != null)
                Text('Código de barras: ${item.barcode}'),
              if (item.expiryDate != null)
                Text(
                    'Fecha de vencimiento: ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}'),
              Text(
                  'Última reposición: ${DateFormat('dd/MM/yyyy').format(item.lastRestockDate)}'),
              if (item.treatmentType != null)
                Text('Tipo de tratamiento: ${item.treatmentType}'),
              if (item.compatibleSkinTypes != null &&
                  item.compatibleSkinTypes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Tipos de piel compatibles:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 4,
                  children: item.compatibleSkinTypes!
                      .map((type) => Chip(label: Text(type)))
                      .toList(),
                ),
              ],
              if (item.usedInTreatments != null &&
                  item.usedInTreatments!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Usado en tratamientos:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 4,
                  children: item.usedInTreatments!
                      .map((treatment) => Chip(label: Text(treatment)))
                      .toList(),
                ),
              ],
              if (item.usagePerTreatment != null)
                Text(
                    'Cantidad usada por tratamiento: ${item.usagePerTreatment}'),
              const SizedBox(height: 8),
              Text('Disponible para venta: ${item.forSale ? 'Sí' : 'No'}'),
              if (item.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Notas:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(item.notes),
              ],
              if (item.estimatedDaysUntilStockout() != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Días estimados hasta agotar stock: ${item.estimatedDaysUntilStockout()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.estimatedDaysUntilStockout()! < 7
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Inventario'),
        actions: [
          IconButton(
            icon: Icon(
              _showLowStockOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: _toggleLowStockFilter,
            tooltip: 'Mostrar solo productos con stock bajo',
          ),
          IconButton(
            icon: Icon(
              _showExpiringOnly ? Icons.access_time_filled : Icons.access_time,
            ),
            onPressed: _toggleExpiringFilter,
            tooltip: 'Mostrar solo productos por vencer',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddProductDialog,
            tooltip: 'Añadir nuevo producto',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar Productos',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filtros rápidos
                      if (_showLowStockOnly ||
                          _showExpiringOnly ||
                          _selectedCategory != null ||
                          _selectedTreatmentType != null ||
                          _searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Limpiar Filtros'),
                            onPressed: _clearFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade100,
                              foregroundColor: Colors.red.shade900,
                            ),
                          ),
                        ),

                      // Selector de categoría
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: DropdownButton<String>(
                          hint: const Text('Categoría'),
                          value: _selectedCategory == null
                              ? 'Todos'
                              : _selectedCategory,
                          items: _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: _selectCategory,
                        ),
                      ),

                      // Selector de tipo de tratamiento
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: DropdownButton<String>(
                          hint: const Text('Tipo Tratamiento'),
                          value: _selectedTreatmentType == null
                              ? 'Todos'
                              : _selectedTreatmentType,
                          items: _treatmentTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: _selectTreatmentType,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: inventoryState.when(
              data: (items) {
                // Filtrar items basado en la búsqueda
                final filteredItems = _searchQuery.isEmpty
                    ? items
                    : items.where((item) {
                        return item.name.toLowerCase().contains(_searchQuery) ||
                            item.brand.toLowerCase().contains(_searchQuery) ||
                            item.category
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            (item.barcode
                                    ?.toLowerCase()
                                    .contains(_searchQuery) ??
                                false) ||
                            (item.notes.toLowerCase().contains(_searchQuery));
                      }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron productos'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];

                    // Calcular si el producto está por vencer (menos de 30 días)
                    final isExpiringSoon = item.expiryDate != null
                        ? item.expiryDate!.difference(DateTime.now()).inDays <
                            30
                        : false;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: InkWell(
                        onTap: () => _showProductDetails(item),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                            '${item.brand} - ${item.category}'),
                                        if (item.treatmentType != null)
                                          Text('Tipo: ${item.treatmentType}'),
                                      ],
                                    ),
                                  ),
                                  if (item.isLowStock)
                                    const Chip(
                                      label: Text('Stock Bajo'),
                                      backgroundColor: Colors.red,
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                    ),
                                  if (isExpiringSoon)
                                    Chip(
                                      label: const Text('Por Vencer'),
                                      backgroundColor: Colors.orange,
                                      labelStyle:
                                          const TextStyle(color: Colors.white),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Stock: ${item.quantity}'),
                                      Text('Mínimo: ${item.minimumQuantity}'),
                                      if (item.expiryDate != null)
                                        Text(
                                            'Vence: ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}'),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          'Costo: \$${item.costPrice.toStringAsFixed(2)}'),
                                      Text(
                                          'Venta: \$${item.retailPrice.toStringAsFixed(2)}'),
                                      Text(
                                          'Ganancia: ${item.profitMargin.toStringAsFixed(1)}%'),
                                    ],
                                  ),
                                ],
                              ),
                              if (item.usedInTreatments != null &&
                                  item.usedInTreatments!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Usado en: ${item.usedInTreatments!.take(2).join(", ")}${item.usedInTreatments!.length > 2 ? "..." : ""}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () =>
                                        _showReduceStockDialog(item),
                                    tooltip: 'Reducir stock',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _showAddStockDialog(item),
                                    tooltip: 'Añadir stock',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _showUpdateQuantityDialog(item),
                                    tooltip: 'Editar cantidad',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () => _showProductDetails(item),
                                    tooltip: 'Ver detalles',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error al cargar inventario: ${error.toString()}'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        tooltip: 'Añadir nuevo producto',
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respaldo y Exportación de Datos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Respaldo Manual',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Crea un respaldo manual de todos los datos de la aplicación. El respaldo incluirá clientes, citas, transacciones, inventario y configuraciones.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.backup),
                        label: const Text('Crear Respaldo'),
                        onPressed: _isExporting ? null : _createBackup,
                      ),
                      if (_isExporting) const CircularProgressIndicator(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exportar Datos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Exporta los datos de la aplicación en formato CSV para usarlos en otras aplicaciones como Excel.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.people),
                        label: const Text('Clientes'),
                        onPressed:
                            _isExporting ? null : () => _exportData('clientes'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Citas'),
                        onPressed:
                            _isExporting ? null : () => _exportData('citas'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.monetization_on),
                        label: const Text('Transacciones'),
                        onPressed: _isExporting
                            ? null
                            : () => _exportData('transacciones'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.inventory),
                        label: const Text('Inventario'),
                        onPressed: _isExporting
                            ? null
                            : () => _exportData('inventario'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restaurar Datos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '⚠️ Advertencia: Restaurar un respaldo reemplazará todos los datos actuales. Esta acción no se puede deshacer.',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.restore),
                        label: const Text('Restaurar Respaldo'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: _isImporting ? null : _restoreBackup,
                      ),
                      if (_isImporting) const CircularProgressIndicator(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Respaldos Automáticos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Habilitar respaldos automáticos'),
                    subtitle: const Text(
                        'La aplicación creará respaldos automáticos cada día'),
                    value: true, // Esto debería conectarse a un provider real
                    onChanged: (value) {
                      // Implementar cambio de configuración
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Último respaldo automático'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(DateTime.now()), // Esto debería ser dinámico
                    ),
                    trailing:
                        const Icon(Icons.check_circle, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Aquí iría la lógica para crear un respaldo
      // Simulamos un proceso que toma tiempo
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respaldo creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear respaldo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportData(String dataType) async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Aquí iría la lógica para exportar datos
      // Simulamos un proceso que toma tiempo
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Datos de $dataType exportados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    // Mostrar diálogo de confirmación
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Restauración'),
        content: const Text(
          '¿Está seguro que desea restaurar el respaldo? Todos los datos actuales serán reemplazados y esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (shouldRestore != true) return;

    setState(() {
      _isImporting = true;
    });

    try {
      // Aquí iría la lógica para restaurar un respaldo
      // Simulamos un proceso que toma tiempo
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respaldo restaurado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al restaurar respaldo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
}

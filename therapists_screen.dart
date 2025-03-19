import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class TherapistsScreen extends ConsumerWidget {
  const TherapistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final therapistsAsync = ref.watch(usersProvider(UserRole.therapist));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Terapeutas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditTherapistDialog(context, ref),
          ),
        ],
      ),
      body: therapistsAsync.when(
        data: (therapists) {
          if (therapists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay terapeutas registrados'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir Terapeuta'),
                    onPressed: () => _showAddEditTherapistDialog(context, ref),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: therapists.length,
            itemBuilder: (context, index) {
              final therapist = therapists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      therapist.name.isNotEmpty
                          ? therapist.name.substring(0, 1)
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    therapist.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(therapist.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddEditTherapistDialog(
                            context, ref, therapist),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () =>
                            _confirmDeleteTherapist(context, ref, therapist),
                      ),
                    ],
                  ),
                  onTap: () => _showTherapistDetails(context, therapist),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Error al cargar terapeutas'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditTherapistDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditTherapistDialog(
    BuildContext context,
    WidgetRef ref, [
    UserModel? therapist,
  ]) {
    showDialog(
      context: context,
      builder: (ctx) => TherapistFormDialog(
        therapist: therapist,
        onSave: (newTherapist) async {
          try {
            if (therapist == null) {
              // Añadir nuevo terapeuta
              await ref
                  .read(authNotifierProvider.notifier)
                  .createUser(newTherapist);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terapeuta añadido correctamente'),
                  ),
                );
              }
            } else {
              // Actualizar terapeuta existente
              await ref
                  .read(authNotifierProvider.notifier)
                  .updateUser(newTherapist);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terapeuta actualizado correctamente'),
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

  void _confirmDeleteTherapist(
    BuildContext context,
    WidgetRef ref,
    UserModel therapist,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Está seguro de que desea eliminar al terapeuta "${therapist.name}"?'),
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
                    .read(authNotifierProvider.notifier)
                    .deleteUser(therapist.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Terapeuta eliminado correctamente'),
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

  void _showTherapistDetails(BuildContext context, UserModel therapist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(therapist.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(therapist.email),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Miembro desde'),
              subtitle: Text(
                '${therapist.createdAt.day}/${therapist.createdAt.month}/${therapist.createdAt.year}',
              ),
            ),
          ],
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
}

class TherapistFormDialog extends ConsumerStatefulWidget {
  final UserModel? therapist;
  final Function(UserModel) onSave;

  const TherapistFormDialog({
    super.key,
    this.therapist,
    required this.onSave,
  });

  @override
  ConsumerState<TherapistFormDialog> createState() =>
      _TherapistFormDialogState();
}

class _TherapistFormDialogState extends ConsumerState<TherapistFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isCreatingNew = true;

  @override
  void initState() {
    super.initState();
    if (widget.therapist != null) {
      _isCreatingNew = false;
      _nameController.text = widget.therapist!.name;
      _emailController.text = widget.therapist!.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final therapistModel = UserModel(
        id: widget.therapist?.id ?? '',
        name: name,
        email: email,
        role: UserRole.therapist,
        createdAt: widget.therapist?.createdAt ?? DateTime.now(),
      );

      if (_isCreatingNew && password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingrese una contraseña')),
        );
        return;
      }

      widget.onSave(therapistModel);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(_isCreatingNew ? 'Añadir Nuevo Terapeuta' : 'Editar Terapeuta'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo *',
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
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un email';
                  }
                  if (!value.contains('@')) {
                    return 'Por favor ingrese un email válido';
                  }
                  return null;
                },
              ),
              if (_isCreatingNew) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña *',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (_isCreatingNew) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese una contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                    }
                    return null;
                  },
                ),
              ],
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
}

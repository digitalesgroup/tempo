//lib/screens/clients/client_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luxe_spa_management/models/user_model.dart';

import '../../widgets/common/custom_dialog.dart';
import '../../widgets/specialized/client_form.dart';
import '../../widgets/specialized/transaction_form.dart';
import '../../providers/client_provider.dart';
import '../../models/client_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../appointments/appointment_screen.dart';
import '../../models/appointment_model.dart';
import '../../models/transaction_model.dart';
import 'package:go_router/go_router.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  bool _isSearchFocused = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(clientSearchProvider.notifier).state = value;
  }

  void _showAddClientDialog() {
    // En lugar de mostrar un diálogo, navegamos a la ruta de nuevo cliente
    context.go('/clients/new');
  }

  void _showClientDetails(ClientModel client) {
    context.goNamed(
      'client_details',
      pathParameters: {'id': client.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsState = ref.watch(filteredClientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchFocused
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar Cliente...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                onChanged: _onSearchChanged,
                autofocus: true,
                onSubmitted: (_) {
                  setState(() {
                    _isSearchFocused = false;
                  });
                },
              )
            : const Text('Clientes'),
        actions: [
          if (!_isSearchFocused)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearchFocused = true;
                });
              },
            ),
          if (_isSearchFocused)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearchFocused = false;
                  _searchController.clear();
                  _onSearchChanged('');
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/clients/new'),
          ),
        ],
      ),
      body: clientsState.when(
        data: (clients) {
          if (clients.isEmpty) {
            return const Center(
              child: Text('No se encontraron clientes'),
            );
          }

          return ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              final fullName = client.fullName;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(fullName.isNotEmpty
                        ? fullName.substring(0, 1).toUpperCase()
                        : '?'),
                  ),
                  title: Text(fullName),
                  subtitle: Text('Teléfono: ${client.contactInfo.phone}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Visitas: ${client.visitCount}'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showClientOptions(client),
                      ),
                    ],
                  ),
                  onTap: () => _showClientDetails(client),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Error al cargar clientes'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/clients/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showClientOptions(ClientModel client) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar Cliente'),
            onTap: () {
              Navigator.of(ctx).pop();
              showDialog(
                context: context,
                builder: (dialogCtx) => FullScreenDialog(
                  title: 'Editar Cliente',
                  content: ClientForm(
                    initialData: client,
                    onSave: (updatedClient) {
                      ref
                          .read(clientsNotifierProvider.notifier)
                          .updateClient(updatedClient);
                      Navigator.of(dialogCtx).pop();
                    },
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_add),
            title: const Text('Agregar Nota de Tratamiento'),
            onTap: () {
              Navigator.of(ctx).pop();
              _showAddTreatmentNoteDialog(client);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Crear Cita'),
            onTap: () {
              Navigator.of(ctx).pop();
              showDialog(
                context: context,
                builder: (dialogCtx) => FullScreenDialog(
                  title: 'Nueva Cita para ${client.fullName}',
                  content: AppointmentForm(
                    initialDate: DateTime.now(),
                    preselectedClientId: client.id, // Usar el nuevo parámetro
                    onSave: (appointment) async {
                      try {
                        // Indicador de carga
                        showDialog(
                          context: dialogCtx,
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
                                    Text('Guardando cita...'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );

                        // Guardar cita
                        await ref
                            .read(appointmentsNotifierProvider.notifier)
                            .addAppointment(appointment);

                        // Cerrar loading
                        Navigator.of(dialogCtx).pop();

                        // Cerrar formulario
                        Navigator.of(dialogCtx).pop();

                        // Mostrar mensaje de éxito
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cita creada correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        // Cerrar loading si hay error
                        Navigator.of(dialogCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al crear la cita: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment, color: Colors.green),
            title: const Text('Registrar Pago'),
            onTap: () {
              Navigator.of(ctx).pop();
              showDialog(
                context: context,
                builder: (dialogCtx) => FullScreenDialog(
                  title: 'Registrar Pago para ${client.fullName}',
                  content: TransactionForm(
                    selectedClient: client,
                    onSave: (transaction) async {
                      try {
                        // Indicador de carga
                        showDialog(
                          context: dialogCtx,
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

                        // Guardar transacción
                        final id = await ref
                            .read(transactionsNotifierProvider.notifier)
                            .addTransaction(transaction);

                        // Cerrar loading
                        Navigator.of(dialogCtx).pop();

                        // Cerrar formulario
                        Navigator.of(dialogCtx).pop();

                        // Actualizar transacciones del cliente
                        ref
                            .read(transactionsNotifierProvider.notifier)
                            .setFilters(clientId: client.id);

                        // Mostrar snack
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Pago registrado correctamente'),
                            backgroundColor: Colors.green,
                            action: SnackBarAction(
                              label: 'VER DETALLE',
                              textColor: Colors.white,
                              onPressed: () {
                                // Acciones extra si quieres
                              },
                            ),
                          ),
                        );
                      } catch (e) {
                        // Cerrar loading si hay error
                        Navigator.of(dialogCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al registrar el pago: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
          // Nuevo botón para eliminar cliente
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Eliminar Cliente',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(ctx).pop();
              _showDeleteClientConfirmation(client);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteClientConfirmation(ClientModel client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
            '¿Está seguro que desea eliminar a ${client.fullName}?\n\nEsta acción no se puede deshacer y eliminará también todas sus citas y transacciones.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              // Primero cerramos el diálogo de confirmación
              Navigator.of(ctx).pop();

              // LUEGO mostramos el indicador de carga
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Eliminando cliente...'),
                  duration: Duration(
                      seconds: 30), // Duración larga para que no desaparezca
                ),
              );

              // Ejecutamos la operación de eliminación
              ref
                  .read(databaseServiceProvider)
                  .deleteUser(client.id, UserRole.client)
                  .then((_) {
                // Al completar exitosamente

                // Escondemos el snackbar anterior
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                // Actualizamos la lista de clientes
                ref.read(clientsNotifierProvider.notifier).loadClients();

                // Mostramos mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cliente eliminado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }).catchError((e) {
                // Si hay un error

                // Escondemos el snackbar anterior
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                // Mostramos error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar cliente: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddTreatmentNoteDialog(ClientModel client) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Nota de Tratamiento'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Nota',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isNotEmpty) {
                final currentUser = await ref.read(currentUserProvider.future);

                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo identificar al usuario actual'),
                    ),
                  );
                  return;
                }

                final note = TreatmentNote(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: DateTime.now(),
                  note: noteController.text.trim(),
                  therapistId: currentUser.id,
                  therapistName: currentUser.name,
                );

                await ref
                    .read(clientsNotifierProvider.notifier)
                    .addTreatmentNote(client.id, note);

                Navigator.of(ctx).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nota agregada correctamente')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class ClientDetailView extends ConsumerWidget {
  final ClientModel client;

  const ClientDetailView({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(filteredAppointmentsProvider);
    final transactions = ref.watch(transactionsNotifierProvider);

    return DefaultTabController(
      length: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info básica
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      client.fullName.isNotEmpty
                          ? client.fullName.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.fullName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.badge,
                            'Cédula: ${client.personalInfo.idNumber}'),
                        _buildInfoRow(Icons.phone,
                            'Teléfono: ${client.contactInfo.phone}'),
                        _buildInfoRow(
                            Icons.email, 'Email: ${client.contactInfo.email}'),
                        _buildInfoRow(Icons.calendar_today,
                            'Última Visita: ${client.lastVisit.day}/${client.lastVisit.month}/${client.lastVisit.year}'),
                        _buildInfoRow(Icons.repeat,
                            'Total Visitas: ${client.visitCount}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Pestañas
          const TabBar(
            tabs: [
              Tab(text: 'Personal'),
              Tab(text: 'Médico'),
              Tab(text: 'Tratamientos'),
              Tab(text: 'Citas'),
              Tab(text: 'Pagos'),
            ],
          ),

          Expanded(
            child: TabBarView(
              children: [
                // 1) Personal
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, 'Información Personal'),
                      _buildDetailItem('Nombre',
                          '${client.personalInfo.firstName} ${client.personalInfo.lastName}'),
                      _buildDetailItem('Cédula', client.personalInfo.idNumber),
                      _buildDetailItem(
                          'Ocupación', client.personalInfo.occupation),
                      _buildDetailItem('Género', client.personalInfo.gender),
                      _buildDetailItem('Fecha de Nacimiento',
                          '${client.personalInfo.birthDate.day}/${client.personalInfo.birthDate.month}/${client.personalInfo.birthDate.year}'),
                      const SizedBox(height: 16),
                      _buildSectionTitle(context, 'Información de Contacto'),
                      _buildDetailItem(
                          'Correo Electrónico', client.contactInfo.email),
                      _buildDetailItem('Teléfono', client.contactInfo.phone),
                      _buildDetailItem('Dirección', client.contactInfo.address),
                      if (client.referredBy != null &&
                          client.referredBy!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSectionTitle(context, 'Referencias'),
                        _buildDetailItem('Referido por', client.referredBy!),
                      ],
                    ],
                  ),
                ),

                // 2) Médico
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, 'Condiciones Médicas'),
                      _buildCheckItem('Alergias', client.medicalInfo.allergies),
                      _buildCheckItem('Problemas Respiratorios',
                          client.medicalInfo.respiratory),
                      _buildCheckItem('Alteraciones Nerviosas',
                          client.medicalInfo.nervousSystem),
                      _buildCheckItem('Diabetes', client.medicalInfo.diabetes),
                      _buildCheckItem(
                          'Problemas Renales', client.medicalInfo.kidney),
                      _buildCheckItem(
                          'Problemas Digestivos', client.medicalInfo.digestive),
                      _buildCheckItem(
                          'Problemas Cardíacos', client.medicalInfo.cardiac),
                      _buildCheckItem('Tiroides', client.medicalInfo.thyroid),
                      _buildCheckItem('Cirugías Previas',
                          client.medicalInfo.previousSurgeries),
                      if (client.medicalInfo.otherConditions.isNotEmpty)
                        _buildDetailItem('Otras Condiciones',
                            client.medicalInfo.otherConditions),
                      const SizedBox(height: 16),
                      _buildSectionTitle(context, 'Historial Estético'),
                      _buildListItem('Productos Usados',
                          client.aestheticInfo.productsUsed),
                      _buildListItem('Tratamientos Actuales',
                          client.aestheticInfo.currentTreatments),
                      if (client.aestheticInfo.other.isNotEmpty)
                        _buildDetailItem('Otros', client.aestheticInfo.other),
                      const SizedBox(height: 16),
                      _buildSectionTitle(context, 'Hábitos de Vida'),
                      _buildCheckItem('Fumador', client.lifestyleInfo.smoker),
                      _buildCheckItem(
                          'Consume Alcohol', client.lifestyleInfo.alcohol),
                      _buildCheckItem('Actividad Física Regular',
                          client.lifestyleInfo.regularPhysicalActivity),
                      _buildCheckItem('Problemas de Sueño',
                          client.lifestyleInfo.sleepProblems),
                    ],
                  ),
                ),

                // 3) Tratamientos
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (client.consultationReason.isNotEmpty) ...[
                        _buildSectionTitle(context, 'Motivo de Consulta'),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(client.consultationReason),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Ficha Facial
                      _buildSectionTitle(context, 'Ficha Facial'),
                      if (client.facialTreatment.skinType.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No hay información de tratamiento facial',
                            ),
                          ),
                        )
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailItem('Tipo de Piel',
                                    client.facialTreatment.skinType),
                                _buildDetailItem('Estado de la Piel',
                                    client.facialTreatment.skinCondition),
                                _buildDetailItem(
                                    'Grado de Flacidez',
                                    client.facialTreatment.flaccidityDegree
                                        .toString()),
                                if (client.facialTreatment.facialMarks
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Diagrama Facial',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text('Diagrama Facial'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Ficha Corporal
                      _buildSectionTitle(context, 'Ficha Corporal'),
                      if (client.bodyTreatment.height == 0)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No hay información de tratamiento corporal',
                            ),
                          ),
                        )
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(context, 'Medidas (cm)'),
                                _buildDetailItem(
                                    'Abdomen Alto',
                                    client.bodyTreatment.highAbdomen
                                        .toString()),
                                _buildDetailItem('Abdomen Bajo',
                                    client.bodyTreatment.lowAbdomen.toString()),
                                _buildDetailItem('Cintura',
                                    client.bodyTreatment.waist.toString()),
                                _buildDetailItem('Espalda',
                                    client.bodyTreatment.back.toString()),
                                _buildDetailItem('Brazo Izquierdo',
                                    client.bodyTreatment.leftArm.toString()),
                                _buildDetailItem('Brazo Derecho',
                                    client.bodyTreatment.rightArm.toString()),
                                const SizedBox(height: 8),
                                _buildSectionTitle(context, 'Antropometría'),
                                _buildDetailItem('Peso (kg)',
                                    client.bodyTreatment.weight.toString()),
                                _buildDetailItem('Altura (cm)',
                                    client.bodyTreatment.height.toString()),
                                _buildDetailItem(
                                  'IMC',
                                  client.bodyTreatment.bmi.toStringAsFixed(2),
                                ),
                                const SizedBox(height: 8),
                                _buildSectionTitle(context, 'Patologías'),
                                _buildDetailItem(
                                  'Grado de Celulitis',
                                  client.bodyTreatment.cellulite.grade
                                      .toString(),
                                ),
                                _buildDetailItem(
                                  'Ubicación de Celulitis',
                                  client.bodyTreatment.cellulite.location,
                                ),
                                if (client
                                    .bodyTreatment.stretches.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Estrías',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  ...client.bodyTreatment.stretches.map(
                                    (stretch) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                          '${stretch.color} - ${stretch.duration}'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Ficha de bronceado
                      _buildSectionTitle(context, 'Ficha de Bronceado'),
                      if (client.tanningTreatment.glasgowScale == 0)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No hay información de tratamiento de bronceado',
                            ),
                          ),
                        )
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailItem(
                                  'Escala de Glasgow',
                                  client.tanningTreatment.glasgowScale
                                      .toString(),
                                ),
                                _buildDetailItem(
                                  'Escala de Fitzpatrick',
                                  client.tanningTreatment.fitzpatrickScale
                                      .toString(),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Notas de tratamiento
                      _buildSectionTitle(context, 'Notas de Tratamiento'),
                      if (client.treatmentNotes.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No hay notas de tratamiento'),
                          ),
                        )
                      else
                        ...client.treatmentNotes.map(
                          (note) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${note.date.day}/${note.date.month}/${note.date.year}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('Por: ${note.therapistName}'),
                                    ],
                                  ),
                                  const Divider(),
                                  Text(note.note),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 4) Citas
                appointments.when(
                  data: (appointmentsList) {
                    if (appointmentsList.isEmpty) {
                      return const Center(
                        child: Text('No hay citas para este cliente'),
                      );
                    }
                    return ListView.builder(
                      itemCount: appointmentsList.length,
                      itemBuilder: (context, index) {
                        final appointment = appointmentsList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              '${appointment.startTime.day}/${appointment.startTime.month}/${appointment.startTime.year} - '
                              '${appointment.startTime.hour.toString().padLeft(2, '0')}:'
                              '${appointment.startTime.minute.toString().padLeft(2, '0')}',
                            ),
                            subtitle: Text(
                                'Tratamiento: ${appointment.treatmentName}'),
                            trailing: Chip(
                              label: Text(
                                appointment.status.toString().split('.').last,
                              ),
                              backgroundColor:
                                  _getStatusColor(appointment.status),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(
                    child: Text('Error al cargar citas'),
                  ),
                ),

                // 5) Pagos
                transactions.when(
                  data: (transactionsList) {
                    if (transactionsList.isEmpty) {
                      return const Center(
                        child: Text('No hay transacciones para este cliente'),
                      );
                    }

                    final totalPaid = transactionsList
                        .where((t) => t.type == TransactionType.payment)
                        .fold<double>(0, (sum, t) => sum + t.amount);

                    return Column(
                      children: [
                        Card(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('Total Pagado'),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${totalPaid.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Transacciones'),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${transactionsList.length}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Nuevo Pago'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (dialogCtx) => FullScreenDialog(
                                      title:
                                          'Registrar Pago para ${client.fullName}',
                                      content: TransactionForm(
                                        selectedClient: client,
                                        onSave: (transaction) async {
                                          try {
                                            showDialog(
                                              context: dialogCtx,
                                              barrierDismissible: false,
                                              builder: (_) => const AlertDialog(
                                                content: SizedBox(
                                                  height: 100,
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        CircularProgressIndicator(),
                                                        SizedBox(height: 16),
                                                        Text(
                                                          'Procesando pago...',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );

                                            await ref
                                                .read(
                                                    transactionsNotifierProvider
                                                        .notifier)
                                                .addTransaction(transaction);

                                            Navigator.of(dialogCtx).pop();
                                            Navigator.of(dialogCtx).pop();

                                            ref
                                                .read(
                                                    transactionsNotifierProvider
                                                        .notifier)
                                                .setFilters(
                                                    clientId: client.id);

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Pago registrado correctamente',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } catch (e) {
                                            Navigator.of(dialogCtx).pop();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Error al registrar el pago: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 24),
                        Expanded(
                          child: ListView.builder(
                            itemCount: transactionsList.length,
                            itemBuilder: (context, index) {
                              final transaction = transactionsList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(
                                    '${transaction.date.day}/'
                                    '${transaction.date.month}/'
                                    '${transaction.date.year} - '
                                    '${transaction.type.toString().split('.').last}',
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Método: '
                                        '${transaction.paymentMethod.toString().split('.').last}',
                                      ),
                                      if (transaction.notes.isNotEmpty)
                                        Text('Nota: ${transaction.notes}'),
                                      if (transaction.pendingAmount > 0)
                                        Text(
                                          'Pendiente: \$${transaction.pendingAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '\$${transaction.amount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: transaction.type ==
                                                      TransactionType.payment
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Por: ${transaction.staffName}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (transaction.pendingAmount > 0)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.payment,
                                            color: Colors.orange,
                                          ),
                                          tooltip: 'Registrar pago parcial',
                                          onPressed: () {
                                            // Aquí usarías un PartialPaymentForm
                                          },
                                        ),
                                    ],
                                  ),
                                  isThreeLine: transaction.notes.isNotEmpty ||
                                      transaction.pendingAmount > 0,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(
                    child: Text('Error al cargar transacciones'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_box : Icons.check_box_outline_blank,
            color: value ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildListItem(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        if (items.isEmpty)
          const Text('Ninguno')
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 2),
              child: Text('• $item'),
            ),
          ),
      ],
    );
  }

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
}

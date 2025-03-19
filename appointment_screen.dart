// lib/screens/appointments/appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/appointment_model.dart';
import '../../widgets/specialized/appointment_calendar.dart';
import '../../widgets/common/custom_dialog.dart';
import '../../models/user_model.dart';
import '../../models/treatment_model.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();

    // Inicializar el filtro con la fecha actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appointmentsNotifierProvider.notifier).setDateRange(
            DateTime(_focusedDay.year, _focusedDay.month, 1),
            DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59),
          );
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });

    // Actualizar el filtro cuando cambia el mes
    ref.read(appointmentsNotifierProvider.notifier).setDateRange(
          DateTime(focusedDay.year, focusedDay.month, 1),
          DateTime(focusedDay.year, focusedDay.month + 1, 0, 23, 59, 59),
        );
  }

  void _navigateToNewAppointment() {
    // Formatear la fecha seleccionada para incluirla en la URL
    final dateStr = _selectedDay.toIso8601String();
    context.go('/appointments/new?date=$dateStr');
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (ctx) => AppointmentDetailDialog(
        appointment: appointment,
        onUpdate: (updatedAppointment) async {
          try {
            await ref
                .read(appointmentsNotifierProvider.notifier)
                .updateAppointment(updatedAppointment);
            if (mounted) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cita actualizada exitosamente')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          }
        },
        onDelete: (id) async {
          try {
            await ref
                .read(appointmentsNotifierProvider.notifier)
                .deleteAppointment(id);
            if (mounted) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cita eliminada exitosamente')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsState = ref.watch(appointmentsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Citas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToNewAppointment,
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendario
          AppointmentCalendar(
            selectedDay: _selectedDay,
            focusedDay: _focusedDay,
            appointments: appointmentsState.value ?? [],
            onDaySelected: _onDaySelected,
            onPageChanged: _onPageChanged,
          ),

          const Divider(),

          // Lista de citas del día seleccionado
          Expanded(
            child: appointmentsState.when(
              data: (appointments) {
                // Filtrar citas para el día seleccionado
                final dayAppointments = appointments
                    .where((a) => isSameDay(a.startTime, _selectedDay))
                    .toList();

                if (dayAppointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No hay citas para este día'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Agendar Cita'),
                          onPressed: _navigateToNewAppointment,
                        ),
                      ],
                    ),
                  );
                }

                // Ordenar citas por hora de inicio
                dayAppointments
                    .sort((a, b) => a.startTime.compareTo(b.startTime));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = dayAppointments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _showAppointmentDetails(appointment),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')} - ${appointment.endTime.hour.toString().padLeft(2, '0')}:${appointment.endTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Chip(
                                    label: Text(appointment.status
                                        .toString()
                                        .split('.')
                                        .last),
                                    backgroundColor:
                                        _getStatusColor(appointment.status),
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  const Icon(Icons.person),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cliente: ${appointment.clientName}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.spa),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tratamiento: ${appointment.treatmentName}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person_pin),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Terapeuta: ${appointment.therapistName}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Precio: \$${appointment.price.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Spacer(),
                                  appointment.isPaid
                                      ? const Chip(
                                          label: Text('Pagado'),
                                          backgroundColor: Colors.green,
                                          labelStyle:
                                              TextStyle(color: Colors.white),
                                        )
                                      : const Chip(
                                          label: Text('Pendiente'),
                                          backgroundColor: Colors.orange,
                                          labelStyle:
                                              TextStyle(color: Colors.white),
                                        ),
                                ],
                              ),
                              if (appointment.notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Notas:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(appointment.notes),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Text('Error al cargar citas'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewAppointment,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final filters = ref.read(appointmentFilterProvider);
    String? clientId = filters['clientId'];
    String? therapistId = filters['therapistId'];
    AppointmentStatus? status = filters['status'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtrar Citas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Aquí iría el formulario de filtros
            // Implementación simplificada
            DropdownButtonFormField<AppointmentStatus?>(
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              value: status,
              onChanged: (value) {
                status = value;
              },
              items: [
                const DropdownMenuItem<AppointmentStatus?>(
                  value: null,
                  child: Text('Todos'),
                ),
                ...AppointmentStatus.values.map(
                  (s) => DropdownMenuItem<AppointmentStatus?>(
                    value: s,
                    child: Text(s.toString().split('.').last),
                  ),
                ),
              ],
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
              ref.read(appointmentFilterProvider.notifier).state = {
                ...filters,
                'status': status,
              };
              Navigator.of(ctx).pop();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
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

// Clase para formulario de citas
class AppointmentForm extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final AppointmentModel? initialData;
  final Function(AppointmentModel) onSave;
  final String? preselectedClientId; // Añadido el nuevo parámetro

  const AppointmentForm({
    super.key,
    required this.initialDate,
    this.initialData,
    required this.onSave,
    this.preselectedClientId, // Añadido a la lista de parámetros
  });

  @override
  ConsumerState<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends ConsumerState<AppointmentForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late int _duration;
  String? _selectedClientId;
  String? _selectedTherapistId;
  String? _selectedTreatmentId;
  double _price = 0;

  @override
  void initState() {
    super.initState();

    // Inicializar con fecha válida (nunca antes que hoy)
    final now = DateTime.now();
    if (widget.initialData?.startTime != null) {
      _startDate = widget.initialData!.startTime;
      if (_startDate.isBefore(now)) {
        _startDate = now;
      }
    } else {
      _startDate = widget.initialDate;
      if (_startDate.isBefore(now)) {
        _startDate = now;
      }
    }

    _startTime = TimeOfDay.fromDateTime(_startDate);
    _duration = widget.initialData?.durationInMinutes ?? 60;

    // Priorizar el ID del initialData, si existe
    _selectedClientId = widget.initialData?.clientId;

    // Si no hay ID en initialData pero hay un preselectedClientId, usarlo
    if ((_selectedClientId == null || _selectedClientId!.isEmpty) &&
        widget.preselectedClientId != null &&
        widget.preselectedClientId!.isNotEmpty) {
      _selectedClientId = widget.preselectedClientId;
    }

    _selectedTherapistId = widget.initialData?.therapistId;
    _selectedTreatmentId = widget.initialData?.treatmentId;
    _price = widget.initialData?.price ?? 0;
  }

  DateTime _calculateEndTime() {
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    return startDateTime.add(Duration(minutes: _duration));
  }

  void _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      // Obtener datos del formulario
      final notes = _formKey.currentState!.value['notes'] as String? ?? '';

      // Verificar campos obligatorios
      if (_selectedClientId == null ||
          _selectedTherapistId == null ||
          _selectedTreatmentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Por favor complete todos los campos obligatorios')),
        );
        return;
      }

      // Construir el objeto de cita
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      // Necesitamos obtener nombres para el cliente, terapeuta y tratamiento
      String clientName = '';
      String therapistName = '';
      String treatmentName = '';

      try {
        // Obtener cliente
        final client =
            await ref.read(clientProvider(_selectedClientId!).future);
        if (client != null) {
          clientName = client.fullName;
        }

        // Obtener terapeuta
        final users = await ref
            .read(authServiceProvider)
            .getUsers(role: UserRole.therapist);
        final therapist = users.firstWhere((u) => u.id == _selectedTherapistId,
            orElse: () => UserModel(
                  id: '',
                  email: '',
                  name: '',
                  role: UserRole.therapist,
                  createdAt: DateTime.now(),
                ));
        therapistName = therapist.name;

        // Obtener tratamiento
        final treatments = await ref.read(treatmentsProvider.future);
        final treatment =
            treatments.firstWhere((t) => t.id == _selectedTreatmentId,
                orElse: () => TreatmentModel(
                      id: '',
                      name: '',
                      description: '',
                      type: TreatmentType.other,
                      duration: 60,
                      price: 0,
                    ));
        treatmentName = treatment.name;

        // Usar el ID existente o vacío para una nueva cita
        final String appointmentId = widget.initialData?.id ?? '';

        final appointment = AppointmentModel(
          id: appointmentId,
          clientId: _selectedClientId!,
          clientName: clientName,
          therapistId: _selectedTherapistId!,
          therapistName: therapistName,
          treatmentId: _selectedTreatmentId!,
          treatmentName: treatmentName,
          startTime: startDateTime,
          endTime: _calculateEndTime(),
          status: widget.initialData?.status ?? AppointmentStatus.scheduled,
          price: _price,
          notes: notes,
          isPaid: widget.initialData?.isPaid ?? false,
          paymentId: widget.initialData?.paymentId,
        );

        widget.onSave(appointment);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _updatePrice(String treatmentId) async {
    try {
      final treatments = await ref.read(treatmentsProvider.future);
      final treatment = treatments.firstWhere(
        (t) => t.id == treatmentId,
        orElse: () => TreatmentModel(
          id: '',
          name: '',
          description: '',
          type: TreatmentType.other,
          duration: 60,
          price: 0,
        ),
      );

      setState(() {
        _price = treatment.price;
        _duration = treatment.duration;

        // Actualiza también el valor del campo de texto manualmente
        // Necesitamos asegurarnos de que _formKey y su estado estén inicializados
        if (_formKey.currentState != null) {
          _formKey.currentState!.fields['price']?.didChange(_price.toString());
        }
      });
    } catch (e) {
      // Manejar error
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final therapists =
        ref.watch(authServiceProvider).getUsers(role: UserRole.therapist);
    final treatments = ref.watch(treatmentsProvider);

    return FormBuilder(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de fecha y hora
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha y Hora',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final DateTime now = DateTime.now();
                              final DateTime firstDate =
                                  now; // Usar la fecha actual como primera fecha

                              // Asegurarnos que la fecha inicial no sea anterior a la fecha mínima
                              DateTime initialPickDate = _startDate;
                              if (initialPickDate.isBefore(firstDate)) {
                                initialPickDate = firstDate;
                              }

                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: initialPickDate,
                                firstDate: firstDate,
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );

                              if (pickedDate != null) {
                                setState(() {
                                  _startDate = pickedDate;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_startDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: _startTime,
                              );
                              if (pickedTime != null) {
                                setState(() {
                                  _startTime = pickedTime;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Hora de Inicio',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(
                                _startTime.format(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Duración (minutos)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timer),
                            ),
                            child: Text('$_duration min'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hora de Fin',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(
                              TimeOfDay.fromDateTime(_calculateEndTime())
                                  .format(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sección de cliente y terapeuta
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    clients.when(
                      data: (clientsList) {
                        // Verificar si _selectedClientId existe en la lista
                        if (_selectedClientId != null &&
                            _selectedClientId!.isNotEmpty) {
                          final clientExists =
                              clientsList.any((c) => c.id == _selectedClientId);
                          if (!clientExists) {
                            // Si no existe, resetearlo para evitar errores en el dropdown
                            _selectedClientId = null;
                          }
                        }

                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Cliente *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          value: _selectedClientId,
                          hint: const Text('Seleccione un cliente'),
                          onChanged: (value) {
                            setState(() {
                              _selectedClientId = value;
                            });
                          },
                          items: clientsList
                              .map(
                                (client) => DropdownMenuItem<String>(
                                  value: client.id,
                                  child: Text(client.fullName),
                                ),
                              )
                              .toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor seleccione un cliente';
                            }
                            return null;
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error al cargar clientes'),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<UserModel>>(
                      future: therapists,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          return const Text('Error al cargar terapeutas');
                        }

                        final therapistsList = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Terapeuta *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_pin),
                          ),
                          value: _selectedTherapistId,
                          hint: const Text('Seleccione un terapeuta'),
                          onChanged: (value) {
                            setState(() {
                              _selectedTherapistId = value;
                            });
                          },
                          items: therapistsList
                              .map(
                                (therapist) => DropdownMenuItem<String>(
                                  value: therapist.id,
                                  child: Text(therapist.name),
                                ),
                              )
                              .toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor seleccione un terapeuta';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sección de tratamiento
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tratamiento y Precio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    treatments.when(
                      data: (treatmentsList) {
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Tratamiento *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.spa),
                          ),
                          value: _selectedTreatmentId,
                          hint: const Text('Seleccione un tratamiento'),
                          onChanged: (value) {
                            setState(() {
                              _selectedTreatmentId = value;
                            });
                            if (value != null) {
                              _updatePrice(value);
                            }
                          },
                          items: treatmentsList
                              .map(
                                (treatment) => DropdownMenuItem<String>(
                                  value: treatment.id,
                                  child: Text(
                                      '${treatment.name} (${treatment.duration} min)'),
                                ),
                              )
                              .toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor seleccione un tratamiento';
                            }
                            return null;
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) =>
                          const Text('Error al cargar tratamientos'),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'price',
                      initialValue: _price.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Precio *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        helperText: 'Puedes modificar manualmente este precio',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value != null && value.isNotEmpty) {
                          setState(() {
                            _price = double.tryParse(value) ?? _price;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un precio';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor ingrese un número válido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sección de notas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'notes',
                      initialValue: widget.initialData?.notes,
                      decoration: const InputDecoration(
                        labelText: 'Notas Adicionales',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Guardar Cita'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clase para diálogo de detalles de cita
class AppointmentDetailDialog extends ConsumerWidget {
  final AppointmentModel appointment;
  final Function(AppointmentModel) onUpdate;
  final Function(String) onDelete;

  const AppointmentDetailDialog({
    super.key,
    required this.appointment,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Detalles de la Cita'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hora y estado
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time),
                              const SizedBox(width: 8),
                              Text(
                                '${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')} - ${appointment.endTime.hour.toString().padLeft(2, '0')}:${appointment.endTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Chip(
                            label: Text(
                                appointment.status.toString().split('.').last),
                            backgroundColor:
                                _getStatusColor(appointment.status),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 8),
                          Text(
                            '${appointment.startTime.day}/${appointment.startTime.month}/${appointment.startTime.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Información del cliente y terapeuta
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person),
                          const SizedBox(width: 8),
                          const Text(
                            'Cliente: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            appointment.clientName,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_pin),
                          const SizedBox(width: 8),
                          const Text(
                            'Terapeuta: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            appointment.therapistName,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Información del tratamiento y precio
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.spa),
                          const SizedBox(width: 8),
                          const Text(
                            'Tratamiento: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            appointment.treatmentName,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_money),
                          const SizedBox(width: 8),
                          const Text(
                            'Precio: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '\$${appointment.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          appointment.isPaid
                              ? const Chip(
                                  label: Text('Pagado'),
                                  backgroundColor: Colors.green,
                                  labelStyle: TextStyle(color: Colors.white),
                                )
                              : const Chip(
                                  label: Text('Pendiente'),
                                  backgroundColor: Colors.orange,
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (appointment.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notas:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(appointment.notes),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Acciones disponibles según el estado
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Acciones',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (appointment.status ==
                              AppointmentStatus.scheduled) ...[
                            ActionChip(
                              label: const Text('Confirmar'),
                              backgroundColor: Colors.green,
                              labelStyle: const TextStyle(color: Colors.white),
                              onPressed: () => _updateStatus(
                                  context, AppointmentStatus.confirmed),
                            ),
                            ActionChip(
                              label: const Text('Cancelar'),
                              backgroundColor: Colors.red,
                              labelStyle: const TextStyle(color: Colors.white),
                              onPressed: () => _updateStatus(
                                  context, AppointmentStatus.cancelled),
                            ),
                          ],
                          if (appointment.status ==
                              AppointmentStatus.confirmed) ...[
                            ActionChip(
                              label: const Text('En Progreso'),
                              backgroundColor: Colors.amber,
                              labelStyle: const TextStyle(color: Colors.white),
                              onPressed: () => _updateStatus(
                                  context, AppointmentStatus.inProgress),
                            ),
                            ActionChip(
                              label: const Text('Cancelar'),
                              backgroundColor: Colors.red,
                              labelStyle: const TextStyle(color: Colors.white),
                              onPressed: () => _updateStatus(
                                  context, AppointmentStatus.cancelled),
                            ),
                          ],
                          if (appointment.status ==
                              AppointmentStatus.inProgress) ...[
                            ActionChip(
                              label: const Text('Completar'),
                              backgroundColor: Colors.teal,
                              labelStyle: const TextStyle(color: Colors.white),
                              onPressed: () => _updateStatus(
                                  context, AppointmentStatus.completed),
                            ),
                          ],
                          if (!appointment.isPaid) ...[
                            ActionChip(
                              label: const Text('Registrar Pago'),
                              backgroundColor: Colors.blue,
                              labelStyle: const TextStyle(color: Colors.white),
                              onPressed: () =>
                                  _showRegisterPaymentDialog(context),
                            ),
                          ],
                          ActionChip(
                            label: const Text('Editar'),
                            backgroundColor: Colors.purple,
                            labelStyle: const TextStyle(color: Colors.white),
                            onPressed: () => _showEditDialog(context),
                          ),
                          if (appointment.status !=
                              AppointmentStatus.completed) ...[
                            ActionChip(
                              label: const Text('Eliminar'),
                              backgroundColor: Colors.deepOrange,
                              labelStyle: const TextStyle(color: Colors.white),
                              onPressed: () => _confirmDelete(context),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  void _updateStatus(BuildContext context, AppointmentStatus newStatus) {
    final updatedAppointment = appointment.copyWith(
      status: newStatus,
      id: appointment.id,
    );
    onUpdate(updatedAppointment);
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => FullScreenDialog(
        title: 'Editar Cita',
        content: AppointmentForm(
          initialDate: appointment.startTime,
          initialData: appointment,
          onSave: onUpdate,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
            '¿Está seguro de que desea eliminar esta cita? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete(appointment.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showRegisterPaymentDialog(BuildContext context) {
    // Aquí iría la lógica para registrar un pago
    // Implementación simplificada
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: const Text(
            'Esta funcionalidad estaría vinculada con el módulo de gestión financiera.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
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

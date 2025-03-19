// lib/router/go_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luxe_spa_management/providers/appointment_provider.dart';
import 'package:luxe_spa_management/providers/client_provider.dart';
import 'package:luxe_spa_management/providers/transaction_provider.dart';
import '../providers/auth_provider.dart';

import '../screens/auth/auth_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/clients/client_screen.dart';
import '../screens/appointments/appointment_screen.dart';
import '../screens/finances/finance_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/treatments/treatments_screen.dart';
import '../screens/users/therapists_screen.dart';
import '../widgets/common/dashboard_layout.dart';
import '../models/client_model.dart';
import '../services/database_service.dart';
import '../widgets/specialized/client_form.dart';

import '../models/appointment_model.dart';

// Proveedor para el router que depende del estado de autenticación
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true, // Activa esto para depuración

    // Redirección basada en estado de autenticación
    redirect: (context, state) {
      // Obtener el estado de autenticación y la ruta actual
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/';

      // Lógica de redirección
      if (!isLoggedIn && !isAuthRoute) {
        // Si no está autenticado y no está en la ruta de auth, redirigir a auth
        return '/';
      }

      if (isLoggedIn && isAuthRoute) {
        // Si está autenticado y está en la ruta de auth, redirigir a dashboard
        return '/dashboard';
      }

      // En otros casos, no redirigir
      return null;
    },

    routes: [
      // Ruta de autenticación
      GoRoute(
        path: '/',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),

      // Rutas protegidas con el layout de dashboard
      ShellRoute(
        builder: (context, state, child) {
          // Este builder se ejecuta para todas las rutas dentro del ShellRoute
          return DashboardLayout(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => DashboardScreen(),
          ),
          GoRoute(
            path: '/clients',
            name: 'clients',
            builder: (context, state) => const ClientsScreen(),
          ),
          // IMPORTANTE: La ruta específica debe ir ANTES de la ruta con parámetro
          GoRoute(
            path: '/clients/new',
            name: 'new_client',
            builder: (context, state) => const NewClientPage(),
          ),
          // Detalles de cliente con ID
          GoRoute(
            path: '/clients/:id',
            name: 'client_details',
            builder: (context, state) {
              final clientId = state.pathParameters['id']!;
              return ClientDetailPage(clientId: clientId);
            },
          ),
          GoRoute(
            path: '/appointments',
            name: 'appointments',
            builder: (context, state) => const AppointmentsScreen(),
          ),
          // Nueva ruta para crear citas
          GoRoute(
            path: '/appointments/new',
            name: 'new_appointment',
            builder: (context, state) {
              // Obtener la fecha seleccionada de los parámetros de la URL si existe
              final selectedDateStr = state.uri.queryParameters['date'];
              final selectedDate = selectedDateStr != null
                  ? DateTime.parse(selectedDateStr)
                  : DateTime.now();
              return NewAppointmentPage(selectedDate: selectedDate);
            },
          ),
          GoRoute(
            path: '/treatments',
            name: 'treatments',
            builder: (context, state) => const TreatmentsScreen(),
          ),
          GoRoute(
            path: '/therapists',
            name: 'therapists',
            builder: (context, state) => const TherapistsScreen(),
          ),
          GoRoute(
            path: '/finances',
            name: 'finances',
            builder: (context, state) => const FinancesScreen(),
          ),
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],

    // Manejo de errores de navegación
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: Ruta no encontrada ${state.uri.path}'),
      ),
    ),
  );
});

// Instancia global del router para uso directo sin Riverpod
// Esta es la variable que estás importando en app.dart
final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    // Ruta de autenticación
    GoRoute(
      path: '/',
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),

    // Rutas con el layout de dashboard
    ShellRoute(
      builder: (context, state, child) {
        return DashboardLayout(
          currentRoute: state.matchedLocation,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => DashboardScreen(),
        ),
        GoRoute(
          path: '/clients',
          name: 'clients',
          builder: (context, state) => const ClientsScreen(),
        ),
        // IMPORTANTE: La ruta específica debe ir ANTES de la ruta con parámetro
        GoRoute(
          path: '/clients/new',
          name: 'new_client',
          builder: (context, state) => const NewClientPage(),
        ),
        // Detalles de cliente con ID
        GoRoute(
          path: '/clients/:id',
          name: 'client_details',
          builder: (context, state) {
            final clientId = state.pathParameters['id']!;
            return ClientDetailPage(clientId: clientId);
          },
        ),
        GoRoute(
          path: '/appointments',
          name: 'appointments',
          builder: (context, state) => const AppointmentsScreen(),
        ),
        // Nueva ruta para crear citas
        GoRoute(
          path: '/appointments/new',
          name: 'new_appointment',
          builder: (context, state) {
            // Obtener la fecha seleccionada de los parámetros de la URL si existe
            final selectedDateStr = state.uri.queryParameters['date'];
            final selectedDate = selectedDateStr != null
                ? DateTime.parse(selectedDateStr)
                : DateTime.now();
            return NewAppointmentPage(selectedDate: selectedDate);
          },
        ),
        GoRoute(
          path: '/treatments',
          name: 'treatments',
          builder: (context, state) => const TreatmentsScreen(),
        ),
        GoRoute(
          path: '/therapists',
          name: 'therapists',
          builder: (context, state) => const TherapistsScreen(),
        ),
        GoRoute(
          path: '/finances',
          name: 'finances',
          builder: (context, state) => const FinancesScreen(),
        ),
        GoRoute(
          path: '/inventory',
          name: 'inventory',
          builder: (context, state) => const InventoryScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Error: Ruta no encontrada ${state.uri.path}'),
    ),
  ),
);

// Nueva página para los detalles del cliente
class ClientDetailPage extends ConsumerStatefulWidget {
  final String clientId;

  const ClientDetailPage({Key? key, required this.clientId}) : super(key: key);

  @override
  ConsumerState<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends ConsumerState<ClientDetailPage> {
  @override
  void initState() {
    super.initState();
    // Configurar filtros para citas y transacciones cuando se inicia la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appointmentFilterProvider.notifier).state = {
        'clientId': widget.clientId,
        'startDate': null,
        'endDate': null,
        'therapistId': null,
        'status': null,
      };

      ref.read(transactionsNotifierProvider.notifier).setFilters(
            clientId: widget.clientId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClientModel?>(
      future: DatabaseService().getClient(widget.clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cliente')),
            body: const Center(child: Text('Cliente no encontrado')),
          );
        }

        final client = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(client.fullName),
            // Añadir botón de retroceso
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Regresar a la lista de clientes
                context.go('/clients');
              },
            ),
          ),
          body: ClientDetailView(client: client),
        );
      },
    );
  }
}

// Nueva página para crear un nuevo cliente
class NewClientPage extends ConsumerWidget {
  const NewClientPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Cliente'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/clients'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ClientForm(
          onSave: (client) {
            ref.read(clientsNotifierProvider.notifier).addClient(client);
            context
                .go('/clients'); // Navegamos de vuelta a la lista de clientes
          },
        ),
      ),
    );
  }
}

// Nueva página para crear una nueva cita
// Nueva página para crear una nueva cita
class NewAppointmentPage extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const NewAppointmentPage({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  ConsumerState<NewAppointmentPage> createState() => _NewAppointmentPageState();
}

class _NewAppointmentPageState extends ConsumerState<NewAppointmentPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cita'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/appointments'),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppointmentForm(
              initialDate: widget.selectedDate,
              onSave: _handleSaveAppointment,
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Guardando cita...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleSaveAppointment(AppointmentModel appointment) async {
    try {
      // Mostrar indicador de carga
      setState(() {
        _isLoading = true;
      });

      // Guardar la cita
      await ref
          .read(appointmentsNotifierProvider.notifier)
          .addAppointment(appointment);

      // Verificar si el widget aún está montado antes de proceder
      if (!mounted) return;

      // Ocultar la carga
      setState(() {
        _isLoading = false;
      });

      // Usar un pequeño retraso para asegurar que la UI se actualice
      Future.delayed(Duration.zero, () {
        if (mounted) {
          // Navegar de vuelta a la lista de citas
          context.go('/appointments');

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } catch (e) {
      // Ocultar indicador de carga en caso de error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la cita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

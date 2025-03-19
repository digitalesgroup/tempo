// lib/providers/client_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/client_model.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final clientsProvider = FutureProvider<List<ClientModel>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getClients();
});

final clientProvider =
    FutureProvider.family<ClientModel?, String>((ref, id) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getClient(id);
});

final clientSearchProvider = StateProvider<String>((ref) => '');

final filteredClientsProvider = Provider<AsyncValue<List<ClientModel>>>((ref) {
  final clientsAsync = ref.watch(clientsProvider);
  final searchQuery = ref.watch(clientSearchProvider).toLowerCase();

  return clientsAsync.when(
    data: (clients) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(clients);
      }

      return AsyncValue.data(clients.where((client) {
        final fullName = client.personalInfo.firstName.toLowerCase() +
            ' ' +
            client.personalInfo.lastName.toLowerCase();
        final idNumber = client.personalInfo.idNumber.toLowerCase();
        final email = client.contactInfo.email.toLowerCase();
        final phone = client.contactInfo.phone.toLowerCase();

        return fullName.contains(searchQuery) ||
            idNumber.contains(searchQuery) ||
            email.contains(searchQuery) ||
            phone.contains(searchQuery);
      }).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

class ClientsNotifier extends StateNotifier<AsyncValue<List<ClientModel>>> {
  final DatabaseService _dbService;

  ClientsNotifier(this._dbService) : super(const AsyncValue.loading()) {
    loadClients();
  }

  Future<void> loadClients() async {
    state = const AsyncValue.loading();
    try {
      final clients = await _dbService.getClients();
      state = AsyncValue.data(clients);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String> addClient(ClientModel client) async {
    try {
      final id = await _dbService.addClient(client);
      loadClients(); // Refrescar la lista
      return id;
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateClient(ClientModel client) async {
    try {
      await _dbService.updateClient(client);
      loadClients(); // Refrescar la lista
    } catch (e) {
      throw e;
    }
  }

  Future<void> addTreatmentNote(String clientId, TreatmentNote note) async {
    try {
      await _dbService.addTreatmentNote(clientId, note);
      loadClients(); // Refrescar la lista
    } catch (e) {
      throw e;
    }
  }
}

final clientsNotifierProvider =
    StateNotifierProvider<ClientsNotifier, AsyncValue<List<ClientModel>>>(
        (ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ClientsNotifier(dbService);
});

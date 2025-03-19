// lib/providers/treatment_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/treatment_model.dart';
import 'client_provider.dart';

final treatmentsProvider = FutureProvider<List<TreatmentModel>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getTreatments();
});

final treatmentsByTypeProvider =
    FutureProvider.family<List<TreatmentModel>, TreatmentType>(
        (ref, type) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getTreatments(type: type);
});

final activeTreatmentsProvider =
    Provider<AsyncValue<List<TreatmentModel>>>((ref) {
  final treatmentsAsync = ref.watch(treatmentsProvider);

  return treatmentsAsync.when(
    data: (treatments) {
      return AsyncValue.data(treatments.where((t) => t.isActive).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

class TreatmentsNotifier
    extends StateNotifier<AsyncValue<List<TreatmentModel>>> {
  final DatabaseService _dbService;

  TreatmentsNotifier(this._dbService) : super(const AsyncValue.loading()) {
    loadTreatments();
  }

  Future<void> loadTreatments() async {
    state = const AsyncValue.loading();
    try {
      final treatments = await _dbService.getTreatments();
      state = AsyncValue.data(treatments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String> addTreatment(TreatmentModel treatment) async {
    try {
      final id = await _dbService.addTreatment(treatment);
      loadTreatments();
      return id;
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateTreatment(TreatmentModel treatment) async {
    try {
      await _dbService.updateTreatment(treatment);
      loadTreatments();
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteTreatment(String id) async {
    try {
      await _dbService.deleteTreatment(id);
      loadTreatments();
    } catch (e) {
      throw e;
    }
  }

  Future<void> toggleTreatmentStatus(String id) async {
    try {
      final treatments = state.value ?? [];
      final treatment = treatments.firstWhere((t) => t.id == id);
      final updatedTreatment = TreatmentModel(
        id: treatment.id,
        name: treatment.name,
        description: treatment.description,
        type: treatment.type,
        duration: treatment.duration,
        price: treatment.price,
        requiredProducts: treatment.requiredProducts,
        isActive: !treatment.isActive,
      );

      await _dbService.updateTreatment(updatedTreatment);
      loadTreatments();
    } catch (e) {
      throw e;
    }
  }
}

final treatmentsNotifierProvider =
    StateNotifierProvider<TreatmentsNotifier, AsyncValue<List<TreatmentModel>>>(
        (ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return TreatmentsNotifier(dbService);
});

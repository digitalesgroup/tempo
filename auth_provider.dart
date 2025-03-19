// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUser();
});

final userRoleProvider = FutureProvider<UserRole>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUserRole();
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isCurrentUserAdmin();
});

// Provider para obtener usuarios por rol
final usersProvider =
    FutureProvider.family<List<UserModel>, UserRole>((ref, role) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getUsers(role: role);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithEmail(email, password);
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signUp(
      String email, String password, String name, UserRole role) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signUp(email, password, name, role);
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      throw e;
    }
  }

  // Métodos para la gestión de usuarios/terapeutas
  Future<void> createUser(UserModel user, [String? password]) async {
    try {
      await _authService.createUser(user, password ?? 'Password123!');
      // No actualizamos el estado porque esto no afecta al usuario actual
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _authService.updateUser(user);
      // Si estamos actualizando al usuario actual, actualizamos el estado
      final currentUser = state.value;
      if (currentUser != null && currentUser.id == user.id) {
        state = AsyncValue.data(user);
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _authService.deleteUser(userId);
      // Si eliminamos al usuario actual, cerramos la sesión
      final currentUser = state.value;
      if (currentUser != null && currentUser.id == userId) {
        await signOut();
      }
    } catch (e) {
      throw e;
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

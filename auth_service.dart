// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error en signIn: $e');
      throw e;
    }
  }

  Future<void> signUp(
      String email, String password, String name, UserRole role) async {
    try {
      // 1. Crear usuario en Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // 2. Guardar en la colección correcta según el rol
        final uid = userCredential.user!.uid;
        final userData = {
          'email': email,
          'name': name,
          'role': role.toString(),
          'createdAt': Timestamp.now(),
          'isActive': true,
        };

        // Guardar en colección de usuarios (general)
        await _firestore.collection('users').doc(uid).set(userData);

        // Guardar en colección específica según rol
        String collectionName;
        switch (role) {
          case UserRole.admin:
            collectionName = 'administrators';
            break;
          case UserRole.therapist:
            collectionName = 'therapists';
            // Para terapeutas, necesitamos información adicional
            final therapistData = {
              ...userData,
              'specialization': '',
              'services': [],
              'schedule': '',
            };
            await _firestore
                .collection(collectionName)
                .doc(uid)
                .set(therapistData);
            break;
          case UserRole.client:
          default:
            collectionName = 'clients';
            // Para clientes, crear también documento en la colección client_details
            await _firestore.collection('client_details').doc(uid).set({
              'userId': uid,
              'personalInfo': {
                'firstName': name,
                'lastName': '',
                'idNumber': '',
                'occupation': '',
                'gender': '',
                'birthDate': Timestamp.now(),
              },
              'contactInfo': {
                'email': email,
                'phone': '',
                'address': '',
              },
              'medicalInfo': {},
              'aestheticInfo': {},
              'lifestyleInfo': {},
              'consultationReason': '',
              'facialTreatment': {},
              'bodyTreatment': {},
              'tanningTreatment': {},
              'preferredTreatments': [],
              'lastVisit': Timestamp.now(),
              'visitCount': 0,
              'treatmentNotes': [],
            });
            await _firestore.collection(collectionName).doc(uid).set(userData);
            break;
        }

        print('Usuario creado exitosamente: $uid en colección $collectionName');
      }
    } catch (e) {
      print('Error en signUp: $e');
      throw e;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error en signOut: $e');
      throw e;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error en resetPassword: $e');
      throw e;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error en getCurrentUser: $e');
      return null;
    }
  }

  Future<UserRole> getCurrentUserRole() async {
    try {
      final user = await getCurrentUser();
      return user?.role ?? UserRole.client;
    } catch (e) {
      print('Error en getCurrentUserRole: $e');
      return UserRole.client;
    }
  }

  // Método para verificar si el usuario actual es administrador
  Future<bool> isCurrentUserAdmin() async {
    final role = await getCurrentUserRole();
    return role == UserRole.admin;
  }

  // Implementación del método para obtener usuarios por rol
  Future<List<UserModel>> getUsers({required UserRole role}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role.toString())
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error en getUsers: $e');
      throw e;
    }
  }

  // Método para crear un nuevo usuario
  Future<void> createUser(UserModel user, [String? password]) async {
    try {
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password ?? 'Password123!',
      );

      // Crear documento de usuario en Firestore con el ID generado por Auth
      final userWithId = UserModel(
        id: userCredential.user!.uid,
        email: user.email,
        name: user.name,
        role: user.role,
        createdAt: DateTime.now(),
      );

      final userData = userWithId.toFirestore();

      // Guardar en colección de usuarios (general)
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      // Si es un terapeuta, añadir también en la colección de therapists
      if (user.role == UserRole.therapist) {
        final therapistData = {
          ...userData,
          'specialization': '',
          'services': [],
          'schedule': '',
        };

        await _firestore
            .collection('therapists')
            .doc(userCredential.user!.uid)
            .set(therapistData);
      }
    } catch (e) {
      print('Error creating user: $e');
      throw e;
    }
  }

  // Método para actualizar un usuario existente
  Future<void> updateUser(UserModel user) async {
    try {
      final userData = user.toFirestore();

      // Actualizar en colección de usuarios (general)
      await _firestore.collection('users').doc(user.id).update(userData);

      // Si es un terapeuta, actualizar también en la colección de therapists
      if (user.role == UserRole.therapist) {
        await _firestore.collection('therapists').doc(user.id).update(userData);
      }
    } catch (e) {
      print('Error updating user: $e');
      throw e;
    }
  }

  // Método para eliminar un usuario
  Future<void> deleteUser(String userId) async {
    try {
      // Primero obtener el usuario para saber su rol
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userRole = userData['role'] as String;

        // Eliminar de Firestore
        await _firestore.collection('users').doc(userId).delete();

        // Si es un terapeuta, eliminar también de la colección de therapists
        if (userRole.contains('therapist')) {
          await _firestore.collection('therapists').doc(userId).delete();
        }

        // NOTA: Para eliminar de Firebase Auth se requeriría acceso administrativo
        // o la implementación de una Cloud Function, que está fuera del alcance de este ejemplo
      }
    } catch (e) {
      print('Error deleting user: $e');
      throw e;
    }
  }

  // Método específico para obtener los terapeutas
  Future<List<UserModel>> getTherapists() async {
    return getUsers(role: UserRole.therapist);
  }
}

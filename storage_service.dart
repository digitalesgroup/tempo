// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadClientPhoto(String clientId, File file) async {
    try {
      final ref = _storage
          .ref()
          .child('clients/$clientId/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error en uploadClientPhoto: $e');
      throw e;
    }
  }

  Future<String> uploadProductImage(String productId, File file) async {
    try {
      final ref = _storage.ref().child('products/$productId');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error en uploadProductImage: $e');
      throw e;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (e) {
      print('Error en deleteFile: $e');
      throw e;
    }
  }
}

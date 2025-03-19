import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider para el tema actual
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  // Comenzamos con el tema claro por defecto
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  // Carga la preferencia de tema guardada
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      print('Tema cargado: ${isDarkMode ? "oscuro" : "claro"}');
    } catch (e) {
      print('Error al cargar tema: $e');
      // Si hay un error, mantenemos el tema claro
      state = ThemeMode.light;
    }
  }

  // Cambia entre tema claro y oscuro
  Future<void> toggleTheme() async {
    final newState = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newState;
    print(
        'Cambiando tema a: ${newState == ThemeMode.dark ? "oscuro" : "claro"}');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', newState == ThemeMode.dark);
      print('Preferencia de tema guardada');
    } catch (e) {
      print('Error al guardar preferencia de tema: $e');
    }
  }

  // Establece un tema específico
  Future<void> setTheme(ThemeMode themeMode) async {
    state = themeMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', themeMode == ThemeMode.dark);
    } catch (e) {
      print('Error al guardar preferencia de tema: $e');
    }
  }
}

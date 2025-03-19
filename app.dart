import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router/go_router.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';

class SpaApp extends ConsumerWidget {
  const SpaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos el proveedor de tema
    final themeMode = ref.watch(themeProvider);
    // Print para depuración
    print(
        'Construyendo app con tema: ${themeMode == ThemeMode.dark ? "oscuro" : "claro"}');

    // Observamos el proveedor de idioma
    final locale = ref.watch(localeProvider);

    // Para el router usamos el proveedor de go_router
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Luxe Spa Management',
      debugShowCheckedModeBanner: false,
      // Definimos correctamente los temas
      theme: lightTheme, // Tema claro
      darkTheme: darkTheme, // Tema oscuro
      themeMode: themeMode, // Modo de tema (system, light, dark)
      locale: locale,
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotevault/core/providers/theme_provider.dart';
import 'package:quotevault/features/auth/providers/profile_provider.dart';
import 'routes/app_router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(appThemeProvider);
    final settings = ref.watch(themeSettingsProvider);
    
    // Load settings from profile on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (settings.syncWithProfile) {
        final syncService = ref.read(profileSyncServiceProvider);
        syncService.loadThemeSettingsFromProfile();
      }
    });
    // final themeData = ref.watch(appThemeProvider);
    // final settings = ref.watch(themeSettingsProvider);
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,

      // theme: ThemeData(useMaterial3: true),
      title: 'QuoteVault',
      theme: themeData.copyWith(brightness: Brightness.light),
      darkTheme: themeData.copyWith(brightness: Brightness.dark),
      themeMode: settings.themeMode == ThemeModeType.system
          ? ThemeMode.system
          : (settings.themeMode == ThemeModeType.dark
                ? ThemeMode.dark
                : ThemeMode.light),

      // home: const QuoteListScreen(),
    );
  }
}

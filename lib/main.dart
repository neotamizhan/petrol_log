import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/records_provider.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storageService = StorageService();
  await storageService.init();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => RecordsProvider(storageService)..init(),
      child: const PetrolLogApp(),
    ),
  );
}

class PetrolLogApp extends StatelessWidget {
  const PetrolLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordsProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Petrol Log',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: provider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

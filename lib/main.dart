import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  // 👇 ESTA LÍNEA ES LA CLAVE: inicializa los plugins antes de runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const AppCheckAdminApp());
}

class AppCheckAdminApp extends StatelessWidget {
  const AppCheckAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppCheck Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0F766E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}

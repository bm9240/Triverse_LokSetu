import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/citizen_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/grievbot_screen.dart'; // GrievBot - AI complaint intake
import 'screens/easyform_screen.dart'; // EasyForm - Auto-fill forms
import 'providers/complaint_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Error loading .env file: $e');
    // Continue anyway - app will work without .env for basic features
  }
  runApp(const LokSetuApp());
}

class LokSetuApp extends StatelessWidget {
  const LokSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ComplaintProvider(),
      child: MaterialApp(
        title: 'LokSetu - ProofChain',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6B2C91), // Purple from image
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const HomeScreen(),
        routes: {
          '/citizen': (context) => const CitizenScreen(),
          '/admin': (context) => const AdminScreen(),
          '/easyform': (context) => const EasyFormScreen(),
          // Note: GrievBot route requires parameters, use Navigator.push instead
        },
      ),
    );
  }
}

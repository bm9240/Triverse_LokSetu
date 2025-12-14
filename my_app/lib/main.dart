import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/citizen_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/grievbot_screen.dart'; // GrievBot - AI complaint intake
import 'providers/complaint_provider.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
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
          // Note: GrievBot route requires parameters, use Navigator.push instead
        },
      ),
    );
  }
}

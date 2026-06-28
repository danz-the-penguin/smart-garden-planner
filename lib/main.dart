import 'package:flutter/material.dart';
import 'package:sgp/alert_history_screen.dart';
import 'package:sgp/tree_list_screen.dart';
import 'package:sgp/login_screen.dart';

void main() {
  runApp(const SmartGardenApp());
}

class SmartGardenApp extends StatelessWidget {
  const SmartGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Garden Planner',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
        cardTheme: CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      home: const LoginScreen(), 
      routes: {
        '/dashboard': (context) => TreeListScreen(),
        '/alerts': (context) => const AlertHistoryScreen(),
      },
    );
  }
}

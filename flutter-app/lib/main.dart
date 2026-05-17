import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const KhidmatYarApp());
}

class KhidmatYarApp extends StatelessWidget {
  const KhidmatYarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KhidmatYar AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D2A1C)),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}

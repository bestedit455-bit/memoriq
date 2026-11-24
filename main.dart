import 'package:flutter/material.dart';
import 'theme.dart';
import 'splash.dart';
import 'home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MemoriqApp());
}

class MemoriqApp extends StatelessWidget {
  const MemoriqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MEMORIQ',
      theme: buildPremiumTheme(),
      home: const SplashScreen(next: HomePage()),
    );
  }
}

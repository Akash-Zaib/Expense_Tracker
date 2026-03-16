import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // ── Routing ──────────────────────────────────────────────
      initialRoute: AppRoutes.initial, // currently '/home'
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

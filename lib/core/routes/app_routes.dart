import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/expense/presentation/pages/home_page.dart';
import '../../features/expense/presentation/pages/submit_expense_page.dart';
import '../../features/expense/presentation/pages/add_amount_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';

/// Centralized route name constants for the entire app.
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  // Route names
  static const String root = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String submitExpense = '/submit-expense';
  static const String addAmount = '/add-amount';
  static const String notifications = '/notifications';

  /// The initial route when the app launches.
  static const String initial = login;

  /// Route generator used by [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
      case login:
        return _buildRoute(const LoginPage(), settings);
      case signup:
        return _buildRoute(const SignupPage(), settings);
      case home:
        return _buildRoute(const HomePage(), settings);
      case submitExpense:
        return _buildRoute(const SubmitExpensePage(), settings);
      case addAmount:
        return _buildRoute(const AddAmountPage(), settings);
      case notifications:
        return _buildRoute(const NotificationsPage(), settings);
      default:
        return _buildRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
          settings,
        );
    }
  }

  /// Helper to create a consistent [MaterialPageRoute].
  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

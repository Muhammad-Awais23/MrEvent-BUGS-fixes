import 'package:event_manager/components/bottomNav.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:event_manager/screens/admin.dart';
import 'package:event_manager/screens/adminPanel.dart';
import 'package:event_manager/screens/login_screen.dart';
import 'package:event_manager/screens/mainscreen.dart';
import 'package:event_manager/screens/signup_screen.dart';

class RouteHelper {
  static Future<String> getInitRoute() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    bool isAdmin = prefs.getBool('isAdmin') ?? false;
    bool isUser = prefs.getBool('isUser') ?? false;

    if (isLoggedIn) {
      if (isAdmin) {
        return adminPanel;
      } else if (isUser) {
        return mainscreen;
      } else {
        return login;
      }
    } else {
      return login;
    }
  }

  static const String initRoute = "/";
  static const String login = "/login";
  static const String signup = "/signup";
  static const String mainscreen = "/mainscreen";
  static const String admin = "/admin";
  static const String adminPanel = "/adminpanel";
  static const String bottomnavbar = "/bottomnavbar";

  static Map<String, WidgetBuilder> routes(BuildContext context) {
    return {
      login: (context) => const LoginScreen(),
      signup: (context) => const SignUpScreen(),
      admin: (context) => const AdminPage(),
      mainscreen: (context) => const HomeScreen(),
      bottomnavbar: (context) => const BottomTabsPage(),
      adminPanel: (context) => AdminPanelScreen(),
      initRoute: (context) => FutureBuilder<String>(
            future: getInitRoute(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasData) {
                return Navigator(
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => _buildScreen(snapshot.data!),
                    );
                  },
                );
              } else {
                return const LoginScreen();
              }
            },
          ),
    };
  }

  static Widget _buildScreen(String route) {
    switch (route) {
      case mainscreen:
        return const BottomTabsPage();
      case adminPanel:
        return AdminPanelScreen();
      default:
        return const LoginScreen();
    }
  }
}

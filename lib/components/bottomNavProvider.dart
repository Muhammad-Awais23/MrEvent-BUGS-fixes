import 'package:event_manager/screens/historyscreen.dart';
import 'package:event_manager/screens/mainscreen.dart';
import 'package:event_manager/screens/notificationScreen.dart';
import 'package:event_manager/screens/userprofilescreen.dart';
import 'package:event_manager/screens/viewEvents.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BottomTabsPageProvider extends ChangeNotifier {
  int _currentPage = 0;
  int get currentPage => _currentPage;

  late String username = "";
  late String email = "";
  late String userid = "";
  late String userdocid = "";

  List<Widget> _pages = [];

  List<Widget> get pages => _pages;

  BottomTabsPageProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email') ?? "";
    username = prefs.getString('username') ?? "";
    userid = prefs.getString('userid') ?? "";
    userdocid = prefs.getString('userdocid') ?? "";

    _pages = [
      const HomeScreen(),
      ViewEvents(),
      HistoryScreen(),
      NotificationsScreen(),
      UserProfileScreen(),
    ];

    notifyListeners();
  }

  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }
}

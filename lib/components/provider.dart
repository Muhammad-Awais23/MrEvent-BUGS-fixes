import 'package:flutter/material.dart';

class UserData extends ChangeNotifier {
  String? email;
  String? username;

  void setUser(String email, String username) {
    this.email = email;
    this.username = username;
    notifyListeners();
  }
}

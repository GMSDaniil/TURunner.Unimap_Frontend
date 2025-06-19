import 'package:auth_app/domain/entities/user.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  UserEntity? _user;

  UserEntity? get user => _user;

  void setUser(UserEntity user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
  }
}
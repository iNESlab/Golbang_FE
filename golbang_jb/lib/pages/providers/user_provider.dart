import 'package:flutter/material.dart';

class UserTokenProvider with ChangeNotifier {
  String? _userToken;

  String? get userToken => _userToken;

  void setUserToken(String token) {
    _userToken = token;
    notifyListeners();
  }

  void clearUserToken() {
    _userToken = null;
    notifyListeners();
  }
}
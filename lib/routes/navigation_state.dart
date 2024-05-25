import 'package:flutter/material.dart';

class NavigationState extends ChangeNotifier {
  String? _currentPath;

  String? get currentPath => _currentPath;

  void setPath(String path) {
    _currentPath = path;
    notifyListeners();
  }
}

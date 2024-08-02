import 'package:flutter/material.dart';

class NavigationState extends ChangeNotifier {
  String? _currentPath;

  String? get currentPath => _currentPath;

  void setPath(String path) {
    print('NavigationState: Setting path to $path');
    _currentPath = path;
    notifyListeners();
  }
}

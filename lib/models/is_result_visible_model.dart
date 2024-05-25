import 'package:flutter/material.dart';

class IsResultVisibleModel extends ChangeNotifier {
  bool _resultVisible = false;

  bool get resultVisible => _resultVisible;

  void setResultVisible(bool newResultVisible) {
    _resultVisible = newResultVisible;
    notifyListeners();
  }
}

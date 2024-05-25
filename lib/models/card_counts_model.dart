import 'package:flutter/material.dart';

class CardCountsModel extends ChangeNotifier {
  Map<String, int> _cardCounts = {};

  Map<String, int> get cardCounts => _cardCounts;

  void setCardCountsModel(Map<String, int> newCounts) {
    _cardCounts = newCounts;
    notifyListeners();
  }
}

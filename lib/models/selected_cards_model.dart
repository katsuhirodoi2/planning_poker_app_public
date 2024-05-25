import 'package:flutter/material.dart';

class SelectedCardsModel extends ChangeNotifier {
  Map<String, Map<String, String?>> _selectedCards = {};

  Map<String, Map<String, String?>> get selectedCards => _selectedCards;

  void setSelectedCards(Map<String, Map<String, String?>> newCards) {
    _selectedCards = newCards;
    notifyListeners();
  }
}

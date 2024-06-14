import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class PlatformFunctions {
  void setTitle(String title) {}

  String getOrigin() {
    return '';
  }

  Future<Uint8List?> pickImage() async {
    return null;
  }
}

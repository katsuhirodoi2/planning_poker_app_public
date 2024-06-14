import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class PlatformFunctions {
  void setTitle(String title) {}

  String getOrigin() {
    return '';
  }

  Future<Uint8List?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return await pickedFile.readAsBytes();
    } else {
      print('No image selected.');
      return null;
    }
  }
}

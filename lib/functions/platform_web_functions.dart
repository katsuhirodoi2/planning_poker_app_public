import 'dart:html' as html;
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class PlatformFunctions {
  void setTitle(String title) {
    html.document.title = title;
  }

  String getOrigin() {
    return html.window.location.origin;
  }

  Future<Uint8List?> pickImage() async {
    Uint8List? imageData;
    try {
      imageData = await ImagePickerWeb.getImageAsBytes();
      if (imageData != null) {
        // 作成したファイルをsaveImageに渡します
        return imageData;
      } else {
        print('No image selected.');
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }
}

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:planning_poker_app/functions/common_functions.dart';

Future<String?> uploadImageAndSaveUrl(
    String roomID, Uint8List? imageData) async {
  if (imageData == null) {
    print('画像が選択されていません。');
    return null;
  }

  String fileName = DateTime.now().millisecondsSinceEpoch.toString() +
      '_' +
      generateRandomString(6, true);
  ;
  FirebaseStorage storage = FirebaseStorage.instance;
  Reference ref = storage.ref().child("public/images/$roomID/$fileName");

  try {
    // 画像をアップロードします。
    await ref.putData(imageData);
    print('画像のアップロードが完了しました。');

    // アップロードした画像のURLを取得します。
    String downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    print('画像のアップロード中にエラーが発生しました: $e');
    return null;
  }
}

// ランダムな数字を生成します
// String generateRandomNumberString(int length) {
//   var rand = new Random();
//   var codeUnits = List.generate(
//     length,
//     (index) => rand.nextInt(10), // 0から9までのランダムな数字を生成
//   );

//   return codeUnits.join();
// }

// SharedPreferencesに_imageDataを保存します
Future<void> saveUserImage(Uint8List? imageData) async {
  if (imageData == null) {
    return;
  }
  String base64Image = base64Encode(imageData);

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userImage', base64Image);
}

// SharedPreferencesからimageDataを読み込みます
Future<Image> loadUserImage() async {
  final prefs = await SharedPreferences.getInstance();
  final base64Image = prefs.getString('userImage');

  if (base64Image == null) {
    return Image.asset(
      'assets/images/default_face.png',
      width: 44,
      height: 44,
      fit: BoxFit.cover,
    );
  }

  final bytes = base64Decode(base64Image);
  return Image.memory(
    bytes,
    width: 44,
    height: 44,
    fit: BoxFit.cover,
  );
}

// SharedPreferencesのuserImageにデータが入っているかどうかをチェックします
Future<bool> checkPrefsUserImage() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? base64Image = prefs.getString('userImage');
  if (base64Image != null) {
    return true;
  } else {
    return false;
  }
}

// SharedPreferencesからimageDataを削除します
Future<void> deleteUserImage() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('userImage');
}

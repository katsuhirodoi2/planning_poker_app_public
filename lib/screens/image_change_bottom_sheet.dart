import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:planning_poker_app/functions/user_image_common_functions.dart';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:planning_poker_app/platform_functions_export.dart';

class ImageChangeBottomSheet extends StatefulWidget {
  final prefsUserName;
  final roomID;
  final Image? initialImage;
  final bool isSaveServer;

  ImageChangeBottomSheet(
      {required this.prefsUserName,
      required this.roomID,
      required this.initialImage,
      required this.isSaveServer});

  @override
  _ImageChangeBottomSheet createState() => _ImageChangeBottomSheet();
}

class _ImageChangeBottomSheet extends State<ImageChangeBottomSheet> {
  bool changeUserImageIsLoading = false;

  ValueNotifier<Uint8List?> _imageData = ValueNotifier<Uint8List?>(null);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          width: min(MediaQuery.of(context).size.width * 0.8, 400),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () async {
                        Uint8List? imageData = await getImage();
                        if (imageData != null) {
                          loadImage(imageData);
                        }
                      },
                      child: Text(
                        '画像を選択する',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Color(0xFFFFFFFF),
                            ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4B39EF),
                        foregroundColor: Color(0xFFFFFFFF),
                        padding: EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    child: Text(
                      'プレビュー',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0x4C4B39EF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF4B39EF), // 縁取りの色
                        width: 2, // 縁取りの幅
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: ValueListenableBuilder<Uint8List?>(
                        valueListenable: _imageData,
                        builder: (BuildContext context, Uint8List? value,
                            Widget? child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: value == null
                                ? Image.asset(
                                    'assets/images/default_face.png',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  )
                                : Image.memory(
                                    value,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 8.0),
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              // モーダルを閉じる
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'キャンセル',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Color(0xFF4B39EF),
                                  ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFFFFFF),
                              foregroundColor: Color(0xFF4B39EF),
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 8.0),
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                changeUserImageIsLoading = true;
                              });

                              try {
                                await saveImage(widget.prefsUserName);
                              } catch (e) {
                                print(
                                    'Error occurred during saveImage or loadUserImage: $e');
                              }

                              setState(() {
                                changeUserImageIsLoading = false;
                              });
                              // 処理が終わったらモーダルは閉じる
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              widget.isSaveServer ? '保存する' : '決定',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Color(0xFFFFFFFF),
                                  ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4B39EF),
                              foregroundColor: Color(0xFFFFFFFF),
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (changeUserImageIsLoading)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  // 画像データをグローバル変数に保存します
  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      convertAndLoadImage(widget.initialImage!);
    }
  }

  // 画像を選択してUint8Listに変換します
  Future<Uint8List?> getImage() async {
    return await PlatformFunctions().pickImage();
  }

  // 画像を選択してUint8Listに変換します
  Future<void> convertAndLoadImage(Image image) async {
    final completer = Completer<ui.Image>();
    image.image.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener(
            (info, _) => completer.complete(info.image),
          ),
        );
    final ui.Image uiImage = await completer.future;
    final ByteData? byteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.png);
    loadImage(byteData!.buffer.asUint8List());
  }

  // 画像データをグローバル変数に保存します
  void loadImage(Uint8List imageData) {
    _imageData.value = imageData;
  }

  Future<void> saveImage(String userName) async {
    // 画像をアップロードしてURLを取得
    var downloadUrl;

    if (widget.isSaveServer) {
      downloadUrl =
          await uploadImageAndSaveUrl(widget.roomID, _imageData.value);
    }

    // prefsに画像を保存
    await saveUserImage(_imageData.value);

    // Firestoreにユーザー情報を保存
    if (widget.isSaveServer) {
      var userDocs = await _firestore
          .collection('rooms')
          .doc(widget.roomID.toString())
          .collection('users')
          .where('userName', isEqualTo: userName)
          .get();
      if (userDocs.docs.isNotEmpty) {
        await _firestore
            .collection('rooms')
            .doc(widget.roomID.toString())
            .collection('users')
            .doc(userDocs.docs.first.id)
            .update({'imageUrl': downloadUrl});
      }

      // ルームの最終アクティビティ日時を更新
      await _firestore
          .collection('rooms')
          .doc(widget.roomID.toString())
          .update({
        'lastActivityDateTime': FieldValue.serverTimestamp(),
      });
    }
  }
}

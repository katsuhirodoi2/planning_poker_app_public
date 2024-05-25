import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:planning_poker_app/routes/my_router_delegate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:planning_poker_app/functions/user_image_common_functions.dart';
import 'package:planning_poker_app/screens/image_change_bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class NameInputScreen extends StatefulWidget {
  @override
  _NameInputScreenState createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final _nameController = TextEditingController();

  // ローディング状態を管理するための変数を追加
  bool _isLoading = false;

  late Future<List<Object>> prefsUserImageFutureList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('名前を入力'),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                Container(
                  width: 200, // テキストフィールドの幅を制限
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '名前',
                      labelStyle: TextStyle(
                        fontSize: 12, // フォントサイズを小さくする
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  child: Text(
                    'アイコン',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                SizedBox(height: 8),
                FutureBuilder(
                  future: prefsUserImageFutureList, // 非同期データを取得する関数
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(); // データを取得中はローディングインジケータを表示
                    } else if (snapshot.hasError) {
                      return Text('エラーが発生しました'); // エラーが発生した場合の表示
                    } else {
                      Image prefsUserImage = snapshot.data?[0] as Image;
                      bool isExistPrefsUserImage = snapshot.data?[1] as bool;

                      return PopupMenuButton(
                        offset: Offset(0, 50 + 12), // メニューの表示位置を調整
                        icon: Container(
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: prefsUserImage, // 非同期データを使用
                            ),
                          ),
                        ),
                        itemBuilder: (BuildContext context) {
                          List<PopupMenuEntry> menuItems = [
                            PopupMenuItem(
                              value: 'changeUserImage',
                              child: Text('アイコンを変更する',
                                  style:
                                      Theme.of(context).textTheme.labelMedium),
                            ),
                          ];
                          // 特定の条件が満たされたときにのみ、'deleteUserImage' メニューアイテムを追加
                          if (isExistPrefsUserImage) {
                            menuItems.add(
                              PopupMenuItem(
                                value: 'deleteUserImage',
                                child: Text('アイコンを削除する',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium),
                              ),
                            );
                          }
                          return menuItems;
                        },
                        onSelected: (value) async {
                          if (value == 'changeUserImage') {
                            await showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return ImageChangeBottomSheet(
                                  prefsUserName: '',
                                  roomID: '',
                                  initialImage: prefsUserImage,
                                  isSaveServer: false,
                                );
                              },
                            );
                          } else if (value == 'deleteUserImage') {
                            await deleteUserImage();
                          }
                          setState(() {
                            prefsUserImageFutureList = Future.wait(
                                [loadUserImage(), checkPrefsUserImage()]);
                          });
                        },
                      );
                    }
                  },
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      saveNameAndImage(context);
                    },
                    child: Text(
                      '入室',
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
              ],
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    prefsUserImageFutureList =
        Future.wait([loadUserImage(), checkPrefsUserImage()]);
    loadUserName();
  }

  void saveNameAndImage(BuildContext context) async {
    String userName = _nameController.text;
    // userNameが入力されていない場合はエラーメッセージを表示し、後続の処理を行わない
    if (userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('名前が入力されていません。名前を入力してから入室ボタンを押してください。'),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? roomID = prefs.getString('roomID');

    // Firestoreに接続するためのインスタンスを作成
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    if (roomID == null || roomID.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('端末にroomIDが保持されていません。homeページに戻ります。'),
          action: SnackBarAction(
            label: 'Home',
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/'));
            },
          ),
        ),
      );
    } else {
      // 同じルームに同じユーザー名が存在しないかチェック
      final findUser = await _firestore
          .collection('rooms')
          .doc(roomID)
          .collection('users')
          .where('userName', isEqualTo: userName)
          .get();

      if (findUser.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同名のユーザーが既に部屋にいます。重複しない名前に変更してください。')),
        );
      } else {
        // 処理を開始する前にローディング状態をtrueに設定
        setState(() {
          _isLoading = true;
        });

        Uint8List imageData = await loadUserImageToUnit8List();

        // 画像をアップロードしてURLを取得
        var downloadUrl = await uploadImageAndSaveUrl(roomID, imageData);

        // prefsに画像を保存
        // await saveUserImage(_imageData.value);

        // Firestoreにユーザー情報を保存
        await _firestore
            .collection('rooms')
            .doc(roomID)
            .collection('users')
            .add({
          'userName': userName,
          'imageUrl': downloadUrl,
        });

        // SharedPreferencesにユーザー名を保存
        await prefs.setString('userName', userName);
        await prefs.setString('storedUserName', userName);

        // ルームの最終アクティビティ日時を更新
        await _firestore.collection('rooms').doc(roomID).update({
          'lastActivityDateTime': FieldValue.serverTimestamp(),
        });

        // 処理が完了したらローディング状態をfalseに設定
        setState(() {
          _isLoading = false;
        });

        // ルームが存在する場合、ナビゲーションを行う
        MyRouterDelegate routerDelegate =
            Router.of(context).routerDelegate as MyRouterDelegate;
        routerDelegate.setNewRoutePath('/room/$roomID');
      }
    }
  }

  // SharedPreferencesからuserImageを読み込み、Uint8Listに変換して返します
  Future<Uint8List> loadUserImageToUnit8List() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Image = prefs.getString('userImage');

    if (base64Image == null) {
      // base64Imageがnullの場合はデフォルトの画像をUint8Listに変換して返す
      ByteData data = await rootBundle.load('assets/images/default_face.png');
      Uint8List defaultImage = data.buffer.asUint8List();
      return defaultImage;
    } else {
      // base64Imageがnullでない場合はUint8Listに変換して返す
      final bytes = base64Decode(base64Image);
      return bytes;
    }
  }

  Future<void> loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserName = prefs.getString('storedUserName');
    if (storedUserName != null) {
      _nameController.text = storedUserName;
    }
  }
}

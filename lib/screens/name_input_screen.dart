import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:planning_poker_app/functions/room_common_functions.dart';
import 'package:planning_poker_app/routes/my_router_delegate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:planning_poker_app/functions/user_image_common_functions.dart';
import 'package:planning_poker_app/screens/image_change_bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class NameInputScreen extends StatefulWidget {
  @override
  _NameInputScreenState createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final _nameController = TextEditingController();

  // ローディング状態を管理するための変数を追加
  bool _isLoading = false;

  late Future<List<Object>> prefsUserImageFutureList;

  // Firestoreに接続するためのインスタンスを作成
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('名前を入力'),
        leading: !kIsWeb
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  // スマホ版のみ、戻るボタンを押したときにルートを "/" に設定する
                  MyRouterDelegate routerDelegate =
                      Router.of(context).routerDelegate as MyRouterDelegate;
                  routerDelegate.setNewRoutePath('/');
                },
              )
            : null,
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
      // 部屋でブロックされていないかチェック
      bool isBlockUser = await checkBlockUser(roomID);
      if (isBlockUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('この部屋には入室できません。')),
        );
        return;
      }

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
        // ここで、利用者のデバイスがiOSの場合のみ利用規約に同意しているかどうかを確認する処理を追加する
        if (Theme.of(context).platform == TargetPlatform.iOS) {
          bool isAgree = prefs.getBool('isAgree') ?? false;
          if (isAgree == false) {
            showEulaDialog(context).then((isAgree) {
              if (isAgree == true) {
                prefs.setBool('isAgree', true);
                saveNameAndImageToFirestore(userName, roomID);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('利用規約に同意していないため、入室できません。')),
                );
              }
            });
          } else {
            saveNameAndImageToFirestore(userName, roomID);
          }
        } else {
          saveNameAndImageToFirestore(userName, roomID);
        }
      }
    }
  }

  saveNameAndImageToFirestore(String userName, String roomID) async {
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
    await _firestore.collection('rooms').doc(roomID).collection('users').add({
      'userName': userName,
      'imageUrl': downloadUrl,
    });

    // SharedPreferencesにユーザー名を保存
    SharedPreferences prefs = await SharedPreferences.getInstance();
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

  Future<bool?> showEulaDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // ユーザーがダイアログ外をタップしてもダイアログが閉じないようにする
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('利用規約'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  '''本利用規約（以下、「本規約」）は、プランニングポーカー（以下、「本アプリ」）の利用に関する条件を定めるものです。入室する前に、本規約をよくお読みください。入室することにより、ユーザーは本規約に同意したものとみなされます。

第1条（適用）
本規約は、本アプリの利用に関する一切の関係に適用されます。

第2条（禁止事項）
ユーザーは、本アプリの利用にあたり、以下の行為をしてはなりません。

・法令または公序良俗に違反する行為
・犯罪行為に関連する行為
・本アプリのサーバーまたはネットワークの機能を破壊したり、妨害したりする行為
・本アプリの運営を妨害するおそれのある行為
・他のユーザーに関する個人情報等を収集または蓄積する行為
・不正アクセスをし、またはこれを試みる行為
・他のユーザーに成りすます行為
・本アプリに関連して、反社会的勢力に対して直接または間接に利益を供与する行為
・その他、本アプリが不適切と判断する行為

第3条（保証の否認および免責事項）
本アプリは、本アプリに事実上または法律上の瑕疵（安全性、信頼性、正確性、完全性、有効性、特定の目的適合性、セキュリティなどに関する欠陥、エラーやバグ、権利侵害などを含む）がないことを明示的にも黙示的にも保証しておりません。本アプリは、本アプリの利用により生じたあらゆる損害について、一切の責任を負いません。

第4条（サービス内容の変更等）
本アプリは、ユーザーへの事前の告知なく、本アプリの内容を変更し、または提供を中止することができます。本アプリは、これによってユーザーに生じた損害について一切の責任を負いません。

第5条（利用規約の変更）
本アプリは、必要と判断した場合には、ユーザーに通知することなく、いつでも本規約を変更することができます。

第6条（個人情報の取扱い）
本アプリの利用によって取得するユーザーの個人情報については、本アプリのプライバシーポリシーに従い適切に取り扱うものとします。

第7条（権利義務の譲渡の禁止）
ユーザーは、本アプリの書面による事前の承諾なく、利用契約上の地位または本規約に基づく権利もしくは義務を第三者に譲渡し、または担保に供することはできません。

第8条（準拠法・裁判管轄）
本規約の解釈にあたっては、日本法を準拠法とします。本アプリに関して紛争が生じた場合には、本アプリの所在地を管轄する裁判所を専属的合意管轄とします。''',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                '同意しない',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Color(0xFF4B39EF),
                    ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFFFFF),
                foregroundColor: Color(0xFF4B39EF),
                padding: EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(
                '同意する',
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
          ],
        );
      },
    );
  }
}

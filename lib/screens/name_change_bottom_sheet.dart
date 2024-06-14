import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:planning_poker_app/functions/user_image_common_functions.dart';
import 'dart:math';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class NameChangeBottomSheet extends StatefulWidget {
  final prefsUserName;
  final roomID;
  final Function onUserNameChanged;

  NameChangeBottomSheet(
      {required this.prefsUserName,
      required this.roomID,
      required this.onUserNameChanged});

  @override
  _NameChangeBottomSheet createState() => _NameChangeBottomSheet();
}

class _NameChangeBottomSheet extends State<NameChangeBottomSheet>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;

  @override
  Widget build(BuildContext context) {
    bool changeUserNameIsLoading = false;
    String errorMessage = '';
    bool showError = false;

    AnimationController _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 500),
      vsync: this,
    );

    Animation<Offset> _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    Timer? _hideErrorTimer;

    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
      void hideErrorMsg() async {
        await _controller.reverse();
        setModalState(() {
          showError = false;
          errorMessage = '';
        });

        Future.delayed(Duration(seconds: 1), () {});
      }

      void showErrorMsg(String msg) {
        _controller.reset();

        // 前回のタイマーがあればキャンセル
        _hideErrorTimer?.cancel();

        setModalState(() {
          showError = true;
          errorMessage = msg;
          _controller.forward();
        });

        // hideErrorMsgを呼び出すタイマーを設定
        _hideErrorTimer = Timer(Duration(seconds: 3), () {
          if (showError) {
            hideErrorMsg();
          }
        });
      }

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
                    showError
                        ? SlideTransition(
                            position: _offsetAnimation,
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Color(0x80000000),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                errorMessage,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Container(),
                    SizedBox(height: showError ? 16 : 0),
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
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16, 0, 16, 0),
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
                                setModalState(() {
                                  changeUserNameIsLoading = true;
                                });

                                try {
                                  errorMessage = await changeUserName(
                                      widget.prefsUserName,
                                      _nameController.text);
                                } catch (e) {
                                  print(
                                      'Error occurred during changeUserName: $e');
                                }

                                setModalState(() {
                                  changeUserNameIsLoading = false;
                                });
                                if (errorMessage.isEmpty) {
                                  // 処理が終わったらモーダルは閉じる
                                  Navigator.of(context).pop();
                                } else {
                                  showErrorMsg(errorMessage);
                                }
                              },
                              child: Text(
                                '保存する',
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
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16, 0, 16, 0),
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
          if (changeUserNameIsLoading)
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
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefsUserName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ユーザーの名前を変更する関数
  Future<String> changeUserName(
      String currentUserName, String newUserName) async {
    // ユーザー名が変更されていない場合は、処理を終了
    if (currentUserName == newUserName) {
      print('ユーザー名変更なし。処理しない');
      return '';
    }

    // ここにダミーの遅延を入れる。
    // await Future.delayed(Duration(seconds: 3));

    // 既に同じユーザー名が存在する場合は、エラーを出力して処理を終了
    final userDocsForExistCheck = await _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .collection('users')
        .where('userName', isEqualTo: newUserName)
        .get();
    if (userDocsForExistCheck.docs.isNotEmpty) {
      return '同名のユーザーが既に部屋にいます。重複しない名前に変更してください。';
    }

    if (currentUserName.isEmpty) {
      return '不明なエラー：現在のユーザー名が空になっている、もしくは取得できませんでした。';
    }

    // SharedPreferencesにユーザー名を保存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', newUserName);
    await prefs.setString('storedUserName', newUserName);

    // prefsUserNameを更新
    setState(() {
      widget.onUserNameChanged();
    });

    // Firestoreにユーザー情報を保存
    var userDocsForUpdate = await _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .collection('users')
        .where('userName', isEqualTo: currentUserName)
        .get();

    if (userDocsForUpdate.docs.isNotEmpty) {
      await _firestore
          .collection('rooms')
          .doc(widget.roomID.toString())
          .collection('users')
          .doc(userDocsForUpdate.docs.first.id)
          .update({
        'userName': newUserName,
      });
    }

    // 直前のroomScreenCheckRoomExistsが非同期処理となっており、その実行中に以下のupdateが実行されると、lastActivityDateTimeが一瞬nullとなるため、roomScreenCheckRoomExistsを確実に終わらせてからupdateを実行するための遅延処理を行う
    await Future.delayed(Duration(milliseconds: 100));

    // ルームの最終アクティビティ日時を更新
    await _firestore.collection('rooms').doc(widget.roomID.toString()).update({
      'lastActivityDateTime': FieldValue.serverTimestamp(),
    });

    return '';
  }
}

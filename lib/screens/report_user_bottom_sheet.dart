import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ReportUserBottomSheet extends StatefulWidget {
  final roomID;
  final Function onReportSuccess;

  ReportUserBottomSheet({
    required this.roomID,
    required this.onReportSuccess,
  });

  @override
  _ReportUserBottomSheet createState() => _ReportUserBottomSheet();
}

class _ReportUserBottomSheet extends State<ReportUserBottomSheet>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _textFieldController;

  @override
  Widget build(BuildContext context) {
    bool addReportAbuseMessageIsLoading = false;
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
                      width: double.infinity,
                      child: TextField(
                        controller: _textFieldController,
                        maxLines: 5, // ユーザーが改行を入力できるようにする
                        decoration: InputDecoration(
                          labelText: 'ユーザーの違反内容',
                          labelStyle: TextStyle(
                            fontSize: 12, // フォントサイズを小さくする
                          ),
                          border: OutlineInputBorder(), // テキストフィールドの境界線を表示
                          contentPadding:
                              EdgeInsets.all(8.0), // テキストフィールド内のパディングを調整
                          floatingLabelBehavior:
                              FloatingLabelBehavior.always, // ラベルを常に浮かんだ状態にする
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
                                  addReportAbuseMessageIsLoading = true;
                                });

                                try {
                                  errorMessage = await addReportAbuseMessage(
                                      _textFieldController.text);
                                } catch (e) {
                                  print(
                                      'Error occurred during addReportAbuseMessage: $e');
                                }

                                setModalState(() {
                                  addReportAbuseMessageIsLoading = false;
                                });
                                if (errorMessage.isEmpty) {
                                  // 処理が終わったらモーダルは閉じる
                                  Navigator.of(context).pop();

                                  // 違反を報告した後にコールバックを呼び出す
                                  widget.onReportSuccess();
                                } else {
                                  showErrorMsg(errorMessage);
                                }
                              },
                              child: Text(
                                '報告する',
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
          if (addReportAbuseMessageIsLoading)
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
    _textFieldController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  Future<String> addReportAbuseMessage(String reportMessage) async {
    try {
      // ここにダミーの遅延を入れる。
      // await Future.delayed(Duration(seconds: 3));

      if (reportMessage.isEmpty) {
        return '違反内容を記入してください';
      }

      // throw Exception('わざと例外を発生させました');

      // 報告内容をデータベースに登録
      await _firestore.collection('reportAbuseMessages').add({
        'roomID': widget.roomID,
        'reportMessage': reportMessage,
        'reportDateTime': FieldValue.serverTimestamp(),
      });

      // ルームの最終アクティビティ日時を更新
      await _firestore
          .collection('rooms')
          .doc(widget.roomID.toString())
          .update({
        'lastActivityDateTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error occurred during _addReportAbuseMessage: $e');
      return 'エラーが発生しました。';
    }

    return '';
  }
}

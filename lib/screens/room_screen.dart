import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:planning_poker_app/models/card_counts_model.dart';
import 'package:planning_poker_app/models/is_result_visible_model.dart';
import 'package:planning_poker_app/models/selected_cards_model.dart';
import 'dart:html' as html;
import 'package:planning_poker_app/routes/my_router_delegate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planning_poker_app/functions/user_image_common_functions.dart';
import 'dart:math';
import 'package:planning_poker_app/screens/image_change_bottom_sheet.dart';
import 'package:planning_poker_app/functions/room_common_functions.dart';
import 'dart:async';

class RoomScreen extends StatefulWidget {
  final int roomID;

  RoomScreen({required this.roomID});

  @override
  _RoomScreenState createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with TickerProviderStateMixin {
  late Future<List<Object>> initFuture;
  Future<String>? exiterFuture;

  // Firestoreに接続するためのインスタンスを作成
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> cardNumbers = [];
  Map<String, String> previousSelectedCards = {};

  @override
  Widget build(BuildContext context) {
    // ブラウザのタイトルを設定
    html.document.title = '部屋番号 ${widget.roomID} - プランニングポーカー';

    double drawAreaBorderWidthSum = 0;
    double drawInnerAreaBorderWidthSum = 0;
    double marginBorderWidthSum = 0;
    double screenWidth = MediaQuery.of(context).size.width;
    double leftAreaWidth = 300;
    double rightAreaWidth = 600;
    double idealDrawAreaWidth = 16 +
        leftAreaWidth +
        rightAreaWidth +
        drawInnerAreaBorderWidthSum; // 1つ目の16=drawAreaの左padding
    double marginAreaWidth = screenWidth >
            idealDrawAreaWidth + drawAreaBorderWidthSum
        ? (screenWidth - (idealDrawAreaWidth + drawAreaBorderWidthSum)) / 2 -
            marginBorderWidthSum
        : 0;
    double leftAreaRatio =
        leftAreaWidth / (leftAreaWidth + rightAreaWidth) * 100;
    double rightAreaRatio =
        rightAreaWidth / (leftAreaWidth + rightAreaWidth) * 100;
    double drawAreaWidth = 0;
    if (16 +
                rightAreaWidth +
                drawAreaBorderWidthSum +
                drawInnerAreaBorderWidthSum >=
            screenWidth ||
        (screenWidth >= 617 && screenWidth <= 653)) {
      // leftAreaWidth が (screenWidth >= 617 && screenWidth <= 653) 程度より小さい場合、leftAreaWidthのウィジェッドの描画領域が子要素を賄えなくなり、エラーが出るため、この条件を追加
      // 1つ目の16=drawAreaの左padding
      drawAreaWidth = screenWidth - drawAreaBorderWidthSum;
      leftAreaWidth = drawAreaWidth -
          16 -
          drawInnerAreaBorderWidthSum; // 1つ目の16=drawAreaの左padding
      rightAreaWidth = drawAreaWidth -
          16 -
          drawInnerAreaBorderWidthSum; // 1つ目の16=drawAreaの左padding
    } else if (idealDrawAreaWidth + drawAreaBorderWidthSum > screenWidth) {
      drawAreaWidth = screenWidth - drawAreaBorderWidthSum;
      leftAreaWidth = (drawAreaWidth - drawInnerAreaBorderWidthSum - 16) *
              leftAreaRatio /
              100 -
          1; // 1つ目の16=drawAreaの左padding、-1=コンテナが折り返されるのを防ぐため
      rightAreaWidth = (drawAreaWidth - drawInnerAreaBorderWidthSum - 16) *
              rightAreaRatio /
              100 -
          1; // 1つ目の16=drawAreaの左padding、-1=コンテナが折り返されるのを防ぐため
    } else {
      drawAreaWidth =
          idealDrawAreaWidth + marginAreaWidth + marginBorderWidthSum;
    }
    double rightAreaHeaderLeftWidth = (rightAreaWidth - 16 - 16 - 16) / 2 -
        2; // 1つ目の16=rightAreaの左padding、2つ目の16=rightAreaの右padding、3つ目の16=rightAreaの右padding、3つ目のrightAreaの右margin、-2=なぜかrightAreaHeaderRightエリアから2px分ボタンがはみ出すので調整
    double rightAreaHeaderRightWidth = rightAreaHeaderLeftWidth;
    if (rightAreaHeaderRightWidth < (120 + 120 + 16 + 2)) {
      // 120=ボタンの幅、16=rightAreaHeaderRightの右padding、2=なぜかrightAreaHeaderRightエリアから2px分ボタンがはみ出すので調整
      rightAreaHeaderLeftWidth =
          (rightAreaHeaderLeftWidth + rightAreaHeaderRightWidth) - 120;
      rightAreaHeaderRightWidth = 120;
    }
    double marginLeftPlus = 0;
    if (leftAreaWidth == rightAreaWidth) {
      marginLeftPlus = marginAreaWidth; // ここ、見直し必要
      drawAreaWidth += marginLeftPlus; // ここ、見直し必要
    }

    return FutureBuilder<List<Object>>(
        future: initFuture,
        builder: (BuildContext context, AsyncSnapshot<List<Object>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 部屋の存在チェックが完了するまでローディング画面を表示
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            // エラーが発生した場合の処理
            return Text('Error: ${snapshot.error}');
          } else {
            bool roomExists = snapshot.data?[0] as bool;
            String prefsUserName = snapshot.data?[1] as String;
            Image prefsUserImage = snapshot.data?[2] as Image;
            bool isExistPrefsUserImage = snapshot.data?[3] as bool;

            TextStyle? prefsUserNameStyle =
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 0.8,
                    );
            final TextPainter prefsUserNameTextPainter = TextPainter(
              text: TextSpan(
                text: prefsUserName,
                style: prefsUserNameStyle,
              ),
              maxLines: 1,
              textDirection: TextDirection.ltr,
            )..layout();

            // 部屋の存在チェックが完了した後の描画
            if (roomExists == true) {
              if (!Provider.of<SelectedCardsModel>(context, listen: true)
                  .selectedCards
                  .containsKey(prefsUserName)) {
                if (exiterFuture == null) {
                  exiterFuture = getExiter(prefsUserName);
                }
                return FutureBuilder<String>(
                  future: exiterFuture,
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        // エラーハンドリング
                        return Text('エラー: ${snapshot.error}');
                      } else {
                        String? exiter = snapshot.data;
                        if (exiter != prefsUserName) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                color:
                                    Theme.of(context).canvasColor, // テーマの背景色を使用
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                              ),
                              AlertDialog(
                                backgroundColor: Colors.white, // 背景色を白に設定
                                shape: RoundedRectangleBorder(
                                  // 縁の形状を設定
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Color(0xFFE0E3E7), // 縁の色を設定
                                  ),
                                ),
                                title: Text('通知'),
                                content: Text(
                                    '${snapshot.data}によって退出させられました'), // データが利用できるときはそのデータを表示
                                actions: <Widget>[
                                  SizedBox(
                                    height: 40,
                                    width: 104,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await deleteUserName();
                                        await deleteExitedUser(prefsUserName);
                                        MyRouterDelegate routerDelegate =
                                            Router.of(context).routerDelegate
                                                as MyRouterDelegate;
                                        routerDelegate.setNewRoutePath('/');
                                      },
                                      child: Text(
                                        "閉じる",
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          return FutureBuilder(
                            future: Future.delayed(Duration.zero, () async {
                              await deleteUserName();
                              await deleteExitedUser(prefsUserName);
                              MyRouterDelegate routerDelegate =
                                  Router.of(context).routerDelegate
                                      as MyRouterDelegate;
                              routerDelegate.setNewRoutePath('/');
                            }),
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Scaffold(
                                  body: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              } else {
                                return Container(); // 何も表示しない
                              }
                            },
                          );
                        }
                      }
                    } else {
                      return Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                  },
                );
              } else {
                return GestureDetector(
                  child: Scaffold(
                    body: SafeArea(
                      top: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(16, 0, 0, 0),
                            margin: EdgeInsets.only(left: marginAreaWidth),
                            width: drawAreaWidth,
                            // decoration: BoxDecoration(
                            //   border: Border.all(
                            //     color: Colors.red,
                            //     width: drawAreaBorderWidthSum / 2,
                            //   ),
                            // ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16, 16, 16, 0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'プランニングポーカー',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium,
                                              ),
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(0, 4, 0, 0),
                                                child: Text(
                                                    '部屋番号 ${widget.roomID}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelMedium),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16, 12, 16, 12),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              PopupMenuButton(
                                                offset: Offset(
                                                    0, 50 + 12), // メニューの表示位置を調整
                                                icon: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: Color(0x4C4B39EF),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: Color(
                                                          0xFF4B39EF), // 縁取りの色
                                                      width: 2, // 縁取りの幅
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding: EdgeInsets.all(2),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: prefsUserImage,
                                                    ),
                                                  ),
                                                ),
                                                itemBuilder:
                                                    (BuildContext context) {
                                                  List<PopupMenuEntry>
                                                      menuItems = [
                                                    PopupMenuItem(
                                                      value: 'changeUserImage',
                                                      child: Text('アイコンを変更する',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .labelMedium),
                                                    ),
                                                  ];
                                                  // 特定の条件が満たされたときにのみ、'deleteUserImage' メニューアイテムを追加
                                                  if (isExistPrefsUserImage) {
                                                    menuItems.add(
                                                      PopupMenuItem(
                                                        value:
                                                            'deleteUserImage',
                                                        child: Text('アイコンを削除する',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelMedium),
                                                      ),
                                                    );
                                                  }
                                                  return menuItems;
                                                },
                                                onSelected: (value) async {
                                                  if (value ==
                                                      'changeUserImage') {
                                                    await showModalBottomSheet(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return ImageChangeBottomSheet(
                                                          prefsUserName:
                                                              prefsUserName,
                                                          roomID: widget.roomID
                                                              .toString(),
                                                          initialImage:
                                                              prefsUserImage,
                                                          isSaveServer: true,
                                                        );
                                                      },
                                                    );
                                                  } else if (value ==
                                                      'deleteUserImage') {
                                                    await deleteUserImage();
                                                    await deleteUserImageUrl(
                                                        prefsUserName);
                                                  }
                                                  setState(() {
                                                    initFuture = Future.wait([
                                                      roomScreenCheckRoomExists(),
                                                      checkUserName(true),
                                                      loadUserImage(),
                                                      checkPrefsUserImage(),
                                                    ]);
                                                  });
                                                },
                                              ),
                                              Container(
                                                constraints: BoxConstraints(
                                                  minWidth: 96,
                                                  maxWidth: min(
                                                      max(screenWidth * 0.3,
                                                          96),
                                                      192),
                                                ),
                                                padding: EdgeInsetsDirectional
                                                    // .fromSTEB(4, 0, 0, 0),
                                                    .fromSTEB(0, 0, 0, 0),
                                                child: Column(
                                                  // mainAxisSize: MainAxisSize.max,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Transform.translate(
                                                      offset: Offset(
                                                          prefsUserNameTextPainter
                                                                      .size
                                                                      .width <
                                                                  12
                                                              ? -12.0
                                                              : prefsUserNameTextPainter
                                                                          .size
                                                                          .width <
                                                                      24
                                                                  ? -8.0
                                                                  : -6.0,
                                                          8.0),
                                                      child: PopupMenuButton(
                                                        offset: Offset(
                                                          0,
                                                          prefsUserNameTextPainter
                                                                  .size.height +
                                                              24,
                                                        ), // メニューの表示位置を調整
                                                        icon: Container(
                                                          child: Text(
                                                            prefsUserName,
                                                            style:
                                                                prefsUserNameStyle,
                                                          ),
                                                        ),
                                                        itemBuilder:
                                                            (BuildContext
                                                                context) {
                                                          List<PopupMenuEntry>
                                                              menuItems = [
                                                            PopupMenuItem(
                                                              value:
                                                                  'changeUserName',
                                                              child: Text(
                                                                  '名前を変更する',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .labelMedium),
                                                            ),
                                                          ];
                                                          return menuItems;
                                                        },
                                                        onSelected:
                                                            (value) async {
                                                          if (value ==
                                                              'changeUserName') {
                                                            showModalBottomSheet(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                final _nameController =
                                                                    TextEditingController(
                                                                        text:
                                                                            prefsUserName);

                                                                bool
                                                                    changeUserNameIsLoading =
                                                                    false;
                                                                String
                                                                    errorMessage =
                                                                    '';
                                                                bool showError =
                                                                    false;

                                                                AnimationController
                                                                    _controller =
                                                                    AnimationController(
                                                                  duration: const Duration(
                                                                      milliseconds:
                                                                          500),
                                                                  reverseDuration:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              500),
                                                                  vsync: this,
                                                                );

                                                                Animation<
                                                                        Offset>
                                                                    _offsetAnimation =
                                                                    Tween<
                                                                        Offset>(
                                                                  begin:
                                                                      const Offset(
                                                                          0.0,
                                                                          -1.0),
                                                                  end: Offset
                                                                      .zero,
                                                                ).animate(
                                                                        CurvedAnimation(
                                                                  parent:
                                                                      _controller,
                                                                  curve: Curves
                                                                      .easeInOut,
                                                                ));

                                                                Timer?
                                                                    _hideErrorTimer;

                                                                return StatefulBuilder(builder:
                                                                    (BuildContext
                                                                            context,
                                                                        StateSetter
                                                                            setModalState) {
                                                                  void
                                                                      hideErrorMsg() async {
                                                                    await _controller
                                                                        .reverse();
                                                                    setModalState(
                                                                        () {
                                                                      showError =
                                                                          false;
                                                                      errorMessage =
                                                                          '';
                                                                    });

                                                                    Future.delayed(
                                                                        Duration(
                                                                            seconds:
                                                                                1),
                                                                        () {});
                                                                  }

                                                                  void showErrorMsg(
                                                                      String
                                                                          msg) {
                                                                    _controller
                                                                        .reset();

                                                                    // 前回のタイマーがあればキャンセル
                                                                    _hideErrorTimer
                                                                        ?.cancel();

                                                                    setModalState(
                                                                        () {
                                                                      showError =
                                                                          true;
                                                                      errorMessage =
                                                                          msg;
                                                                      _controller
                                                                          .forward();
                                                                    });

                                                                    // hideErrorMsgを呼び出すタイマーを設定
                                                                    _hideErrorTimer = Timer(
                                                                        Duration(
                                                                            seconds:
                                                                                3),
                                                                        () {
                                                                      if (showError) {
                                                                        hideErrorMsg();
                                                                      }
                                                                    });
                                                                  }

                                                                  return Stack(
                                                                    children: <Widget>[
                                                                      Container(
                                                                        width: min(
                                                                            MediaQuery.of(context).size.width *
                                                                                0.8,
                                                                            400),
                                                                        child:
                                                                            SingleChildScrollView(
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                EdgeInsets.all(16),
                                                                            child:
                                                                                Column(
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
                                                                                            style: TextStyle(color: Colors.white, fontSize: 16),
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
                                                                                              errorMessage = await changeUserName(prefsUserName, _nameController.text);
                                                                                            } catch (e) {
                                                                                              print('Error occurred during saveImage or loadUserImage: $e');
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
                                                                          top:
                                                                              0,
                                                                          bottom:
                                                                              0,
                                                                          left:
                                                                              0,
                                                                          right:
                                                                              0,
                                                                          child:
                                                                              Center(
                                                                            child:
                                                                                CircularProgressIndicator(),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  );
                                                                });
                                                              },
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                    Transform.translate(
                                                      offset:
                                                          Offset(-4.0, -8.0),
                                                      child: TextButton(
                                                        onPressed: () {
                                                          exitRoom(
                                                              prefsUserName,
                                                              prefsUserName);
                                                        },
                                                        style: ButtonStyle(
                                                          padding:
                                                              WidgetStateProperty
                                                                  .all<
                                                                      EdgeInsetsGeometry>(
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    4, 0, 4, 0),
                                                          ),
                                                          backgroundColor:
                                                              WidgetStateProperty
                                                                  .resolveWith<
                                                                      Color?>(
                                                            (Set<WidgetState>
                                                                states) {
                                                              if (states.contains(
                                                                  WidgetState
                                                                      .hovered))
                                                                return Color(
                                                                    0x80EBEBEB); // ホバー時の背景色
                                                              return null; // ホバーしていないときの背景色（無し）
                                                            },
                                                          ),
                                                          shape: WidgetStateProperty
                                                              .all<
                                                                  RoundedRectangleBorder>(
                                                            RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16), // 四隅の丸みの半径を設定
                                                              side: BorderSide
                                                                  .none,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          '退出する',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .labelMedium,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional(-1, 0),
                                    child: Container(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0, 0, 16, 0),
                                      width: 732,
                                      // decoration: BoxDecoration(
                                      //   border: Border.all(
                                      //     color: Colors.blue,
                                      //     width: drawInnerAreaBorderWidthSum / 2,
                                      //   ),
                                      // ),
                                      child: Wrap(
                                        spacing: 16, // ボタン間のスペース
                                        runSpacing: 16, // 行間のスペース
                                        children: cardNumbers.map((cardNumber) {
                                          return SizedBox(
                                            height: 40,
                                            width: 104,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                await saveUserCardSelection(
                                                    prefsUserName, cardNumber);
                                                await updateLastActivityDateTime();
                                                var isResultVisibleModel =
                                                    Provider.of<
                                                            IsResultVisibleModel>(
                                                        context,
                                                        listen: false);
                                                if (isResultVisibleModel
                                                    .resultVisible) {
                                                  calculateCardCounts();
                                                }
                                              },
                                              child: Text(
                                                "${cardNumber} point${double.parse(cardNumber) > 1 ? 's' : ''}",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      color: Color(0xFFFFFFFF),
                                                      fontFamily: "Readex Pro",
                                                    ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Color(0xFF4B39EF),
                                                foregroundColor:
                                                    Color(0xFFFFFFFF),
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(16, 0, 16, 0),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    // decoration: BoxDecoration(
                                    //   border: Border.all(
                                    //     color: Colors.green,
                                    //     width: drawInnerAreaBorderWidthSum / 2,
                                    //   ),
                                    // ),
                                    width: drawAreaWidth,
                                    child: Wrap(
                                      children: [
                                        Container(
                                          width: leftAreaWidth,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Consumer<SelectedCardsModel>(
                                                builder: (context,
                                                    selectedCardModel, child) {
                                                  return Consumer<
                                                      CardCountsModel>(
                                                    builder: (context,
                                                        cardCountsModel,
                                                        child) {
                                                      return Consumer<
                                                          IsResultVisibleModel>(
                                                        builder: (context,
                                                            isResultVisibleModel,
                                                            child) {
                                                          var entries =
                                                              cardCountsModel
                                                                  .cardCounts
                                                                  .entries
                                                                  .toList();
                                                          entries.sort((a, b) {
                                                            var compare = b
                                                                .value
                                                                .compareTo(
                                                                    a.value);
                                                            if (compare != 0)
                                                              return compare;
                                                            return b.key
                                                                .compareTo(
                                                                    a.key);
                                                          });
                                                          // 最大得票数を見つける
                                                          int maxVotes = entries
                                                                  .isNotEmpty
                                                              ? entries
                                                                  .map((e) =>
                                                                      e.value)
                                                                  .reduce((value,
                                                                          element) =>
                                                                      value > element
                                                                          ? value
                                                                          : element)
                                                              : 0; // リストが空の場合は0を返す
                                                          List<Widget> widgets =
                                                              [];
                                                          for (var i = 0;
                                                              i <
                                                                  entries
                                                                      .length;
                                                              i++) {
                                                            if (!isResultVisibleModel
                                                                .resultVisible) {
                                                              continue;
                                                            }
                                                            var entry =
                                                                entries[i];
                                                            EdgeInsetsDirectional
                                                                cardCountsContainerMargin =
                                                                i == 0
                                                                    ? EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0,
                                                                            16,
                                                                            16 +
                                                                                marginLeftPlus,
                                                                            0)
                                                                    : EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0,
                                                                            8,
                                                                            16 +
                                                                                marginLeftPlus,
                                                                            0);
                                                            widgets.add(
                                                              Container(
                                                                margin:
                                                                    cardCountsContainerMargin,
                                                                width: double
                                                                    .infinity,
                                                                height: 80,
                                                                constraints:
                                                                    BoxConstraints(
                                                                  maxWidth:
                                                                      leftAreaWidth,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  border: Border
                                                                      .all(
                                                                    color: Color(
                                                                        0xFFE0E3E7),
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                child: Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          16,
                                                                          0,
                                                                          16,
                                                                          0),
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    children: [
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0,
                                                                            0,
                                                                            16,
                                                                            0),
                                                                        child: maxVotes ==
                                                                                entry.value
                                                                            ? Icon(
                                                                                Icons.star,
                                                                                color: Color(0xFFFFCA27),
                                                                                size: 32,
                                                                              )
                                                                            : Container(
                                                                                width: 32,
                                                                                height: 32,
                                                                              ), // 最大得票数でない場合でも同じスペースを確保
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text('${entry.key} point${double.parse(entry.key) > 1 ? 's' : ''} 選択者',
                                                                                style: Theme.of(context).textTheme.labelMedium),
                                                                            Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              children: [
                                                                                Padding(
                                                                                  padding: EdgeInsetsDirectional.fromSTEB(0, 4, 4, 0),
                                                                                  child: Text(
                                                                                    '${entry.value} 名',
                                                                                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                                                                          fontFamily: "Outfit",
                                                                                        ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      CircularPercentIndicator(
                                                                        percent:
                                                                            entry.value /
                                                                                selectedCardModel.selectedCards.length,
                                                                        radius:
                                                                            45,
                                                                        lineWidth:
                                                                            8,
                                                                        animation:
                                                                            true,
                                                                        animateFromLastPercent:
                                                                            true,
                                                                        progressColor:
                                                                            Color(0xFF4B39EF),
                                                                        backgroundColor:
                                                                            Color(0x4C4B39EF),
                                                                        center:
                                                                            Text(
                                                                          '${(entry.value / selectedCardModel.selectedCards.length * 100).round()}%',
                                                                          style: Theme.of(context)
                                                                              .textTheme
                                                                              .headlineMedium
                                                                              ?.copyWith(
                                                                                fontSize: 10,
                                                                                fontFamily: "Outfit",
                                                                              ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                          return Column(
                                                            children: widgets,
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                              Consumer<SelectedCardsModel>(
                                                builder: (context,
                                                    selectedCardModel, child) {
                                                  return Consumer<
                                                      CardCountsModel>(
                                                    builder: (context,
                                                        cardCountsModel,
                                                        child) {
                                                      return Consumer<
                                                          IsResultVisibleModel>(
                                                        builder: (context,
                                                            isResultVisibleModel,
                                                            child) {
                                                          int userCount =
                                                              selectedCardModel
                                                                  .selectedCards
                                                                  .length;
                                                          int selectedCount =
                                                              selectedCardModel
                                                                  .selectedCards
                                                                  .values
                                                                  .where((userMap) =>
                                                                      userMap['selectedCard']
                                                                          ?.isNotEmpty ??
                                                                      false)
                                                                  .length;
                                                          double averagePoints = selectedCardModel
                                                                  .selectedCards
                                                                  .values
                                                                  .where((userMap) =>
                                                                      userMap['selectedCard']
                                                                          ?.isNotEmpty ??
                                                                      false)
                                                                  .map((userMap) =>
                                                                      double.parse(
                                                                          userMap['selectedCard'] ??
                                                                              '0'))
                                                                  .fold(
                                                                      0.0,
                                                                      (double previousValue,
                                                                              element) =>
                                                                          previousValue +
                                                                          element) /
                                                              (selectedCount > 0
                                                                  ? selectedCount
                                                                  : 1);

                                                          return Container(
                                                            margin: EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0,
                                                                    16,
                                                                    16 +
                                                                        marginLeftPlus,
                                                                    0),
                                                            width:
                                                                double.infinity,
                                                            constraints:
                                                                BoxConstraints(
                                                              maxWidth:
                                                                  leftAreaWidth,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              border:
                                                                  Border.all(
                                                                color: Color(
                                                                    0xFFE0E3E7),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0,
                                                                          0,
                                                                          0,
                                                                          16),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            1,
                                                                            1,
                                                                            1,
                                                                            0),
                                                                    child:
                                                                        Container(
                                                                      width: double
                                                                          .infinity,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .white,
                                                                        boxShadow: [
                                                                          BoxShadow(
                                                                            blurRadius:
                                                                                0,
                                                                            color:
                                                                                Color(0xFFE0E3E7),
                                                                            offset:
                                                                                Offset(
                                                                              0,
                                                                              1,
                                                                            ),
                                                                          )
                                                                        ],
                                                                        borderRadius:
                                                                            BorderRadius.only(
                                                                          bottomLeft:
                                                                              Radius.circular(0),
                                                                          bottomRight:
                                                                              Radius.circular(0),
                                                                          topLeft:
                                                                              Radius.circular(8),
                                                                          topRight:
                                                                              Radius.circular(8),
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            24,
                                                                            0,
                                                                            24,
                                                                            0),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          children: [
                                                                            Expanded(
                                                                              child: Padding(
                                                                                padding: EdgeInsetsDirectional.fromSTEB(0, 16, 0, 16),
                                                                                child: Column(
                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Text('投票結果', style: Theme.of(context).textTheme.titleLarge),
                                                                                    Padding(
                                                                                      padding: EdgeInsetsDirectional.fromSTEB(0, 4, 0, 0),
                                                                                      child: Text(
                                                                                          isResultVisibleModel.resultVisible
                                                                                              ? '投票結果を集計しました'
                                                                                              : userCount > 0 && selectedCount >= userCount
                                                                                                  ? '投票率が100%になりました'
                                                                                                  : '投票を待っています',
                                                                                          style: Theme.of(context).textTheme.labelMedium),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Align(
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            0,
                                                                            0),
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional
                                                                          .fromSTEB(
                                                                              24,
                                                                              24,
                                                                              24,
                                                                              0),
                                                                      child:
                                                                          CircularPercentIndicator(
                                                                        percent: userCount >
                                                                                0
                                                                            ? selectedCount /
                                                                                userCount
                                                                            : 0,
                                                                        radius:
                                                                            120,
                                                                        lineWidth:
                                                                            20,
                                                                        animation:
                                                                            true,
                                                                        animateFromLastPercent:
                                                                            true,
                                                                        progressColor:
                                                                            Color(0xFF4B39EF),
                                                                        backgroundColor:
                                                                            Color(0x4C4B39EF),
                                                                        center:
                                                                            Text(
                                                                          '${userCount > 0 ? (selectedCount / userCount * 100).round() : 0}%',
                                                                          style: Theme.of(context)
                                                                              .textTheme
                                                                              .displaySmall
                                                                              ?.copyWith(
                                                                                fontFamily: "Outfit",
                                                                              ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            24,
                                                                            16,
                                                                            24,
                                                                            0),
                                                                    child: Text(
                                                                        isResultVisibleModel.resultVisible
                                                                            ? '平均値'
                                                                            : '投票率',
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .bodyLarge),
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            24,
                                                                            4,
                                                                            24,
                                                                            8),
                                                                    child: Text(
                                                                        isResultVisibleModel.resultVisible
                                                                            ? "${(averagePoints * 10).round() / 10} point${averagePoints > 1 ? 's' : ''}"
                                                                            : "上記の通りです（${userCount} 人中 ${selectedCount} 人が投票）",
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .labelSmall),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: rightAreaWidth,
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0, 0, 0, 0),
                                            child: Container(
                                              margin: EdgeInsetsDirectional
                                                  .fromSTEB(0, 16,
                                                      16 + marginLeftPlus, 16),
                                              width: double.infinity,
                                              constraints: BoxConstraints(
                                                maxWidth: rightAreaWidth,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Color(0xFFE0E3E7),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    IntrinsicHeight(
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Container(
                                                            width:
                                                                rightAreaHeaderLeftWidth,
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0,
                                                                          0,
                                                                          12,
                                                                          0),
                                                                  child: Text(
                                                                      'プレイヤー情報',
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .headlineMedium),
                                                                ),
                                                                Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0,
                                                                          4,
                                                                          12,
                                                                          0),
                                                                  child: Text(
                                                                      '各プレイヤーのカード選択状況は以下の通りです',
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .labelMedium),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Container(
                                                            width:
                                                                rightAreaHeaderRightWidth,
                                                            child: Align(
                                                              alignment: Alignment
                                                                  .centerRight,
                                                              child: Wrap(
                                                                spacing:
                                                                    16, // ボタン間のスペース
                                                                runSpacing:
                                                                    16, // 行間のスペース
                                                                children: [
                                                                  Container(
                                                                    child:
                                                                        SizedBox(
                                                                      height:
                                                                          40,
                                                                      width:
                                                                          120,
                                                                      child:
                                                                          ElevatedButton(
                                                                        onPressed:
                                                                            () {
                                                                          updateLastActivityDateTime();

                                                                          changeResultVisible(
                                                                              true);
                                                                        },
                                                                        child:
                                                                            Text(
                                                                          "結果を表示",
                                                                          style: Theme.of(context)
                                                                              .textTheme
                                                                              .titleSmall
                                                                              ?.copyWith(
                                                                                color: Color(0xFFFFFFFF),
                                                                              ),
                                                                        ),
                                                                        style: ElevatedButton
                                                                            .styleFrom(
                                                                          backgroundColor:
                                                                              Color(0xFF4B39EF),
                                                                          foregroundColor:
                                                                              Color(0xFFFFFFFF),
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              16,
                                                                              0,
                                                                              16,
                                                                              0),
                                                                          shape:
                                                                              RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(8),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    child:
                                                                        SizedBox(
                                                                      height:
                                                                          40,
                                                                      width:
                                                                          120,
                                                                      child:
                                                                          ElevatedButton(
                                                                        onPressed:
                                                                            () async {
                                                                          await clearAllSelectedCards();
                                                                          updateLastActivityDateTime();

                                                                          changeResultVisible(
                                                                              false);
                                                                        },
                                                                        child:
                                                                            Text(
                                                                          "結果をクリア",
                                                                          style: Theme.of(context)
                                                                              .textTheme
                                                                              .titleSmall
                                                                              ?.copyWith(
                                                                                color: Color(0xFFFFFFFF),
                                                                              ),
                                                                        ),
                                                                        style: ElevatedButton
                                                                            .styleFrom(
                                                                          backgroundColor:
                                                                              Color(0xFF4B39EF),
                                                                          foregroundColor:
                                                                              Color(0xFFFFFFFF),
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              16,
                                                                              0,
                                                                              16,
                                                                              0),
                                                                          shape:
                                                                              RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(8),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0, 16, 0, 0),
                                                      child: Container(
                                                        width: double.infinity,
                                                        height: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Color(0xFFF1F4F8),
                                                          borderRadius:
                                                              BorderRadius.only(
                                                            bottomLeft:
                                                                Radius.circular(
                                                                    0),
                                                            bottomRight:
                                                                Radius.circular(
                                                                    0),
                                                            topLeft:
                                                                Radius.circular(
                                                                    8),
                                                            topRight:
                                                                Radius.circular(
                                                                    8),
                                                          ),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(16,
                                                                      0, 16, 0),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              Expanded(
                                                                flex: 6,
                                                                child: Text(
                                                                    'プレイヤー',
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .labelSmall),
                                                              ),
                                                              Expanded(
                                                                flex: 3,
                                                                child: Text(
                                                                  '選択カード',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .labelSmall,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 3,
                                                                child: Text(
                                                                  '状態',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .labelSmall,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 2,
                                                                child: Padding(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          right:
                                                                              8.0),
                                                                  child: Text(
                                                                    '処理',
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .labelSmall,
                                                                    textAlign:
                                                                        TextAlign
                                                                            .end,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Consumer<
                                                        SelectedCardsModel>(
                                                      builder: (context,
                                                          selectedCardsModel,
                                                          child) {
                                                        List<Widget> widgets =
                                                            [];
                                                        for (var entry
                                                            in selectedCardsModel
                                                                .selectedCards
                                                                .entries
                                                                .toList()
                                                                .asMap()
                                                                .entries) {
                                                          MapEntry<
                                                                  String,
                                                                  Map<String,
                                                                      String?>>
                                                              cardEntry =
                                                              entry.value;
                                                          String
                                                              cardEntryUserName =
                                                              cardEntry.key;
                                                          String?
                                                              cardEntryUserImageUrl =
                                                              cardEntry.value[
                                                                  'imageUrl'];
                                                          String
                                                              cardEntrySelectedCard =
                                                              cardEntry.value[
                                                                      'selectedCard'] ??
                                                                  '';
                                                          String
                                                              previousSelectedCard =
                                                              previousSelectedCards[
                                                                      cardEntryUserName] ??
                                                                  '';
                                                          bool _changeColor =
                                                              (cardEntrySelectedCard !=
                                                                      '' &&
                                                                  previousSelectedCard !=
                                                                      cardEntrySelectedCard);

                                                          AnimationController
                                                              _animationController =
                                                              AnimationController(
                                                            duration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        1000),
                                                            vsync: this,
                                                          );

                                                          final colorTween =
                                                              TweenSequence([
                                                            TweenSequenceItem(
                                                              tween: ColorTween(
                                                                  begin: Color(
                                                                      0xFFFFFFFF),
                                                                  end: Color(
                                                                      0x804B39EF)),
                                                              weight: 1,
                                                            ),
                                                            TweenSequenceItem(
                                                              tween: ColorTween(
                                                                  begin: Color(
                                                                      0x804B39EF),
                                                                  end: Color(
                                                                      0xFFFFFFFF)),
                                                              weight: 1,
                                                            ),
                                                          ]);

                                                          final _colorAnimation =
                                                              colorTween.animate(
                                                                  _animationController);

                                                          _animationController
                                                              .addStatusListener(
                                                                  (status) {
                                                            if (status ==
                                                                AnimationStatus
                                                                    .completed) {
                                                              previousSelectedCards[
                                                                      cardEntryUserName] =
                                                                  cardEntrySelectedCard;
                                                            }
                                                          });

                                                          if (_changeColor) {
                                                            _animationController
                                                                .forward();
                                                          }

                                                          Widget widget =
                                                              Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0,
                                                                        0,
                                                                        0,
                                                                        1),
                                                            child:
                                                                AnimatedBuilder(
                                                              animation:
                                                                  _colorAnimation,
                                                              builder: (context,
                                                                  child) {
                                                                return Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: _colorAnimation
                                                                        .value,
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        blurRadius:
                                                                            0,
                                                                        color: Color(
                                                                            0xFFF1F4F8),
                                                                        offset:
                                                                            Offset(
                                                                          0,
                                                                          1,
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                  child:
                                                                      Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            16,
                                                                            0,
                                                                            16,
                                                                            0),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children: [
                                                                        Expanded(
                                                                          flex:
                                                                              6,
                                                                          child:
                                                                              Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0,
                                                                                8,
                                                                                12,
                                                                                8),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              children: [
                                                                                Padding(
                                                                                  padding: EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                                                                                  child: ClipRRect(
                                                                                    borderRadius: BorderRadius.circular(40),
                                                                                    child: cardEntryUserImageUrl != null
                                                                                        ? CachedNetworkImage(
                                                                                            fadeInDuration: Duration(milliseconds: 500),
                                                                                            fadeOutDuration: Duration(milliseconds: 500),
                                                                                            imageUrl: cardEntryUserImageUrl,
                                                                                            width: 32,
                                                                                            height: 32,
                                                                                            fit: BoxFit.cover,
                                                                                          )
                                                                                        : Image.asset(
                                                                                            'assets/images/default_face.png',
                                                                                            width: 32,
                                                                                            height: 32,
                                                                                            fit: BoxFit.cover,
                                                                                          ),
                                                                                  ),
                                                                                ),
                                                                                Expanded(
                                                                                  child: Padding(
                                                                                    padding: EdgeInsetsDirectional.fromSTEB(4, 0, 0, 0),
                                                                                    child: Column(
                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        Text(
                                                                                          '${cardEntryUserName}',
                                                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                                                fontWeight: FontWeight.w700,
                                                                                              ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Expanded(
                                                                          flex:
                                                                              3,
                                                                          child:
                                                                              LayoutBuilder(
                                                                            builder:
                                                                                (BuildContext context, BoxConstraints constraints) {
                                                                              return Padding(
                                                                                padding: EdgeInsets.symmetric(horizontal: (constraints.maxWidth - 48) / 2),
                                                                                child: Container(
                                                                                  color: (!Provider.of<IsResultVisibleModel>(context, listen: true).resultVisible && cardEntrySelectedCard != '' && cardEntryUserName != prefsUserName) ? Color(0xFFF1F4F8) : null,
                                                                                  child: Text(
                                                                                    (!Provider.of<IsResultVisibleModel>(context, listen: true).resultVisible && cardEntrySelectedCard != '' && cardEntryUserName != prefsUserName) ? '' : '${cardEntrySelectedCard}',
                                                                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                                                          fontFamily: "Outfit",
                                                                                        ),
                                                                                    textAlign: TextAlign.center,
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                          ),
                                                                        ),
                                                                        Expanded(
                                                                          flex:
                                                                              3,
                                                                          child:
                                                                              Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Container(
                                                                                height: 32,
                                                                                decoration: BoxDecoration(
                                                                                  color: (cardEntrySelectedCard.isEmpty) ? Color(0xFFF1F4F8) : Color(0x4D39D2C0),
                                                                                  borderRadius: BorderRadius.circular(40),
                                                                                  border: Border.all(
                                                                                    color: (cardEntrySelectedCard.isEmpty) ? Color(0x00000000) : Color(0xFF39D2C0),
                                                                                  ),
                                                                                ),
                                                                                alignment: AlignmentDirectional(0, 0),
                                                                                child: Padding(
                                                                                  padding: EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
                                                                                  child: Text((cardEntrySelectedCard.isEmpty) ? '未選択' : '選択済', style: Theme.of(context).textTheme.bodyMedium),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Expanded(
                                                                          flex:
                                                                              2,
                                                                          child:
                                                                              Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.end,
                                                                            children: [
                                                                              PopupMenuButton(
                                                                                offset: Offset(0, 40),
                                                                                icon: Icon(
                                                                                  Icons.more_vert,
                                                                                  color: Color(0xFF57636C),
                                                                                ),
                                                                                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                                                                                  PopupMenuItem(
                                                                                    value: 'exit',
                                                                                    child: Text(cardEntryUserName == prefsUserName ? '退出する' : '退出させる', style: Theme.of(context).textTheme.labelMedium),
                                                                                  ),
                                                                                ],
                                                                                onSelected: (value) {
                                                                                  if (value == 'exit') {
                                                                                    exitRoom(cardEntryUserName, prefsUserName);
                                                                                  }
                                                                                },
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          );

                                                          widgets.add(widget);
                                                        }
                                                        return ListView(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          shrinkWrap: true,
                                                          scrollDirection:
                                                              Axis.vertical,
                                                          children: widgets,
                                                        );
                                                      },
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (marginAreaWidth > 0 &&
                                            marginLeftPlus <= 0)
                                          Container(
                                            width: marginAreaWidth,
                                            // decoration: BoxDecoration(
                                            //   border: Border.all(
                                            //     color: Colors.red,
                                            //     width: marginBorderWidthSum / 2,
                                            //   ),
                                            // ),
                                          ),
                                        //),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            } else {
              return Scaffold(
                appBar: AppBar(
                  title: Text('部屋が見つかりませんでした'),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      MyRouterDelegate routerDelegate =
                          Router.of(context).routerDelegate as MyRouterDelegate;
                      routerDelegate.setNewRoutePath('/');
                    },
                  ),
                ),
                body: Center(
                  child: Text('戻るボタンより、homeに戻ってください'),
                ),
              );
            }
          }
        });
  }

  void initState() {
    super.initState();
    initFuture = Future.wait([
      roomScreenCheckRoomExists(),
      checkUserName(true),
      loadUserImage(),
      checkPrefsUserImage(),
    ]);

    cardNumbers = generateFibonacciNumbers(89); // ここでカード群を生成します

    _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        var newCards = Map<String, Map<String, String?>>.fromEntries(
            snapshot.docs.map((doc) {
          var userName = doc.data()['userName']?.toString() ?? '';
          var selectedCard = doc.data()['selectedCard']?.toString() ?? '';
          var imageUrl = doc.data()['imageUrl']?.toString();
          return MapEntry(
              userName, {'selectedCard': selectedCard, 'imageUrl': imageUrl});
        }).cast<MapEntry<String, Map<String, String?>>>());
        Provider.of<SelectedCardsModel>(context, listen: false)
            .setSelectedCards(newCards);
      }
    });

    _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        var newCounts = <String, int>{};
        var data = snapshot.data();
        var cardCounts = data?['cardCounts'];
        if (cardCounts is Map<String, dynamic>) {
          for (var entry in cardCounts.entries) {
            var key = entry.key;
            var value = entry.value;
            if (value is int) {
              newCounts[key] = value;
            }
          }
        }
        Provider.of<CardCountsModel>(context, listen: false)
            .setCardCountsModel(newCounts);
      }
    });

    _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        var data = snapshot.data();
        var newResultVisible = data?['resultVisible'];
        Provider.of<IsResultVisibleModel>(context, listen: false)
            .setResultVisible(newResultVisible);
      }
    });
  }

  void navigateToNameInputScreen() {
    saveRoomID();
    MyRouterDelegate routerDelegate =
        Router.of(context).routerDelegate as MyRouterDelegate;
    routerDelegate.setNewRoutePath('/nameInput');
  }

  Future<bool> roomScreenCheckRoomExists() async {
    // 部屋の存在チェックを行う非同期関数
    // 実際のチェック処理をここに書く
    await Future.delayed(Duration(milliseconds: 100)); // 仮の遅延
    final roomExists = await checkRoomExists(widget.roomID.toString());
    if (!roomExists) {
      return false;
    } else {
      return true;
    }
  }

  Future<String> checkUserName(bool checkUserExistsInUsers) async {
    final prefsUserName = await getUserName(checkUserExistsInUsers);
    if (prefsUserName.isEmpty) {
      navigateToNameInputScreen();
    }

    return prefsUserName;
  }

  void saveRoomID() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('roomID', widget.roomID.toString());
  }

  // ユーザー名を取得する関数
  Future<String> getUserName(bool checkUserExistsInUsers) async {
    final prefs = await SharedPreferences.getInstance();
    String userName = prefs.getString('userName') ?? '';

    if (userName != '') {
      // usersコレクションとexitsコレクションの両方でユーザー名をキーとするドキュメントが存在しないか確認
      bool userExistsInUsers = await isExistUserInUsers(userName);
      bool userExistsInExits = await isExistUserInExits(userName);

      // どちらのコレクションにもドキュメントが存在しない場合、deleteUserName関数を呼び出し、空文字を返す
      if (!userExistsInUsers && !userExistsInExits && checkUserExistsInUsers) {
        await deleteUserName();
        return '';
      } else {
        return userName;
      }
    } else {
      return '';
    }
  }

  // usersコレクションにユーザー名が存在するか確認する関数
  Future<bool> isExistUserInUsers(String userName) async {
    final userCollection = _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .collection('users');
    final userDoc =
        await userCollection.where('userName', isEqualTo: userName).get();
    return userDoc.docs.isNotEmpty;
  }

  // exitsコレクションにユーザー名が存在するか確認する関数
  Future<bool> isExistUserInExits(String userName) async {
    final exitsCollection = _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .collection('exits');
    final exitsDoc =
        await exitsCollection.where('userName', isEqualTo: userName).get();
    return exitsDoc.docs.isNotEmpty;
  }

  // ユーザー名を削除する関数
  Future<void> deleteUserName() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userName');
  }

  // フィボナッチ数列を生成する関数
  List<String> generateFibonacciNumbers(int n) {
    List<double> fibonacciNumbers = [0, 0.5, 1];
    List<String> fibonacciStrings =
        fibonacciNumbers.map((number) => number.toString()).toList();
    while (true) {
      double nextNumber = fibonacciNumbers[fibonacciNumbers.length - 1] +
          fibonacciNumbers[fibonacciNumbers.length - 2];
      if (nextNumber > n) {
        break;
      }
      nextNumber = nextNumber.round().toDouble();

      fibonacciNumbers.add(nextNumber);
      fibonacciStrings.add(nextNumber.toString());
    }
    return fibonacciStrings;
  }

  // ユーザーがカードを選択したときに、その情報をFirestoreに保存する関数
  Future<void> saveUserCardSelection(String userName, String cardNumber) async {
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
          .update({
        'selectedCard': cardNumber,
      });
    }
  }

  // ポーカー結果のクリア処理
  Future<void> clearAllSelectedCards() async {
    final userCollection = _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .collection('users');

    final usersSnapshot = await userCollection.get();

    for (var userDoc in usersSnapshot.docs) {
      await userDoc.reference.update({'selectedCard': ''});
    }

    Map<String, int> cardCounts = {}; // cardCountsを初期化

    await _firestore.collection('rooms').doc(widget.roomID.toString()).update({
      'cardCounts': cardCounts,
    });
  }

  // 各カードの選択回数を計算する関数
  Future<void> calculateCardCounts() async {
    Map<String, int> cardCounts = {}; // cardCountsを初期化

    final userCollection = _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .collection('users');

    final usersSnapshot = await userCollection.get();

    // カードの選択リストをループして、各カードの選択回数を増やす
    for (var userDoc in usersSnapshot.docs) {
      String? card = userDoc.data()['selectedCard'];
      if (card != null && card.isNotEmpty) {
        if (!cardCounts.containsKey(card)) {
          cardCounts[card] = 0;
        }
        cardCounts[card] = (cardCounts[card] ?? 0) + 1;
      }
    }

    // cardCountsをリストに変換し、ソートする
    var sortedCardCounts = cardCounts.entries.toList()
      ..sort((a, b) => a.value != b.value
          ? b.value.compareTo(a.value)
          : b.key.compareTo(a.key));

    Map<String, dynamic> cardCountsMap = {};
    for (var entry in sortedCardCounts) {
      cardCountsMap[entry.key] = entry.value;
    }

    await _firestore.collection('rooms').doc(widget.roomID.toString()).update({
      'cardCounts': cardCountsMap,
    });

    // cardCountsのデータが0件の場合は、isResultVisibleをfalseにする
    if (cardCountsMap.isEmpty) {
      await _firestore
          .collection('rooms')
          .doc(widget.roomID.toString())
          .update({
        'resultVisible': false,
      });
    }
  }

  // 結果を表示・非表示を切り替える関数
  Future<void> changeResultVisible(bool newResultVisible) async {
    int selectedCount = Provider.of<SelectedCardsModel>(context, listen: false)
        .selectedCards
        .values
        .where((selectedCard) => selectedCard.isNotEmpty)
        .length;

    if (newResultVisible == true) {
      if (selectedCount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投票者が0名なので、表示する結果がありません。')),
        );
        return;
      }
      calculateCardCounts();
    }
    await _firestore.collection('rooms').doc(widget.roomID.toString()).update({
      'resultVisible': newResultVisible,
    });
  }

  // 何かアクティビティがあるたびに呼び出す
  Future<void> updateLastActivityDateTime() async {
    await _firestore.collection('rooms').doc(widget.roomID.toString()).update({
      'lastActivityDateTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> exitRoom(String exitedUser, String exiter) async {
    // 退出させられた人と退出させた人の情報をFirestoreに保存
    var exitDocs = await _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .collection('exits')
        .where('userName', isEqualTo: exitedUser)
        .get();
    if (exitDocs.docs.isNotEmpty) {
      await _firestore
          .collection('rooms')
          .doc(widget.roomID.toString())
          .collection('exits')
          .doc(exitDocs.docs.first.id)
          .update({
        'exiter': exiter,
      });
    } else {
      await _firestore
          .collection('rooms')
          .doc(widget.roomID.toString())
          .collection('exits')
          .add({
        'userName': exitedUser,
        'exiter': exiter,
      });
    }

    // 退出させられた人の情報を削除
    var userDocs = await _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .collection('users')
        .where('userName', isEqualTo: exitedUser)
        .get();
    for (var doc in userDocs.docs) {
      await _firestore
          .collection('rooms')
          .doc(widget.roomID.toString())
          .collection('users')
          .doc(doc.id)
          .delete();
    }

    await calculateCardCounts();

    await updateLastActivityDateTime();
  }

  // exiterを取得する関数
  Future<String> getExiter(String exitedUser) async {
    final exitDocs = await _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .collection('exits')
        .where('userName', isEqualTo: exitedUser)
        .get();

    if (exitDocs.docs.isNotEmpty) {
      return exitDocs.docs.first.data()['exiter'] ?? '不明なプレイヤー';
    } else {
      return '不明なプレイヤー';
    }
  }

  // exitsのドキュメントを削除する関数
  Future<void> deleteExitedUser(String exitedUser) async {
    var exitDocs = await _firestore
        .collection('rooms')
        .doc(widget.roomID.toString())
        .collection('exits')
        .where('userName', isEqualTo: exitedUser)
        .get();
    for (var doc in exitDocs.docs) {
      await _firestore
          .collection('rooms')
          .doc(widget.roomID.toString())
          .collection('exits')
          .doc(doc.id)
          .delete();
    }
  }

  // usersコレクションのドキュメントのimageUrlフィールドを削除する関数
  Future<void> deleteUserImageUrl(String userName) async {
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
          .update({
        'imageUrl': FieldValue.delete(),
      });
    }
  }

  // ユーザーの名前を変更する関数
  Future<String> changeUserName(
      String currentUserName, String newUserName) async {
    // ユーザー名が変更されていない場合は、処理を終了
    if (currentUserName == newUserName) {
      print('ユーザー名変更なし。処理しない');
      return '';
    }

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
      initFuture = Future.wait([
        roomScreenCheckRoomExists(),
        checkUserName(false),
        loadUserImage(),
        checkPrefsUserImage(),
      ]);
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

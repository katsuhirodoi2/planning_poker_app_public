import 'package:flutter/material.dart';
import 'package:planning_poker_app/routes/my_router_delegate.dart';
import 'dart:math';
import 'package:planning_poker_app/platform_functions_export.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:planning_poker_app/functions/room_common_functions.dart';
import 'package:planning_poker_app/functions/common_functions.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _roomIDController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // ブラウザのタブに表示されるタイトルを設定
    PlatformFunctions().setTitle('プランニングポーカー');

    return Scaffold(
      appBar: AppBar(
        title: Text('プランニングポーカー'),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 40,
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                      });
                      createRoom(context);
                    },
                    child: Text(
                      '部屋を作る',
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
                SizedBox(height: 20), // ボタン間のスペース
                Container(
                  width: 200, // ここでテキストフィールドの幅を制限します
                  child: TextField(
                    controller: _roomIDController,
                    decoration: InputDecoration(
                      labelText: '部屋番号を入力',
                      labelStyle: TextStyle(
                        fontSize: 12, // フォントサイズを小さくする
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20), // ボタン間のスペース
                SizedBox(
                  height: 40,
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                      });
                      joinRoom(context);
                    },
                    child: Text(
                      '部屋に入る',
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
            Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
    // ,);
  }

  // 部屋番号の総数
  final TOTAL_ROOMS = ROOM_END_NUM - ROOM_START_NUM + 1;

  // 空き部屋を探す関数
  Future<int> findAvailableRoom() async {
    final firestore = FirebaseFirestore.instance;
    DateTime inactivityReleaseTime =
        DateTime.now().subtract(Duration(minutes: INACTIVITY_RELEASE_MINUTES));

    QuerySnapshot querySnapshot = await firestore
        .collection('rooms')
        .where('lastActivityDateTime',
            isLessThanOrEqualTo: inactivityReleaseTime)
        .orderBy('roomID')
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      // inactivityReleaseMinutes以上活動がない部屋がない場合、-1を返す
      return -1;
    } else {
      // inactivityReleaseMinutes以上活動がない部屋がある場合、その部屋IDを返す
      return querySnapshot.docs.first['roomID'];
    }
  }

  // 部屋を作成する関数
  Future<void> createRoom(BuildContext context) async {
    int roomID = await findAvailableRoom();

    if (roomID == -1) {
      // roomsのlastActivityDateTimeが最も古い部屋を見つける処理
      final firestore = FirebaseFirestore.instance;
      DateTime oldestLastActivity = await firestore
          .collection('rooms')
          .orderBy('lastActivityDateTime')
          .limit(1)
          .get()
          .then((snapshot) => snapshot.docs.first['lastActivityDateTime']);

      // 現在時刻との差を計算
      int oldestLastActivityAndNowDiff =
          DateTime.now().difference(oldestLastActivity).inMinutes;

      // INACTIVITY_RELEASE_MINUTES - oldestLastActivityAndNowDiffとINACTIVITY_RELEASE_MINUTESのうち小さい方を選ぶ
      int releaseTime = min(
          INACTIVITY_RELEASE_MINUTES - oldestLastActivityAndNowDiff,
          INACTIVITY_RELEASE_MINUTES);

      setState(() {
        _isLoading = false;
      });

      String message =
          '現在プランニングポーカーの部屋が満室（${TOTAL_ROOMS}部屋中${TOTAL_ROOMS}部屋使用中）です。あと、${releaseTime}分で部屋が空く可能性があります。';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } else {
      // 部屋を作成する処理
      String currentOrigin = PlatformFunctions().getOrigin();
      String newRoomUrl = '$currentOrigin/room/$roomID';

      // Firestoreへの参照を作成
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // ユーザーブロック用のランダム文字列を作成
      String forUserBlockString = generateRandomString(16, false);

      // 部屋の情報を保存する
      await firestore.collection('rooms').doc(roomID.toString()).set({
        'roomID': roomID,
        'lastActivityDateTime': FieldValue.serverTimestamp(),
        'resultVisible': false,
        'forUserBlockString': forUserBlockString,
      });

      // 部屋の下のusersコレクションを取得
      var usersCollection = firestore
          .collection('rooms')
          .doc(roomID.toString())
          .collection('users');

      // 部屋の下のexitsコレクションを取得
      var exitsCollection = firestore
          .collection('rooms')
          .doc(roomID.toString())
          .collection('exits');

      // usersコレクションのすべてのドキュメントを取得
      var usersSnapshot = await usersCollection.get();

      // exitsコレクションのすべてのドキュメントを取得
      var exitsSnapshot = await exitsCollection.get();

      // バッチを作成
      var batch = firestore.batch();

      // 各ユーザードキュメントをバッチに追加して削除
      for (var doc in usersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 各exitsドキュメントをバッチに追加して削除
      for (var doc in exitsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // バッチをコミットして削除を実行
      await batch.commit();

      // /public/images/$roomID/ 配下のファイルを全て削除
      FirebaseStorage storage = FirebaseStorage.instance;
      String path = 'public/images/$roomID/';
      ListResult result = await storage.ref(path).listAll();
      List<Future<void>> deleteFutures =
          result.items.map((item) => item.delete()).toList();
      await Future.wait(deleteFutures);

      setState(() {
        _isLoading = false;
      });

      // 設定されている場合、部屋を作成した後、新しい画面に移動する
      saveRoomID(roomID.toString());
      MyRouterDelegate routerDelegate =
          Router.of(context).routerDelegate as MyRouterDelegate;
      routerDelegate.setNewRoutePath('/nameInput');
    }
  }

  Future<void> joinRoom(BuildContext context) async {
    int? roomID = int.tryParse(_roomIDController.text);

    if (roomID != null) {
      final roomExists =
          await checkRoomExists(roomID.toString()); // データベースに部屋が存在するか確認
      if (roomExists) {
        saveRoomID(roomID.toString());

        setState(() {
          _isLoading = false;
        });

        MyRouterDelegate routerDelegate =
            Router.of(context).routerDelegate as MyRouterDelegate;
        routerDelegate.setNewRoutePath('/nameInput');
      } else {
        setState(() {
          _isLoading = false;
        });
        // ルームが存在しない場合、エラーメッセージを表示する
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('部屋番号${roomID}は作成されていません。')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });

      // 部屋IDが無効な場合のエラーハンドリング
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '部屋番号が無効です。${ROOM_START_NUM}〜${ROOM_END_NUM}の間で入力してください。')),
      );
    }
  }

  void saveRoomID(String roomID) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('roomID', roomID);
  }
}

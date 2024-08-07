import 'package:flutter/material.dart';
import 'package:planning_poker_app/platform_functions_export.dart';
import 'package:planning_poker_app/routes/my_router_delegate.dart';

class UnknownScreen extends StatefulWidget {
  UnknownScreen();

  @override
  _UnknownScreenState createState() => _UnknownScreenState();
}

class _UnknownScreenState extends State<UnknownScreen> {
  @override
  Widget build(BuildContext context) {
    // ブラウザのタブに表示されるタイトルを設定
    PlatformFunctions().setTitle('ページが見つかりません - プランニングポーカー');

    return Scaffold(
      appBar: AppBar(
        title: Text('ページが見つかりません'),
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

  bool roomExists = true;

  void initState() {
    super.initState();
  }
}

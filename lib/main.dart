import 'package:flutter/material.dart';
import 'package:planning_poker_app/models/card_counts_model.dart';
import 'package:planning_poker_app/models/is_result_visible_model.dart';
import 'package:planning_poker_app/models/selected_cards_model.dart';
import 'package:planning_poker_app/models/theme_provider.dart';
import 'package:planning_poker_app/routes/navigation_state.dart';
import 'package:planning_poker_app/routes/my_route_information_parser.dart';
import 'package:planning_poker_app/routes/my_router_delegate.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:planning_poker_app/platform_functions_export.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "XXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
          authDomain: "XXXXXXXXXXXXXXXXXXX.firebaseapp.com",
          projectId: "XXXXXXXXXXXXXXXXXXX",
          storageBucket: "XXXXXXXXXXXXXXXXXXX.appspot.com",
          messagingSenderId: "XXXXXXXXXXXX",
          appId: "1:XXXXXXXXXXXX:web:XXXXXXXXXXXXXXXXXXXX",
          measurementId: "G-XXXXXXXXXX"),
    );
  } else {
    await Firebase.initializeApp().then((_) {}).catchError((error) {
      print('Failed to initialize Firebase: $error');
    });
  }

  setPathUrlStrategy();
  await initUniLinks();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SelectedCardsModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => CardCountsModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => IsResultVisibleModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            routeInformationParser: MyRouteInformationParser(),
            routerDelegate: MyRouterDelegate(navigationState),
            theme: themeProvider.themeData,
            builder: (context, child) {
              return Scaffold(
                resizeToAvoidBottomInset: true,
                body: child,
              );
            },
          );
        },
      ),
    ),
  );
}

Future<void> initUniLinks() async {
  if (!kIsWeb) {
    // モバイルプラットフォームの場合、uni_linksを使用してディープリンクを取得
    linkStream.listen((String? link) {
      print('Stream link: $link'); // デバッグ用ログ出力
      handleLink(link);
    }, onError: (err) {
      print('Stream link error: $err'); // デバッグ用ログ出力
      // Handle exception by warning the user their action did not succeed
    });

    try {
      String? initialLink = await getInitialLink();
      print('Initial link: $initialLink'); // デバッグ用ログ出力
      handleLink(initialLink);
    } on PlatformException {
      print('Initial link PlatformException'); // デバッグ用ログ出力
      // Handle exception by warning the user their action did not succeed
    }
  }
}

void handleLink(String? link) {
  print('Received link: $link'); // デバッグ用ログ出力

  if (link != null) {
    var uri = Uri.parse(link);

    // URLスキームとホストが期待するものであることを確認
    if (uri.scheme == 'https' &&
        uri.host == '[スクリプト設置ドメイン]' &&
        (uri.path == '/open-ios-app.php' ||
            uri.path == '/open-android-app.php')) {
      var roomID = uri.queryParameters['roomID'];

      print('Room ID: $roomID'); // デバッグ用ログ出力

      if (roomID != null) {
        // NavigationStateに新しいパスを設定
        print('Setting path to /room/$roomID');
        navigationState.setPath('/room/$roomID');
      }
    }
  }
}

class TitleUpdateObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name == '/') {
      PlatformFunctions().setTitle('Home Screen');
    }
  }
}

final navigationState = NavigationState();
final MyRouteInformationParser _routeInformationParser =
    MyRouteInformationParser();
final MyRouterDelegate _routerDelegate = MyRouterDelegate(navigationState);

class PlanningPokerApp extends StatelessWidget {
  const PlanningPokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: navigationState,
      child: MaterialApp.router(
        routeInformationParser: MyRouteInformationParser(),
        routerDelegate: MyRouterDelegate(navigationState),
      ),
    );
  }
}

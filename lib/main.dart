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
    await Firebase.initializeApp();
  }

  setPathUrlStrategy();
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

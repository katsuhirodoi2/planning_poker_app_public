import 'package:flutter/material.dart';
import 'package:planning_poker_app/models/card_counts_model.dart';
import 'package:planning_poker_app/models/is_result_visible_model.dart';
import 'package:planning_poker_app/models/selected_cards_model.dart';
import 'package:planning_poker_app/routes/navigation_state.dart';
import 'package:planning_poker_app/routes/my_route_information_parser.dart';
import 'package:planning_poker_app/routes/my_router_delegate.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_strategy/url_strategy.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      ],
      child: MaterialApp.router(
        routeInformationParser: MyRouteInformationParser(),
        routerDelegate: MyRouterDelegate(navigationState),
        theme: ThemeData(
          textTheme: TextTheme(
            displayLarge: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: Color(0xFF14181B),
            ),
            displayMedium: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Color(0xFF14181B),
            ),
            displaySmall: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF14181B),
            ),
            headlineLarge: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 36,
              fontWeight: FontWeight.w400,
              color: Color(0xFF14181B),
            ),
            headlineMedium: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Color(0xFF14181B),
            ),
            headlineSmall: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF14181B),
            ),
            titleLarge: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: Color(0xFF14181B),
            ),
            titleMedium: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Color(0xFF14181B),
            ),
            titleSmall: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF14181B),
            ),
            labelLarge: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Color(0xFF57636C),
            ),
            labelMedium: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF57636C),
            ),
            labelSmall: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF57636C),
            ),
            bodyLarge: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF14181B),
            ),
            bodyMedium: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF14181B),
            ),
            bodySmall: TextStyle(
              fontFamily: 'M PLUS 1',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF14181B),
            ),
          ),
        ),
      ),
    ),
  );
}

class TitleUpdateObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name == '/') {
      html.document.title = 'Home Screen';
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

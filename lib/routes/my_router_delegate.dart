import 'package:flutter/material.dart';
import 'package:planning_poker_app/routes/navigation_state.dart';
import 'package:planning_poker_app/screens/home_screen.dart';
import 'package:planning_poker_app/screens/name_input_screen.dart';
import 'package:planning_poker_app/screens/room_screen.dart';
import 'package:planning_poker_app/screens/unknown_screen.dart';

class MyRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  final NavigationState navigationState;
  final GlobalKey<NavigatorState> navigatorKey;

  String? currentPath;

  MyRouterDelegate(this.navigationState)
      : navigatorKey = GlobalKey<NavigatorState>() {
    navigationState.addListener(notifyListeners);
  }

  @override
  String? get currentConfiguration => navigationState.currentPath;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        if (navigationState.currentPath == null ||
            navigationState.currentPath == '/')
          MaterialPage(child: HomeScreen()),
        if (navigationState.currentPath == '/nameInput')
          MaterialPage(child: NameInputScreen()),
        if (navigationState.currentPath?.startsWith('/room/') ?? false)
          MaterialPage(
              child: RoomScreen(
                  roomID:
                      int.parse(navigationState.currentPath!.substring(6)))),
        if (!(navigationState.currentPath == null ||
            navigationState.currentPath == '/' ||
            navigationState.currentPath == '/nameInput' ||
            (navigationState.currentPath?.startsWith('/room/') ?? false)))
          MaterialPage(child: UnknownScreen()),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        navigationState.setPath('/');
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(String path) async {
    navigationState.setPath(path);
    currentPath = path;
  }
}

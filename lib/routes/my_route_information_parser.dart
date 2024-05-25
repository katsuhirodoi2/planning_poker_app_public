import 'package:flutter/material.dart';

class MyRouteInformationParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(
      RouteInformation routeInformation) async {
    return routeInformation.location ?? '/';
  }

  @override
  RouteInformation restoreRouteInformation(String path) {
    return RouteInformation(location: path);
  }
}

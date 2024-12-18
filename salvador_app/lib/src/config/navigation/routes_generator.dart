import 'package:illyricum_music/src/features/main_view/main_view.dart';
import 'package:flutter/material.dart';

class RouteGenerator {

  static Route<dynamic> generateRoutes(RouteSettings settings) {
    switch(settings.name) {
      case MainView.routeName:
        return MaterialPageRoute(builder: (_) => const MainView());
      default:
        return MaterialPageRoute(builder: (context) => Scaffold(
          body: Center(
            child: Text("Not found ${settings.name}"),
            ),
          )
        );
    }
  }
}
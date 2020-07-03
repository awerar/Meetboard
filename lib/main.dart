import 'package:flutter/material.dart';
import 'package:meetboard/Screens/MainPage/main_page.dart';
import 'package:meetboard/themes.dart';
import 'package:meetboard/routes.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    timeDilation = 10;

    return MaterialApp(
      title: "Meetboard",
      initialRoute: MainPage.routeName,
      routes: routes,
      theme: getTheme(),
    );
  }
}

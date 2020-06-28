import 'package:flutter/material.dart';
import 'package:meetboard/Screens/MainPage/main_page.dart';
import 'package:meetboard/themes.dart';
import 'package:meetboard/routes.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Meetboard",
      theme: getTheme(),
      initialRoute: MainPage.routeName,
      routes: routes,
    );
  }
}

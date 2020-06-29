import 'package:flutter/material.dart';
import 'package:meetboard/Screens/ViewActivityPage/view_activity_page.dart';
import 'package:meetboard/Screens/MainPage/main_page.dart';
import "package:meetboard/Screens/CreatePage/create_activity_page.dart";

final Map<String, Widget Function(BuildContext)> routes = {
  MainPage.routeName: (context) => MainPage(),
  CreateActivityPage.routeName: (context) => CreateActivityPage(),
  ViewActivityPage.routeName: (context) => ViewActivityPage()
};
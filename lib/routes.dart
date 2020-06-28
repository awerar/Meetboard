import 'package:flutter/material.dart';
import 'package:meetboard/Screens/MainPage/main_page.dart';
import "package:meetboard/Screens/CreatePage/create_activity_page.dart";

final Map<String, Widget Function(BuildContext)> routes = {
  "/": (context) => MainPage(),
  "/create_activity_page": (context) => CreateActivityPage()
};
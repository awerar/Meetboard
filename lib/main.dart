import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity_list_model.dart';
import 'package:meetboard/Screens/MainPage/main_page.dart';
import 'package:meetboard/themes.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:provider/provider.dart';
import 'package:meetboard/Models/user_model.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    timeDilation = 1;

    UserModel userModel = UserModel(navigatorKey);
    ActivityListModel activityListModel = ActivityListModel(userModel);

    return MultiProvider(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: "Meetboard",
        home: MainPage(),
        theme: getTheme(),
      ),
      providers: [
        ChangeNotifierProvider.value(value: userModel),
        ChangeNotifierProvider.value(value: activityListModel)
      ],
    );
  }
}
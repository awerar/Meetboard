import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity_list_model.dart';
import 'package:meetboard/Screens/MainPage/main_page.dart';
import 'package:meetboard/themes.dart';
import 'package:meetboard/routes.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:provider/provider.dart';
import 'package:meetboard/Models/user_model.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    timeDilation = 1;
    final UserModel userModel = UserModel();
    final ActivityListModel activityListModel = ActivityListModel(userModel);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userModel),
        ChangeNotifierProvider.value(value: activityListModel)
      ],
      child: MaterialApp(
        title: "Meetboard",
        initialRoute: MainPage.routeName,
        routes: routes,
        theme: getTheme(),
      ),
    );
  }
}
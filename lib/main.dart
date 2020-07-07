import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/user_activity_list_model.dart';
import 'package:meetboard/Screens/MainPage/main_page.dart';
import 'package:meetboard/themes.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:provider/provider.dart';
import 'package:meetboard/Models/user_model.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    timeDilation = 1;
    final UserModel userModel = UserModel();
    final UserActivityListModel activityListModel = UserActivityListModel(userModel);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userModel),
        ChangeNotifierProvider.value(value: activityListModel)
      ],
      child: MaterialApp(
        title: "Meetboard",
        home: MainPage(),
        theme: getTheme(),
      ),
    );
  }
}
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Screens/JoinActivity/join_activity_page.dart';
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

    _handleDynamicLinks();

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

  void _handleDynamicLinks() async {
    PendingDynamicLinkData initialData = await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialData != null && initialData.link != null) _handleDeepLink(initialData.link);

    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData data) {
          if(data.link != null) _handleDeepLink(data.link);
          return;
        }
    );
  }

  void _handleDeepLink(Uri link) {
    if (link.host == "meetboard") {
      if (link.pathSegments.join("/") == "activities/join") {
        debugPrint(link.queryParameters.toString());
        navigatorKey.currentState.push(MaterialPageRoute(
            builder: (context) => JoinActivityPage(),
            settings: RouteSettings(arguments: link.queryParameters)
        ));
      }
    }
  }
}
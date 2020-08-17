import 'dart:collection';

import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:meetboard/Models/activity_list_model.dart';
import 'package:meetboard/Models/settings_model.dart';
import 'package:meetboard/Models/user_model.dart';
import 'package:meetboard/Screens/ActivityPage/settings_tab.dart';
import 'package:meetboard/Screens/EditActivityPage/edit_activity_page.dart';
import 'package:meetboard/Screens/ActivityPage/people_tab.dart';
import 'package:meetboard/themes.dart';
import 'package:provider/provider.dart';

class ActivityPage extends StatefulWidget {
  static const String routeName = "/view_activity_page";

  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  UserActivityData _user;
  ValueReference<Activity> activityReference;

  @override
  void didChangeDependencies() {
    activityReference = ModalRoute.of(context).settings.arguments;
    assert(activityReference != null);

    try {
      _user = activityReference.value.users[Provider
          .of<UserModel>(context)
          .user
          .uid];
    } catch(e) {
      _user = activityReference.value.users.values.elementAt(0);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityListModel>(builder: (context, activityList, child) {
      Activity activity = activityReference.value;

      return DefaultTabController(
        length: 4,
        child: Builder(
          builder: (context) {
            SettingsModel settings = SettingsModel(_getSettings());

            return ChangeNotifierProvider.value(
              value: settings,
              child: Scaffold(
                  appBar: AppBar(
                    centerTitle: true,
                    title: Text(activity.name,),
                    actions: <Widget>[
                      //if (_user.role == ActivityRole.Owner) IconButton(icon: Icon(Icons.edit), onPressed: _editActivity,)
                    ],
                    bottom: TabBar(
                      tabs: <Widget>[
                        Tab(icon: Icon(Icons.info), text: "Info",),
                        Tab(icon: Icon(Icons.people), text: "People",),
                        Tab(icon: Icon(Icons.playlist_add_check), text: "Items",),
                        Tab(icon: Icon(Icons.settings), text: "Settings",),
                      ],
                    ),
                  ),
                  body: TabBarView(
                      children: <Widget>[
                        Container(),
                        PeopleTab(activity, _user),
                        Container(),
                        SettingsTab(_user, activity, settings),
                      ]
                  )
              ),
            );
          },
        ),
      );
    });
  }

  Future<void> _editActivity() {
    return  Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => EditActivityPage(),
            settings: RouteSettings(arguments: EditActivityPageSettings(appbarLabel: "Edit Activity", baseActivity: activityReference.value, handleNewActivity: (newActivity) async {
              if (newActivity != null && newActivity is Activity) Provider.of<ActivityListModel>(context).updateActivity(newActivity);
            }))
        )
    );
  }

  Map<String, SettingsField> _getSettings() {
    return {
      "coming": SettingsField<bool>(
          initialValue: _user.coming,
          getSaveData: (value) {
            return {
              activityReference.value.getUserDataDocument(_user.uid): {
                "coming": value
              }
            };
          }
      )
    };
  }
}
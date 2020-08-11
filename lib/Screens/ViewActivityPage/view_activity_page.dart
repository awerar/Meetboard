import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:meetboard/Models/activity_list_model.dart';
import 'package:meetboard/Models/user_model.dart';
import 'package:meetboard/Screens/EditActivityPage/edit_activity_page.dart';
import 'package:meetboard/themes.dart';
import 'package:provider/provider.dart';

class ViewActivityPage extends StatefulWidget {
  static const String routeName = "/view_activity_page";

  @override
  _ViewActivityPageState createState() => _ViewActivityPageState();
}

class _ViewActivityPageState extends State<ViewActivityPage> {
  bool _coming;
  ValueReference<Activity> activityReference;

  @override
  void didChangeDependencies() {
    activityReference = ModalRoute.of(context).settings.arguments;
    assert(activityReference != null);

    _coming = activityReference.value.users[Provider.of<UserModel>(context).user.uid].coming;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityListModel>(builder: (context, activityList, child) {
      Activity activity = activityReference.value;

      return Scaffold(
        appBar: AppBar(
          title: Hero(child: Text(activity.name,), tag: activity.hashCode.toString() + "Title",),
          actions: <Widget>[
            if (activity.users[Provider.of<UserModel>(context).user.uid].role == ActivityRole.Owner) IconButton(icon: Icon(Icons.edit), onPressed: () async {
              var newActivity = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditActivityPage(),
                  settings: RouteSettings(arguments: EditActivityPageSettings(appbarLabel: "Edit Activity", baseActivity: activity))
                )
              );
              if (newActivity != null && newActivity is Activity) activityList.updateActivity(newActivity);
            },)
          ],
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          children: <Widget>[
            Builder(builder: (BuildContext context) {
              TextStyle style = Theme.of(context).textTheme.subtitle1.copyWith(inherit: true);

              return DefaultTextStyle(
                style: style,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("Activity id: "),
                    GestureDetector(
                      onTap: () => ClipboardManager.copyToClipBoard(activity.id).then((value) => Scaffold.of(context).showSnackBar(SnackBar(content: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text("Copied to Clipboard"),
                          ],
                        ), duration: Duration(seconds: 1),))),
                      child: Text(activity.id, style: style.copyWith(color: Theme.of(context).colorScheme.secondary),)
                    )
                  ],
                ),
              );
            },),
            RaisedButton(
              color: _coming ? green : red,
              onPressed: () {
                setState(() {
                  _coming = !_coming;
                });
              }, child: Text(_coming ? "Coming" : "Not Coming", style: Theme.of(context).textTheme.subtitle2.copyWith(color: Colors.white),),
            )
          ],
        ),
      );
    });
  }
}
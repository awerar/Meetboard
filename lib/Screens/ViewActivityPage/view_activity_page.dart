import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:meetboard/Models/activity_list_model.dart';
import 'package:meetboard/Screens/EditActivityPage/edit_activity_page.dart';
import 'package:provider/provider.dart';

class ViewActivityPage extends StatelessWidget {
  static const String routeName = "/view_activity_page";

  @override
  Widget build(BuildContext context) {
    String activityId = ModalRoute.of(context).settings.arguments;
    assert(activityId != null && activityId != "");

    return Consumer<ActivityListModel>(builder: (context, activityList, child) {
      Activity activity = activityList.getActivity(activityId);

      return Scaffold(
        appBar: AppBar(
          title: Hero(child: Text(activity.name,), tag: activity.hashCode.toString() + "Title",),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.edit), onPressed: () async {
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
      );
    });
  }
}
import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity.dart';

class CreateActivityButton extends StatelessWidget {
  final void Function(Activity) onCreatedActivity;
  CreateActivityButton(this.onCreatedActivity);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
        tooltip: "Create new activity",
        onPressed: () => _createActivity(context),
        icon: Icon(Icons.add),
        label: Text("Create Activity")
    );
  }

  void _createActivity(BuildContext context) async {
    Activity result = await Navigator.of(context).pushNamed("/create_activity_page") as Activity;
    if (result != null) {
      onCreatedActivity(result);
      Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text("Activity Successfully Created"),
            behavior: SnackBarBehavior.fixed,
            action: SnackBarAction(
              label: "View",
              onPressed: (){},
              textColor: Colors.orange,
            ),
          )
      );
    }
  }
}
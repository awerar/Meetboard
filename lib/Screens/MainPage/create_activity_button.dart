import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:meetboard/Screens/ViewActivityPage/view_activity_page.dart';

class CreateActivityButton extends StatefulWidget {
  final void Function(Activity) onCreatedActivity;
  CreateActivityButton(this.onCreatedActivity);

  @override
  _CreateActivityButtonState createState() => _CreateActivityButtonState();
}

class _CreateActivityButtonState extends State<CreateActivityButton> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      heroTag: "CreateButton",
      overlayColor: Colors.black,
      child: Icon(_open ? Icons.close : Icons.add),
      backgroundColor: _open ? Colors.grey : null,
      onOpen: () {
        setState(() {
          _open = true;
        });
      },
      onClose: () {
        setState(() {
          _open = false;
        });
      },
      children: _buildChildren()
    );
  }

  List<SpeedDialChild> _buildChildren() {
    return <SpeedDialChild>[
      _createChild("Join Activity", Icon(Icons.person_add,), null),
      _createChild("Create Activity", Icon(Icons.create,), _createActivity)
    ];
  }

  SpeedDialChild _createChild(String label, Icon icon, void Function() onTap) {
    return SpeedDialChild(
        label: label,
        labelStyle: Theme.of(context).textTheme.bodyText1.copyWith(color: Theme.of(context).colorScheme.onSurface),
        child: icon,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        labelBackgroundColor: Theme.of(context).colorScheme.surface,
        onTap: onTap
    );
  }

  void _createActivity() async {
    Activity result = await Navigator.of(context).pushNamed("/create_activity_page", arguments: {"Create"}) as Activity;
    widget.onCreatedActivity(result);

    //TODO: FIX
    if (result != null) {
      //onCreatedActivity(result);
      Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text("Activity Successfully Created"),
            behavior: SnackBarBehavior.fixed,
            action: SnackBarAction(
              label: "View",
              onPressed: () => Navigator.of(context).pushNamed(ViewActivityPage.routeName, arguments: result.id),
            ),
          )
      );
    }
  }
}

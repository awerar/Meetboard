import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:meetboard/Models/activity_preview.dart';
import 'package:meetboard/Models/activity_list_model.dart';
import 'package:meetboard/Screens/EditActivityPage/edit_activity_page.dart';
import 'package:provider/provider.dart';

class MainPageSpeedDial extends StatefulWidget {

  @override
  _MainPageSpeedDialState createState() => _MainPageSpeedDialState();
}

class _MainPageSpeedDialState extends State<MainPageSpeedDial> {
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
    ActivityPreview result = await Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => EditActivityPage(),
            settings: RouteSettings(arguments: EditActivityPageSettings(appbarLabel: "Create a new activity"))
        )
    ) as ActivityPreview;

    if (result != null) Provider.of<ActivityListModel>(context).createActivity(result);
  }
}

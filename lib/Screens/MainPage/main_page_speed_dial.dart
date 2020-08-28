import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:meetboard/Screens/EditActivityPage/edit_activity_page.dart';
import 'package:meetboard/Screens/JoinActivity/join_activity_page.dart';

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
      _createChild("Join Activity", Icon(Icons.person_add,), _joinActivity),
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
    await Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => EditActivityPage(),
            settings: RouteSettings(arguments: EditActivityPageSettings(appbarLabel: "Create a new activity", handleNewActivity: (a) => null))
        )
    );
  }

  void _joinActivity() async {
    var result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => JoinActivityPage()));
    if (result == null) return;

    if(result as bool) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Successfully joined activity"),
      ));
    } else {
      Scaffold.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Builder(builder: (con) => Text("Error when joining activity. \n(Make sure you haven't joined already)",
          style: DefaultTextStyle.of(con).style.copyWith(color: Theme.of(context).colorScheme.onError),)),
      ));
    }
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/Activity.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Screens/CreatePage/create_activity_page.dart';
import 'package:meetboard/navigator_utils.dart';


class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _activities = [
    Activity("Meeting with the boys", DateTime.utc(2020, 6, 30, 13)),
    Activity("Hike", DateTime.utc(2020, 7, 5, 10)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scheduled Activities", style: Theme.of(context).textTheme.headline1),
        centerTitle: true,
      ),
      body: _buildActivityList(),
      floatingActionButton: _buildCreateButton()
    );
  }

  Widget _buildActivityList() {
    List<Widget> tiles = _activities.map(_buildActivityTile).toList();
    return ListView(children: ListTile.divideTiles(tiles: tiles, context: context).toList(), padding: EdgeInsets.fromLTRB(15, 0, 0, 0));
  }

  Widget _buildActivityTile(Activity activity) {
    return ListTile(title: Text(activity.name), trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(DateFormat("MMMEd").add_jm().format(activity.time)),
        Icon(Icons.arrow_forward_ios),
      ],
    ));
  }

  Widget _buildCreateButton() {
    return FloatingActionButton.extended(
        tooltip: "Create new activity",
        onPressed: _pressCreateActivity,
        icon: Icon(Icons.add),
        label: Text("Create Activity")
    );
  }

  void _pressCreateActivity() {
    Navigator.of(context).push(CreateTransitionTo(CreatePage((activity) {
      setState(() {
        _activities.add(activity);
      });
    })));
  }
}
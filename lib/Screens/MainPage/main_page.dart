import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meetboard/Models/Activity.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Screens/CreatePage/create_page.dart';
import 'package:meetboard/main.dart';
import 'package:meetboard/themes.dart';


class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final activities = [
    Activity("Meeting with the boys", DateTime.utc(2020, 6, 30, 13)),
    Activity("Hike", DateTime.utc(2020, 7, 5, 10)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scheduled Activities", style: TextStyle(fontSize: 25),),
        centerTitle: true,
      ),
      body: _buildActivityList(),
      floatingActionButton: _buildCreateButton()
    );
  }

  Widget _buildActivityList() {
    List<Widget> tiles = activities.map(_buildActivityTile).toList();
    return ListView(children: ListTile.divideTiles(tiles: tiles, context: context).toList());
  }

  Widget _buildActivityTile(Activity activity) {
    return ListTile(title: Text(activity.name), trailing: Text(DateFormat("MMMEd").add_jm().format(activity.time)));
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
    Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CreatePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = Offset(1, 0);
            var end = Offset.zero;
            var curve = Curves.easeOutQuart;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        )
    );
  }
}
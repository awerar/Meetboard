import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Components/double_floating_action_button.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:meetboard/Screens/CreatePage/create_activity_page.dart';

class ViewActivityPage extends StatefulWidget {
  static const String routeName = "/view_activity_page";

  @override
  _ViewActivityPageState createState() => _ViewActivityPageState();
}

class _ViewActivityPageState extends State<ViewActivityPage>{
  Activity _activity;

  @override
  Widget build(BuildContext context) {
    if (_activity == null) {
      _activity = ModalRoute.of(context).settings.arguments;
      assert(_activity != null);
    }

    return Scaffold(
      appBar: AppBar(
        title: Hero(child: Text(_activity.name,), tag: _activity.hashCode.toString() + "Title",),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.edit), onPressed: _edit,)
        ],
      ),
    );
  }

  void _edit() {
    Navigator.of(context).pushNamed(CreateActivityPage.routeName, arguments: {"Save", _activity}).then((activity) {
      setState(() {
        _activity = activity;
      });
      Firestore.instance.collection("Activities").document(_activity.code).updateData(_activity.fireStoreMap());
    });
  }
}

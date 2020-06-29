import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Screens/ViewActivityPage/view_activity_page.dart';
import 'package:meetboard/Screens/MainPage/create_activity_button.dart';


class MainPage extends StatefulWidget {
  static const String routeName = "/";
  
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Activity> _activities;

  @override
  void initState() {
    Firestore.instance.collection("Activities").getDocuments().then((query) {
      setState(() {
        _activities = query.documents.map((document) {
          return Activity(document.data["Name"], document.data["Time"].toDate(), code: document.documentID, coming: document.data.containsKey("Coming") ? document.data["Coming"] : true);
        }).toList();
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Scheduled Activities", style: Theme.of(context).textTheme.headline1),
          centerTitle: true,
        ),
        body: _buildActivityList(),
        floatingActionButton: CreateActivityButton((activity) {
          setState(() {
            _activities.add(activity);
            _sortActivities();
          });

          Firestore.instance.collection("/Activities").add(activity.fireStoreMap());
        }),
    );
  }

  Widget _buildActivityList() {
    if (_activities != null && _activities.length > 0) {
      List<Widget> tiles = _activities.map(_buildActivityTile).toList();
      return ListView(
          children: ListTile.divideTiles(tiles: tiles, context: context)
              .toList(),
          padding: EdgeInsets.fromLTRB(15, 0, 0, 0));
    } else {
      return Container(
        child: Align(
          child: Text("No activities scheduled", style: Theme.of(context).textTheme.bodyText2.apply(color: Colors.grey, fontSizeFactor: 1.2),), alignment: Alignment.topCenter,
        ),
        padding: EdgeInsets.only(top: 15)
        ,);
    }
  }

  Widget _buildActivityTile(Activity activity) {
    bool coming = activity.coming;

    return ListTile(
        title: Text(activity.name),
        subtitle: !coming ? Text("Not Coming", style: TextStyle(color: Colors.red),) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(DateFormat("MMMEd").add_jm().format(activity.time)),
            Icon(Icons.arrow_forward_ios),
          ],
        ),
      onTap: ()
      async {
        await Navigator.of(context).pushNamed(
            ViewActivityPage.routeName, arguments: activity);
        setState(()=>null);
      },
    );
  }

  void _addActivity(Activity activity) {
    setState(() {
      _activities.add(activity);
      _sortActivities();
    });
  }

  void _sortActivities() {
    _activities.sort((a, b) => a.time.millisecondsSinceEpoch - b.time.millisecondsSinceEpoch);
  }
}
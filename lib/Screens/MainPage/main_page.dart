import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Screens/ViewActivityPage/view_activity_page.dart';
import 'package:meetboard/Screens/MainPage/create_activity_button.dart';
import 'package:meetboard/themes.dart';
import 'package:timer_builder/timer_builder.dart';


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
      for(DocumentSnapshot d in query.documents.toList()) {
        if ((d.data["Time"].toDate() as DateTime).millisecondsSinceEpoch < DateTime.now().millisecondsSinceEpoch) {
          //TODO remove from Firestore
          query.documents.remove(d);
        }
      }

      setState(() {
        _activities = query.documents.map((document) {
          return Activity(document.data["Name"], document.data["Time"].toDate(), code: document.documentID, coming: document.data.containsKey("Coming") ? document.data["Coming"] : true);
        }).toList();
        _sortActivities();
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Planned Activities",),
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
      return ListView(children: tiles, padding: EdgeInsets.all(8),);
    } else {
      return Container(
        child: Align(
          child: Text("No activities scheduled", style: Theme.of(context).textTheme.subtitle1.copyWith(inherit: true),), alignment: Alignment.topCenter,
        ),
        padding: EdgeInsets.only(top: 15)
        ,);
    }
  }

  Widget _buildActivityTile(Activity activity) {
    bool coming = activity.coming;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(ViewActivityPage.routeName, arguments: activity);
      },
        child:Card(
            child: SizedBox(
                height: 72,
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(activity.name, style: Theme.of(context).textTheme.subtitle1.copyWith(inherit: true), ),
                            SizedBox(height: 4,),
                            Text(DateFormat((activity.time.year != DateTime.now().year ? "y" : "") + "MMMEd").add_jm().format(activity.time), style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.grey, inherit: true),),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            _buildTimeLeftText(activity, context),
                            Text(!coming ? "Not Coming" : "", style: Theme.of(context).textTheme.bodyText2.copyWith(inherit: true, color: Theme.of(context).colorScheme.error),)
                          ],
                        )
                      ],
                    )
                )
            )
        )
    );
  }

  Widget _buildTimeLeftText(Activity activity, BuildContext context) {
    return TimerBuilder.periodic(
      Duration(seconds: 1),
      builder: (context) {
        Duration duration = activity.time.difference(DateTime.now());
        return Text("${duration.inDays}d ${duration.inHours - duration.inDays * 24}h ${duration.inMinutes - duration.inHours * 60}m", style: Theme.of(context).textTheme.bodyText2.copyWith(inherit: true, color: Colors.grey),);
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
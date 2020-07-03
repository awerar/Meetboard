import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Screens/ViewActivityPage/view_activity_page.dart';
import 'package:meetboard/Screens/MainPage/create_activity_button.dart';
import 'package:meetboard/themes.dart';


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
      List<int> categoryDays = [
        0, 1, 6, 30, 365, 99999999
      ];

      List<String> categoryNames = [
        "Today", "Tomorrow", "Next Week", "Next Month", "Next Year", "In the future"
      ];

      List<Widget> tiles = List<Widget>();
      int category = 0;
      bool first = true;
      for(Activity activity in _activities) {
        DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        int dayDiff = activity.time.difference(today).inDays;

        bool newCategory = false;
        while(dayDiff > categoryDays[category] && category < categoryDays.length) {
          category++;
          newCategory = true;
        }

        if (newCategory || first) {
          if (!first) tiles.add(SizedBox(height: 15,));
          tiles.add(Container(
              child: Text(categoryNames[category], style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.grey, inherit: true), textAlign: TextAlign.left),
            padding: EdgeInsets.only(left: 20),
          ));
          tiles.add(Divider());
        }
        tiles.add(ActivityCard(activity: activity));
        first = false;
      }

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

class ActivityCard extends StatefulWidget {
  final Activity activity;
  ActivityCard({@required this.activity});

  @override
  _ActivityCardState createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  Timer _refresher;
  Duration _timeLeft;

  @override
  void initState() {
    _timeLeft = _getTimeLeft();

    _refresher = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft = _getTimeLeft();
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _refresher.cancel();
    super.dispose();
  }

  Duration _getTimeLeft() {
    return widget.activity.time.difference(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    String timeLeftLabel = "";

    int years = (_timeLeft.inDays ~/ 365);
    if (_timeLeft.inDays >= 365) {
      timeLeftLabel = "In $years ${years > 1 ? "years" : "year"} & ${_timeLeft.inDays % 365} days";
    } else if (_timeLeft.inDays >= 2) {
      timeLeftLabel = "In ${_timeLeft.inDays} days";
    } else if (_timeLeft.inDays == 1) {
      timeLeftLabel = "In one day & ${_timeLeft.inHours % 24}h";
    } else {
      timeLeftLabel = "In ${_timeLeft.inHours}h ${(_timeLeft.inMinutes % 60) + 1}m";
    }

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        splashColor: Theme.of(context).primaryColor.withAlpha((255 * 0.6).floor()),
        onTap: () => Navigator.of(context).pushNamed(ViewActivityPage.routeName, arguments: widget.activity),
        splashFactory: InkRipple.splashFactory,
          child: IntrinsicHeight(child:  Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              SizedBox(
                width: 25,
                child: Stack(
                  children: <Widget>[
                    Container(
                      color: widget.activity.coming ? green : red,
                      constraints: BoxConstraints.expand(),
                    ),
                    Align(child: Icon(Icons.chevron_left, color: Colors.white,), alignment: Alignment.center,)
                  ],
                ),
              ),
              Flexible(
                  child: ListTile(
                    title: Text(widget.activity.name, ),
                    subtitle: Text(DateFormat(DateFormat.YEAR_ABBR_MONTH_WEEKDAY_DAY).add_jm().format(widget.activity.time) + "\n$timeLeftLabel"),
                    trailing: Text(widget.activity.coming ? "" : "Not Coming", style: theme.textTheme.bodyText2.copyWith(inherit: true, color: theme.colorScheme.error),),
                    isThreeLine: true,
                  )
              )
            ],
          )
          )
      ),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      elevation: 2,
    );
  }
}

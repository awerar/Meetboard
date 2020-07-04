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
  GlobalKey _cardKey = GlobalKey();
  bool _visible = true;

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
    return Visibility(
      visible: _visible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Card(
        margin: EdgeInsets.all(8),
        key: _cardKey,
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          splashColor: Theme.of(context).primaryColor.withAlpha((255 * 0.6).floor()),
          onTap: _transitionToViewPage,
          splashFactory: InkRipple.splashFactory,
            child: _buildCardContents()
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildCardContents() {
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

    return IntrinsicHeight(
        child:  Row(
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
                  title: Hero(child: Text(widget.activity.name, ), tag: widget.activity.hashCode.toString() + "Title",),
                  subtitle: Text(DateFormat(DateFormat.YEAR_ABBR_MONTH_WEEKDAY_DAY).add_jm().format(widget.activity.time) + "\n$timeLeftLabel"),
                  trailing: Text(widget.activity.coming ? "" : "Not Coming", style: theme.textTheme.bodyText2.copyWith(inherit: true, color: theme.colorScheme.error),),
                  isThreeLine: true,
                )
            )
          ],
        )
    );
  }

  void _transitionToViewPage() {
    final transitionDuration = Duration(milliseconds: 300);
    setState(() {
      _visible = false;
    });

    EdgeInsets padding = (_cardKey.currentWidget as Card).margin;

    final RenderBox cardRenderBox = _cardKey.currentContext.findRenderObject();
    final Size cardSize = Size(cardRenderBox.size.width - padding.horizontal, cardRenderBox.size.height - padding.vertical);
    Offset cardOffset = cardRenderBox.localToGlobal(Offset.zero);
    cardOffset = Offset(cardOffset.dx + padding.left, cardOffset.dy + padding.top);

    Tween<Size> sizeTween = Tween<Size>(
      begin: cardSize,
      end: MediaQuery.of(context).size
    );

    Tween<Offset> positionTween = Tween<Offset>(
      begin: cardOffset,
      end: Offset.zero
    );

    Tween<double> elevationTween = Tween<double>(
      begin: (_cardKey.currentWidget as Card).elevation,
      end: 25
    );

    assert((_cardKey.currentWidget as Card).shape is RoundedRectangleBorder);

    BorderRadiusTween borderRadiusTween = BorderRadiusTween(
      begin: ((_cardKey.currentWidget as Card).shape as RoundedRectangleBorder).borderRadius,
      end: BorderRadius.zero
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: transitionDuration,
        pageBuilder: (context, animation, secondaryAnimation) => ViewActivityPage(),
        settings: RouteSettings(arguments: widget.activity),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (animation.value == 1) return ViewActivityPage();

          Animation easeInOutAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut
          );

          Animation easeOutAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCirc
          );

          BorderRadius borderRadius = borderRadiusTween.evaluate(easeInOutAnim);
          Size size = sizeTween.evaluate(easeInOutAnim);
          Offset position = positionTween.evaluate(easeInOutAnim);
          double elevation = elevationTween.evaluate(easeOutAnim);

          return Stack(
            children: <Widget>[
              Positioned(
                left: position.dx,
                top: position.dy,
                child: Card(
                  clipBehavior: Clip.hardEdge,
                  key: UniqueKey(),
                  shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  margin: EdgeInsets.all(0),
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: _buildCardContents(),
                  ),
                  elevation: elevation,
                ),
              ),
              Positioned(
                height: size.height,
                width: size.width,
                left: position.dx,
                top: position.dy,
                child: Opacity(
                  opacity: animation.value,
                  child: ClipRRect(child: ViewActivityPage(), borderRadius: borderRadius,),
                ),
              )
            ],
          );
        }
      )
    ).then((value) {
      _visible = true;
    });
  }
}

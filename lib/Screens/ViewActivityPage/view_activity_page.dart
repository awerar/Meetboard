import 'dart:collection';

import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:meetboard/Models/activity_list_model.dart';
import 'package:meetboard/Models/user_model.dart';
import 'package:meetboard/Screens/EditActivityPage/edit_activity_page.dart';
import 'package:meetboard/themes.dart';
import 'package:provider/provider.dart';

class ViewActivityPage extends StatefulWidget {
  static const String routeName = "/view_activity_page";

  @override
  _ViewActivityPageState createState() => _ViewActivityPageState();
}

class _ViewActivityPageState extends State<ViewActivityPage> {
  bool _coming, _savedComing;
  bool _saving = false;
  UserActivityData _user;
  ValueReference<Activity> activityReference;

  @override
  void didChangeDependencies() {
    activityReference = ModalRoute.of(context).settings.arguments;
    assert(activityReference != null);

    try {
      _user = activityReference.value.users[Provider
          .of<UserModel>(context)
          .user
          .uid];
    } catch(e) {
      _user = activityReference.value.users.values.elementAt(0);
    }
    _savedComing = _user.coming;
    _coming = _savedComing;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityListModel>(builder: (context, activityList, child) {
      Activity activity = activityReference.value;

      return IgnorePointer(
        ignoring: _saving,
        child: WillPopScope(
          onWillPop: () async {
            return Future.doWhile(() => _saving).then((value) => true);
          },
          child: Scaffold(
              appBar: AppBar(
                title: Hero(child: Text(activity.name,), tag: activity.hashCode.toString() + "Title",),
                actions: <Widget>[
                  if (_user.role == ActivityRole.Owner) IconButton(icon: Icon(Icons.edit), onPressed: () async {
                    await Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => EditActivityPage(),
                            settings: RouteSettings(arguments: EditActivityPageSettings(appbarLabel: "Edit Activity", baseActivity: activity, handleNewActivity: (newActivity) async {
                              if (newActivity != null && newActivity is Activity) activityList.updateActivity(newActivity);
                            }))
                        )
                    );
                  },)
                ],
              ),
              body: ListView(
                children: <Widget>[
                  Opacity(child: LinearProgressIndicator(), opacity: _saving ? 1 : 0,),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    child: Column(
                      children: <Widget>[
                        Builder(builder: (BuildContext context) {
                          TextStyle style = Theme.of(context).textTheme.subtitle1.copyWith(inherit: true);

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              DefaultTextStyle(
                                style: style,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text("Activity Code: "),
                                    GestureDetector(
                                        onTap: () => ClipboardManager.copyToClipBoard(activity.id).then((value) => Scaffold.of(context).showSnackBar(SnackBar(content: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text("Copied to Clipboard"),
                                          ],
                                        ), duration: Duration(seconds: 1),))),
                                        child: Text(activity.id, style: style.copyWith(color: Theme.of(context).colorScheme.secondary),)
                                    )
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.help),
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text("Activity Code"),
                                          content: Text("If you share this code with your friends, they can enter it on their devices to join this activity"),
                                          actions: <Widget>[
                                            FlatButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: Text("Got it!"),
                                            )
                                          ],
                                        );
                                      }
                                  );
                                },
                              )
                            ],
                          );
                        },),
                        RaisedButton(onPressed: () => _swapComingState(activity), color: _willCome(_user) ? green : red,),
                        UserList(activity, _user, _willCome,)
                      ],
                    ),
                  ),
                ],
              )
          ),
        ),
      );
    });
  }

  Future<void> _save(Activity activity) async {
    setState(() {
      _saving = true;
    });

    if (_coming != _savedComing) {
      _savedComing = _coming;
      await Firestore.instance.collection("activities").document(activity.id).collection("users").document(_user.uid).updateData({
        "coming": _coming
      });
    }

    setState(() {
      _saving = false;
    });
  }

  void _swapComingState(Activity activity) {
    if (_saving) return;

    setState(() {
      _coming = !_coming;
    });
    _save(activity);
  }

  bool _willCome(UserActivityData user) {
    return (user.uid != _user.uid && user.coming) || (user.uid == _user.uid && _coming);
  }
}

class UserList extends StatelessWidget {
  final bool Function(UserActivityData) willCome;
  final Activity activity;
  final UserActivityData user;

  UserList(this.activity, this.user, this.willCome, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
        children: <Widget>[_buildSubheader("People Coming")]
          ..add(UserColumn(activity.users.values.where((element) => willCome(element)).toList(), user.uid, (u) => true))
          ..add(SizedBox(height: 20,))..add(_buildSubheader("People Not Coming"))
          ..add(UserColumn(activity.users.values.where((element) => !willCome(element)).toList(), user.uid, (u) => false))
    );
  }

  Widget _buildSubheader(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Builder(
        builder: (context) => Text(
          text,
          style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.grey),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}

class UserColumn extends StatefulWidget {
  final Map<String, UserActivityData> users;
  final HashSet<String> uids;
  final String userUID;
  final bool Function(UserActivityData) willCome;

  final Duration animationDuration = Duration(milliseconds: 900);

  UserColumn(List<UserActivityData> users, this.userUID, this.willCome, {Key key}) :
        uids = HashSet<String>.from(users.map((e) => e.uid)),
        this.users = Map<String, UserActivityData>.fromIterable(users, key: (user) => user.uid),
        super(key: key);

  @override
  _UserColumnState createState() => _UserColumnState();
}

class _UserColumnState extends State<UserColumn> with TickerProviderStateMixin {
  List<UserActivityData> users;

  HashMap<UserActivityData, AnimationController> controllers;

  @override
  void didUpdateWidget(UserColumn oldWidget) {
    List<String> newUIDs = widget.uids.where((element) => !oldWidget.uids.contains(element)).toList();
    List<String> oldUIDs = oldWidget.uids.where((element) => !widget.uids.contains(element)).toList();

    oldUIDs.forEach((element) => _removeUser(oldWidget.users[element]));
    newUIDs.forEach((element) => _addUser(widget.users[element]));

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    users = widget.users.values.toList();
    sortUsers();

    controllers = HashMap.fromIterable(users, key: (u) => u, value: (u) => AnimationController(value: 1, vsync: this, duration: widget.animationDuration));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: users.map((user) => AnimatedBuilder(builder: (context, child) => _buildElement(user, context, controllers[user]), animation: controllers[user],)).toList(),
    );
  }

  void sortUsers() {
    users.sort((a, b) {
      if (a.uid == widget.userUID) return -1;
      else if (b.uid == widget.userUID) return 1;
      else return a.username.compareTo(b.username);
    });
  }

  Widget _buildElement(UserActivityData user, BuildContext context, AnimationController controller) {
    return SizeTransition(
      axisAlignment: -1,
      child: Builder(builder: (context) {
        bool isUser = user.uid == widget.userUID;

        return Card(
          child: ListTile(
            title: !isUser ? Text(user.username) : Builder(builder: (context) => Text("You (${user.username})")),
            subtitle: user.role == ActivityRole.Owner ? Text("Owner") : null,
            leading: CircleAvatar(
              backgroundImage: NetworkImage('https://robohash.org/${user.uid}'),
              child: Align(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.willCome(user) ? green : red,
                    border: Border.fromBorderSide(BorderSide(width: 1, color: Colors.white))
                  ),
                  child: Flex(
                    direction: Axis.horizontal,
                    children: <Widget>[
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: Icon(widget.willCome(user) ? Icons.check : Icons.close, color: Colors.white,),
                        ),
                      ),
                    ],
                  ),
                ),
                alignment: Alignment.bottomRight,
              ),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)
          ),
        );
      }),
      axis: Axis.vertical,
      sizeFactor: CurvedAnimation(parent: controller, curve: Curves.bounceOut, reverseCurve: Curves.bounceIn),
    );
  }

  void _addUser(UserActivityData user) {
    if(users.contains(user)) {
      controllers[user].dispose();
    } else {
      users.add(user);
      sortUsers();
    }

    controllers[user] = AnimationController(
      vsync: this,
      duration: widget.animationDuration
    );

    controllers[user].forward();
  }

  void _removeUser(UserActivityData user) {
    controllers[user].reverse().then((value) {
      setState(() {
        users.remove(user);
        sortUsers();

        controllers[user].dispose();
        controllers.remove(user);
      });
    });
  }

  @override
  void dispose() {
    controllers.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }
}

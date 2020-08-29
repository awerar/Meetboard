import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:meetboard/Models/settings_model.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../themes.dart';

/*class PeopleTab extends StatelessWidget {
  final Activity activity;
  final UserActivityData user;

  PeopleTab(this.activity, this.user);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Consumer<SettingsModel>(
            builder: (BuildContext context, SettingsModel settings, Widget child) {
              List<UserActivityData> peopleComing =  activity.localUsers.values.where((element) => _willCome(element, settings)).toList();
              List<UserActivityData> peopleNotComing =  activity.localUsers.values.where((element) => !_willCome(element, settings)).toList();

              return Column(
                  children: [
                    _buildSubtitle("Coming – ${peopleComing.length}"),
                    UserColumn(peopleComing, user.uid, (u) => true),
                    SizedBox(height: 20,),
                    _buildSubtitle("Not Coming – ${peopleNotComing.length}"),
                    UserColumn(peopleNotComing, user.uid, (u) => false),
                  ],
              );
            }
          ),
        )
      ],
    );
  }

  bool _willCome(UserActivityData user, SettingsModel settings) {
    return (user.uid != this.user.uid && user.coming) || (user.uid == this.user.uid && settings.getSavedValue<bool>("coming"));
  }

  Widget _buildSubtitle(String text) {
    return Align(child: Builder(builder: (context) => Text(text, style: Theme.of(context).textTheme.subtitle2.copyWith(color: Colors.grey),)), alignment: Alignment.centerLeft,);
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
      children: users.map((user) => AnimatedBuilder(builder: (context, child) => _buildElement(user, context, controllers[user]), animation: controllers[user],)).toList()
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

        return ListTile(
          contentPadding: EdgeInsets.only(left: 0),
          title: !isUser ? Text(user.username) : Builder(builder: (context) => Text("You (${user.username})")),
          subtitle: user.role == ActivityRole.Owner ? Text("Owner") : null,
          leading: CircleAvatar(
            backgroundImage: NetworkImage('https://robohash.org/${user.uid}'),
            child: Align(
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.willCome(user) ? green : red,
                    border: Border.fromBorderSide(BorderSide(width: 1, color: Colors.white))
                ),
                padding: EdgeInsets.all(1),
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
}*/
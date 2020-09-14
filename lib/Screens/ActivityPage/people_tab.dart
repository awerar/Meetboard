import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/activity_snapshot.dart';
import 'package:meetboard/ActivitySystem/user_data_snapshot.dart';
import 'package:meetboard/ActivitySystem/user_reference.dart';
import 'package:meetboard/Models/settings_model.dart';
import 'package:meetboard/Models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../themes.dart';

class PeopleTab extends StatelessWidget {
  final ActivitySnapshot activity;

  PeopleTab(this.activity);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Builder(
            builder: (BuildContext context) {
              List<UserDataSnapshot> peopleComing =  activity.users.values.where((user) => user.coming).toList();
              List<UserDataSnapshot> peopleNotComing =  activity.users.values.where((user) => !user.coming).toList();

              return Column(
                  children: [
                    _buildSubtitle("Coming – ${peopleComing.length}"),
                    UserColumn(peopleComing),
                    SizedBox(height: 20,),
                    _buildSubtitle("Not Coming – ${peopleNotComing.length}"),
                    UserColumn(peopleNotComing),
                  ],
              );
            }
          ),
        )
      ],
    );
  }

  Widget _buildSubtitle(String text) {
    return Align(child: Builder(builder: (context) => Text(text, style: Theme.of(context).textTheme.subtitle2.copyWith(color: Colors.grey),)), alignment: Alignment.centerLeft,);
  }
}

class UserColumn extends StatefulWidget {
  final Map<UserReference, UserDataSnapshot> users;

  final Duration animationDuration = Duration(milliseconds: 900);

  UserColumn(List<UserDataSnapshot> users, {Key key}) :
        this.users = Map.unmodifiable(Map<UserReference, UserDataSnapshot>.fromIterable(users, key: (user) => user.ref)),
        super(key: key);

  @override
  _UserColumnState createState() => _UserColumnState();
}

class _UserColumnState extends State<UserColumn> with TickerProviderStateMixin {
  final HashMap<UserReference, AnimationController> _controllers = HashMap();
  final HashMap<UserReference, UserDataSnapshot> _currentUsers = HashMap();

  Iterable<UserDataSnapshot> get _sortedCurrentUsers => _currentUsers.values.toList()..sort(_compareUsers);

  static int _compareUsers(UserDataSnapshot a, UserDataSnapshot b) {
    if (a.ref == UserModel.instance.user) return -1;
    else if (b.ref == UserModel.instance.user) return 1;
    else return a.username.compareTo(b.username);
  }

  @override
  void initState() {
    _currentUsers.addEntries(widget.users.entries);
    _controllers.addEntries(widget.users.entries.map((kv) => MapEntry(kv.key, AnimationController(vsync: this, duration: widget.animationDuration, value: 1))));

    super.initState();
  }

  @override
  void didUpdateWidget(UserColumn oldWidget) {
    List<UserReference> newUIDs = widget.users.keys.where((element) => !oldWidget.users.keys.contains(element)).toList();
    List<UserReference> oldUIDs = oldWidget.users.keys.where((element) => !widget.users.keys.contains(element)).toList();

    oldUIDs.forEach((user) => _animateOut(user));
    newUIDs.forEach((user) => _animateIn(widget.users[user]));

    widget.users.values.forEach((user) {
      _currentUsers[user.ref] = user;
    });

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _sortedCurrentUsers.map((user) => AnimatedBuilder(builder: (context, child) => _buildElement(user, context, _controllers[user.ref]), animation: _controllers[user.ref],)).toList()
    );
  }

  Widget _buildElement(UserDataSnapshot user, BuildContext context, AnimationController controller) {
    assert(controller != null);

    return SizeTransition(
      axisAlignment: -1,
      child: Builder(builder: (context) {
        return ListTile(
          contentPadding: EdgeInsets.only(left: 0),
          title: user.ref != UserModel.instance.user ? Text(user.username) : Builder(builder: (context) => Text("You (${user.username})")),
          subtitle: user.role == ActivityRole.Owner ? Text("Owner") : null,
          leading: CircleAvatar(
            backgroundImage: NetworkImage('https://robohash.org/${user.ref.uid}'),
            child: Align(
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: user.coming ? green : red,
                    border: Border.fromBorderSide(BorderSide(width: 1, color: Colors.white))
                ),
                padding: EdgeInsets.all(1),
                child: Flex(
                  direction: Axis.horizontal,
                  children: <Widget>[
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: Icon(user.coming ? Icons.check : Icons.close, color: Colors.white,),
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

  void _animateIn(UserDataSnapshot user) {
    if(_controllers.containsKey(user.ref)) {
      _controllers[user.ref].dispose();
    }

    _controllers[user.ref] = AnimationController(
        vsync: this,
        duration: widget.animationDuration
    );
    _controllers[user.ref].forward();

    _currentUsers[user.ref] = user;
  }

  void _animateOut(UserReference user) {
    _controllers[user].reverse().then((value) {
      setState(() {
        _currentUsers.remove(user);

        _controllers[user].dispose();
        _controllers.remove(user);
      });
    });
  }

  @override
  void dispose() {
    _controllers.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }
}
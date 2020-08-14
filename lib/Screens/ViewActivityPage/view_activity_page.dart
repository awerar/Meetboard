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
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              children: <Widget>[
                if (_saving) Column(
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(height: 10,)
                  ],
                ),
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
                      SizedBox(width: 10,),
                      Tooltip(
                        child: Icon(Icons.help,),
                        message: "Make your friends enter\nthis code on their\ndevices for them to join",
                        showDuration: Duration(seconds: 5,),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      )
                    ],
                  );
                },),
                SizedBox(height: 8,),
                RaisedButton(
                  color: _coming ? green : red,
                  onPressed: () {
                    setState(() {
                      _coming = !_coming;
                    });
                    _save(activity);
                  }, child: Text(_coming ? "Coming" : "Not Coming", style: Theme.of(context).textTheme.subtitle2.copyWith(color: Colors.white),),
                ),
                SizedBox(height: 20,),
                Text("People", style: Theme.of(context).textTheme.headline5, textAlign: TextAlign.center,),
                Divider(),
                Wrap(
                  direction: Axis.horizontal,
                  alignment: WrapAlignment.spaceAround,
                  children: activity.users.values.map((e) => UserChip(e,
                          (u) => (u.coming && u.uid != _user.uid) || (_coming && u.uid == _user.uid),
                          (u) {
                            Map<String, IconData> tags = Map();

                            if (u.uid == _user.uid) tags["You"] = Icons.face;
                            if (u.role == ActivityRole.Owner) tags["Owner"] = Icons.vpn_key;

                            return tags;
                          }
                          )).toList(),
                )
              ],
            ),
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
}

class UserChip extends StatelessWidget {
  final UserActivityData user;
  final bool Function(UserActivityData) willCome;
  final Map<String, IconData> Function(UserActivityData) getExtraTags;

  UserChip(this.user, this.willCome, this.getExtraTags);

  @override
  Widget build(BuildContext context) {
    bool coming = willCome(user);

    Map<String, IconData> tags = getExtraTags(user);

    return Tooltip(
      showDuration: Duration(seconds: 3),
      message: ((tags.keys.toList()..insert(0, coming ? "Coming" : "Not Coming")).expand((element) => [element, " - "]).toList()..removeLast()).fold("", (previousValue, element) => previousValue + element),
      child: Chip(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            width: 2,
            color: coming ? green : red
          )
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(child: Text(user.username, overflow: TextOverflow.ellipsis, ), constraints: BoxConstraints(maxWidth: 100),),
            SizedBox(width: 5,),
          ]..addAll((tags.values.map((e) => Icon(e)).toList()..insert(0, Icon(coming ? Icons.check : Icons.close, color: coming ? green : red))).expand((element) => [element, SizedBox(width: 5,)]).toList()..removeLast()),
        ),
        avatar: Icon(Icons.person, color: Colors.black,),
      ),
    );
  }
}

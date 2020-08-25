import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserModel extends ChangeNotifier {
  FirebaseUser _user;
  DocumentReference _userDocument, _userActivitiesDocument;
  CollectionReference _userActivityCollection;
  String _username;

  String get username => _username;
  FirebaseUser get user => _user;
  DocumentReference get userDocument => _userDocument;
  CollectionReference get userActivityCollection => _userActivityCollection;

  GlobalKey<NavigatorState> _navigatorKey;

  static UserModel instance;

  UserModel(this._navigatorKey) {
    instance = this;

    _initializeUser();
  }

  void _initializeUser() async {
    _user = await FirebaseAuth.instance.currentUser();
    if (_user == null) {
      _user = (await FirebaseAuth.instance.signInAnonymously()).user;
    }

    _handleUserDocument();

    notifyListeners();
  }

  void _handleUserDocument() async {
    _userDocument = Firestore.instance.collection("users").document(_user.uid);
    _userActivitiesDocument = _userDocument.collection("private_data").document("user_activities");
    _userActivityCollection = _userActivitiesDocument.collection("user_activities");
    DocumentSnapshot documentSnapshot = await _userDocument.get();
    if (!documentSnapshot.exists) await _initializeUserDocument();
    else await _readFromUserDocument();
  }

  Future<void> _initializeUserDocument() async {
    await Future.wait([
      _userActivitiesDocument.setData({
        "activity_count": 0,
        "activities": []
      }),
      queryUsername().then((username) {
        return _userDocument.setData({
          "username": username
        });
      })
    ]);
  }

  Future<void> _readFromUserDocument() async {
    Map<String, dynamic> data = (await _userDocument.get()).data;
    _username = data["username"];
  }

  Future<String> queryUsername() async {
    String username;

    await showDialog(
      context: _navigatorKey.currentState.overlay.context,
      builder: (context) => NameAlert((val) => username = val),
      barrierDismissible: false
    );

    return username;
  }
}

class NameAlert extends StatefulWidget {
  final void Function(String) onUsernameDecided;

  NameAlert(this.onUsernameDecided);

  @override
  _NameAlertState createState() => _NameAlertState();
}

class _NameAlertState extends State<NameAlert> {
  String _username = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Welcome to Meetboard!"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text("Please enter a username"),
          TextField(
            onChanged: (v) => setState(() => _username = v),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
                labelText: "Username"
            ),
          ),
          SizedBox(height: 10,),
          RaisedButton(
            onPressed: _username.length < 2 ? null : () {
              widget.onUsernameDecided(_username);
              Navigator.pop(context);
            },
            color: Theme.of(context).colorScheme.secondary,
            child: Builder(builder: (context) => Text("Submit", style: DefaultTextStyle.of(context).style.copyWith(color: Theme.of(context).colorScheme.onSecondary),),),
          )
        ],
      ),
      contentPadding: EdgeInsets.fromLTRB(25, 0, 25, 5),
    );
  }
}

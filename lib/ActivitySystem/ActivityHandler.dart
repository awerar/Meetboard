import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/ActivityReference.dart';
import 'package:meetboard/ActivitySystem/ActivitySnapshot.dart';
import 'package:meetboard/ActivitySystem/UserDataSnapshot.dart';
import 'package:meetboard/Models/user_model.dart';

import 'ActivityValue.dart';

//Starts not connected, and can connect and disconnect
class ActivityHandler with ChangeNotifier {
  final ActivityReference ref;

  StreamSubscription _documentListener;
  bool get listeningToUpdates => _documentListener != null;

  ActivitySnapshot _latestSnapshot;
  ActivitySnapshot get latestSnapshot => _latestSnapshot;

  final ActivityValue<String> name;
  final ActivityValue<DateTime> time;
  final ActivityUsersValue users;
  final ActivityValue<bool> coming;
  List<IActivityValue> get _values => [name, time, users, coming];

  ActivityHandler._fromLocalValues(this.ref, String name, DateTime time, Iterable<UserDataSnapshot> users) :
    name = ActivityValue.local(name),
    time = ActivityValue.local(time),
    users = ActivityUsersValue.local(users.toList()),
    coming = ActivityValue.local(_parseComing(users)) {
    _linkValues();
  }

  ActivityHandler._fromGlobalValues(this.ref, String name, DateTime time, Iterable<UserDataSnapshot> users) :
        name = ActivityValue.global(name),
        time = ActivityValue.global(time),
        users = ActivityUsersValue.global(users.toList()),
        coming = ActivityValue.global(_parseComing(users)) {
    _linkValues();
  }

  ActivityHandler.fromDocumentSnapshot(ActivityReference ref, DocumentSnapshot doc) : this._fromGlobalValues(
    ref,
    doc.data["name"],
    _parseTimestamp(doc.data[""] as Timestamp),
    _parseUsers(doc.data["users"]),
  );

  static Future<ActivityHandler> create(String name, DateTime time) async {
    HttpsCallableResult result = await CloudFunctions.instance.getHttpsCallable(functionName: "createActivity").call({
      "name": name,
      "time": Timestamp.fromDate(time)
    });
    ActivityReference ref = ActivityReference(result.data as String);

    UserDataSnapshot creator = UserDataSnapshot.getDefaultCreateUser();
    return ActivityHandler._fromLocalValues(ref, name, time, [creator]);
  }

  static Future<ActivityHandler> join(ActivityReference ref) async {
    await CloudFunctions.instance.getHttpsCallable(functionName: "joinActivity").call({
      "id": ref.id
    });
    return ActivityHandler.fromDocumentSnapshot(ref, await ref.activityDocument.get());
  }

  void _linkValues() {
    _values.forEach((element) {
      element.link(this);
      element.addListener(_onActivityChanged);
    });
  }

  void _onActivityChanged() {
    _latestSnapshot = ActivitySnapshot(
      ref: ref,
      name: name.currentValue,
      time: time.currentValue,
      users: users.currentValue.toList()
    );

    notifyListeners();
  }

  void startListen() {
    assert(!listeningToUpdates);

    _documentListener = ref.activityDocument.snapshots().listen((doc) {
      Iterable<UserDataSnapshot> globalUsers = _parseUsers(doc.data["users"]);
      users.setGlobalUsers(globalUsers);

      name.setGlobalValue(doc.data["name"]);
      time.setGlobalValue(_parseTimestamp(doc.data["time"]));
      coming.setGlobalValue(_parseComing(globalUsers));
    });
  }

  void stopListen() {
    assert(listeningToUpdates);

    _documentListener.cancel();
    _documentListener = null;
  }

  static DateTime _parseTimestamp(Timestamp timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
  }

  static bool _parseComing(Iterable<UserDataSnapshot> users) {
    return users.firstWhere((element) => element.uid == UserModel.instance.user.uid).coming;
  }

  static List<UserDataSnapshot> _parseUsers(Map<String, Map<String, dynamic>> userData) {
    return userData.entries.map((e) => UserDataSnapshot.fromData(e.key, e.value));
  }
}
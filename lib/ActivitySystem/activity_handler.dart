import 'dart:async';
import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/ActivitySnapshot.dart';
import 'package:meetboard/ActivitySystem/user_data_snapshot.dart';
import 'package:meetboard/Models/user_model.dart';

import 'activity_value.dart';

//Starts not connected, and can connect and disconnect
class ActivityHandler with ChangeNotifier {
  final ActivityReference ref;

  StreamSubscription _documentListener;
  bool get listeningToUpdates => _documentListener != null;

  ActivitySnapshot _latestSnapshot;
  ActivitySnapshot get latestSnapshot => _latestSnapshot;

  final ActivityValue<String> _name;
  final ActivityValue<DateTime> _time;
  final ActivityUsersValue _users;
  final ActivityValue<bool> _coming;
  Map<String, IActivityValue> get _valuesMap => {
    "name": _name,
    "time": _time,
    "users": _users,
    "coming": _coming
  };
  List<IActivityValue> get _values => _valuesMap.values.toList();

  ActivityHandler._fromLocalValues(this.ref, String name, DateTime time, Iterable<UserDataSnapshot> users) :
    _name = ActivityValue.local(name),
    _time = ActivityValue.local(time),
    _users = ActivityUsersValue.local(users.toList()),
    _coming = ActivityValue.local(_parseComing(users)) {
    _linkValues();
  }

  ActivityHandler._fromGlobalValues(this.ref, String name, DateTime time, Iterable<UserDataSnapshot> users) :
        _name = ActivityValue.global(name),
        _time = ActivityValue.global(time),
        _users = ActivityUsersValue.global(users.toList()),
        _coming = ActivityValue.global(_parseComing(users)) {
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
      name: _name.currentValue,
      time: _time.currentValue,
      users: _users.currentValue.toList()
    );

    notifyListeners();
  }

  Future<void> write(_ActivityWriterWriteFunc writeFunc) {
    ActivityWriter writer = ActivityWriter(this, writeFunc);
    return writer.write();
  }

  void startListen() {
    assert(!listeningToUpdates);

    _documentListener = ref.activityDocument.snapshots().listen((doc) {
      Iterable<UserDataSnapshot> globalUsers = _parseUsers(doc.data["users"]);
      _users.setGlobalUsers(globalUsers);

      _name.setGlobalValue(doc.data["name"]);
      _time.setGlobalValue(_parseTimestamp(doc.data["time"]));
      _coming.setGlobalValue(_parseComing(globalUsers));
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

typedef _ActivityWriterWriteFunc = void Function(ActivityValueWriter<String> name, ActivityValueWriter<DateTime> time, ActivityValueWriter<bool> coming, ActivityUsersValueWriter users);

class ActivityWriter {
  final ActivityHandler _handler;
  ActivityReference get ref => _handler.ref;

  final _ActivityWriterWriteFunc _write;

  ActivityWriter(this._handler, this._write);

  Future<void> write() {
    ActivityValueWriter<String> name = ActivityValueWriter(ref, _handler._name, (val, ref) => FirestoreChange.single(ref.activityDocument, {"name": val}));
    ActivityValueWriter<DateTime> time = ActivityValueWriter(ref, _handler._time, (val, ref) => FirestoreChange.single(ref.activityDocument, {"time": Timestamp.fromDate(val)}));
    ActivityValueWriter<bool> coming = ActivityValueWriter(ref, _handler._coming, (val, ref) => FirestoreChange.single(ref.activityDocument.collection("users").document(UserModel.instance.user.uid), {"coming": val}));
    ActivityUsersValueWriter users = ActivityUsersValueWriter(ref, _handler._users);
    List<IActivityValueWriter> writers = [name, time, coming, users];

    _write(name, time, coming, users);

    return writers.fold<FirestoreChange>(FirestoreChange.none(), (acc, change) => acc.merge(change.getChanges())).apply();
  }
}

class FirestoreChange {
  final Map<DocumentReference, Map<String, dynamic>> changes;

  FirestoreChange.none() : changes = {};
  FirestoreChange.single(DocumentReference doc, Map<String, dynamic> data) : changes = { doc: data };
  FirestoreChange.multiple(this.changes);

  FirestoreChange._merge(FirestoreChange a, FirestoreChange b) :
        changes = (a.changes)
          //Adds all entries from B where A doesn't contain that key
          ..addEntries(b.changes.entries.where((element) => a.changes.containsKey(element.key)))
          //Merges all data from B with the data from A when they share a key
          ..entries.where((element) => b.changes.containsKey(element.key)).forEach((element) => element.value.addEntries(b.changes[element.key].entries));

  FirestoreChange merge(FirestoreChange other) {
    return FirestoreChange._merge(this, other);
  }

  Future<void> apply() async {
    var batch = Firestore.instance.batch();
    for(var entry in changes.entries) {
      batch.setData(entry.key, entry.value, merge: true);
    }
    return batch.commit();
  }
}
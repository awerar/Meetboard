import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/activity_snapshot.dart';
import 'package:meetboard/ActivitySystem/user_data_snapshot.dart';
import 'package:meetboard/Models/user_model.dart';

import 'activity_value.dart';

//Starts not connected, and can connect and disconnect
class ActivityHandler with ChangeNotifier {
  final ActivityReference ref;

  StreamSubscription _activityListener;
  bool get listeningToUpdates => _activityListener != null;

  ActivitySnapshot _latestSnapshot;
  ActivitySnapshot get latestSnapshot => _latestSnapshot;

  final ActivityValue<String> _name;
  final ActivityValue<DateTime> _time;
  final UserListActivityValue _users;
  Map<String, IActivityValue> get _valuesMap => {
    "name": _name,
    "time": _time,
    "users": _users,
  };
  List<IActivityValue> get _values => _valuesMap.values.toList();

  ActivityHandler._fromLocalValues(this.ref, String name, DateTime time, Iterable<UserDataSnapshot> users) :
    _name = ActivityValue.local(name),
    _time = ActivityValue.local(time),
    _users = UserListActivityValue.local(users.toList()) {
    _linkValues();
  }

  ActivityHandler._fromGlobalValues(this.ref, String name, DateTime time, Iterable<UserDataSnapshot> users) :
        _name = ActivityValue.global(name),
        _time = ActivityValue.global(time),
        _users = UserListActivityValue.global(users.toList()) {
    _linkValues();
  }
  
  ActivityHandler._fromValues(this.ref, this._name, this._time, this._users);

  ActivityHandler._fromDocumentSnapshot(ActivityReference ref, DocumentSnapshot doc) : this._fromGlobalValues(
      ref,
      doc.data["name"],
      (doc.data["time"] as Timestamp).toDate(),
      _parseUsers(doc.data["users"])
  );

  static Future<ActivityHandler> fromExisting(ActivityReference ref) async {
    return ActivityHandler._fromDocumentSnapshot(ref, await ref.activityDocument.get());
  }

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

    DocumentSnapshot doc = await ref.activityDocument.get();
    return ActivityHandler._fromValues(
        ref,
        ActivityValue.global(doc.data["name"]),
        ActivityValue.global((doc.data["time"] as Timestamp).toDate()), 
        UserListActivityValue.global(_parseUsers(doc.data["users"]))..addUserLocally(UserDataSnapshot.getDefaultJoinUser())
    );
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

  Future<void> write(ActivityWriteFunc writeFunc) {
    return ActivityWriter._write(writeFunc, this);
  }

  void startListen() {
    assert(!listeningToUpdates);

    _activityListener = ref.activityDocument.snapshots().listen((doc) {
      Iterable<UserDataSnapshot> globalUsers = _parseUsers(doc.data["users"]);
      _users.setGlobalUsers(globalUsers);

      _name.setGlobalValue(doc.data["name"]);
      _time.setGlobalValue((doc.data["time"] as Timestamp).toDate());
    });
  }

  void stopListen() {
    assert(listeningToUpdates);

    _activityListener.cancel();
    _activityListener = null;
  }

  static List<UserDataSnapshot> _parseUsers(dynamic userData) {
    return Map<String, dynamic>.from(userData)
        .map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)))
        .entries.map((e) => UserDataSnapshot.fromData(e.key, e.value)).toList();
  }
}

typedef ActivityWriteFunc = void Function(ActivityWriter writer);

class ActivityWriter {
  final ActivityHandler _handler;
  ActivityReference get ref => _handler.ref;

  final ActivityValueWriter<String> name;
  final ActivityValueWriter<DateTime> time;
  final UserListActivityValueWriter users;
  List<IActivityValueWriter> get _writers => [name, time, users];

  ActivityWriter._(this._handler) :
    name = ActivityValueWriter(_handler._name, (val) => FirestoreChange.single(_handler.ref.activityDocument, {"name": val})),
    time = ActivityValueWriter(_handler._time, (val) => FirestoreChange.single(_handler.ref.activityDocument, {"time": Timestamp.fromDate(val)})),
    users = UserListActivityValueWriter(_handler._users);

  static Future<void> _write(ActivityWriteFunc writeFunc, ActivityHandler handler) {
    ActivityWriter writer = ActivityWriter._(handler);
    writeFunc(writer);

    return writer._writers.fold<FirestoreChange>(FirestoreChange.none(), (acc, change) => acc.merge(change.getChanges())).apply();
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
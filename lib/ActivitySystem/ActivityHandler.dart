import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/ActivityReference.dart';
import 'package:meetboard/ActivitySystem/ActivitySnapshot.dart';
import 'package:meetboard/ActivitySystem/UserDataSnapshot.dart';

//Starts not connected, and can connect and disconnect
class ActivityHandler with ChangeNotifier {
  final ActivityReference ref;

  bool _listeningToUpdates = false;

  ActivitySnapshot _latestSnapshot;
  ActivitySnapshot get latestSnapshot => _latestSnapshot;

  String globalName;
  DateTime globalTime;
  HashSet<UserDataSnapshot> globalUsers;

  LocalValue<String> localName;
  LocalValue<DateTime> localTime;
  LocalValue<HashSet<UserDataSnapshot>> localUsers;

  ActivityHandler._fromLocalValues(this.ref, String name, DateTime time, Iterable<UserDataSnapshot> users) {
    this.localName = LocalValue(this, name);
    this.localTime = LocalValue(this, time);
    this.localUsers = LocalValue(this, HashSet.from(users));
  }

  ActivityHandler.fromDocumentSnapshot(ActivityReference ref, DocumentSnapshot doc) : this._fromLocalValues(
    ref,
    doc.data["name"],
    DateTime.fromMillisecondsSinceEpoch((doc.data[""] as Timestamp).millisecondsSinceEpoch),
    (doc.data["users"] as Map<String, Map<String, dynamic>>).entries.map((e) => UserDataSnapshot.fromData(e.key, e.value))
  );

  static Future<ActivityHandler> create(String name, DateTime time) async {
    HttpsCallableResult result = await CloudFunctions.instance.getHttpsCallable(functionName: "createActivity").call({
      "name": name,
      "time": Timestamp.fromDate(time)
    });
    ActivityReference ref = ActivityReference(result.data as String);
    return ActivityHandler._fromLocalValues(ref, name, time, [UserDataSnapshot.getDefaultCreateUser()]);
  }

  static Future<ActivityHandler> join(ActivityReference ref) async {
    await CloudFunctions.instance.getHttpsCallable(functionName: "joinActivity").call({
      "id": ref.id
    });
    return ActivityHandler.fromDocumentSnapshot(ref, await ref.activityDocument.get());
  }

  void onActivityChanged() {
    _latestSnapshot = _getLatestSnapshot();
    notifyListeners();
  }

  ActivitySnapshot _getLatestSnapshot() {
    if (_listeningToUpdates) {
      assert(localName != null);
      assert(localTime != null);
      assert(localUsers != null);

      return ActivitySnapshot(
        ref: ref,
        name: localName.value,
        time: localTime.value,
        users: localUsers.value.toList()
      );
    } else {
      assert(globalName != null);
      assert(globalTime != null);
      assert(globalUsers != null);

      return ActivitySnapshot(
        ref: ref,
        name: localName != null ? localName.value : globalName,
        time: localTime != null ? localTime.value : globalTime,
        users: (localUsers != null ? localUsers.value : globalUsers).toList()
      );
    }
  }

  void _startListen() {
    assert(!_listeningToUpdates);
    _listeningToUpdates = true;
  }

  void _stopListen() {
    assert(_listeningToUpdates);
    _listeningToUpdates = false;
  }
}

class LocalValue<T> {
  final ActivityHandler _listener;
  T _value;

  T get value => _value;

  LocalValue(this._listener, this._value);

  void updateValue(T Function(T currentValue) modifier) {
    T newValue = modifier(_value);
    if (newValue != null) _value = newValue;
  }
}
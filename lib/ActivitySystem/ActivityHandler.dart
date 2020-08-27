import 'dart:async';
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

  StreamSubscription _documentListener;
  bool get listeningToUpdates => _documentListener != null;

  ActivitySnapshot _latestSnapshot;
  ActivitySnapshot get latestSnapshot => _latestSnapshot;

  final ActivityValue<String> name;
  final ActivityValue<DateTime> time;
  final ActivityValue<HashSet<UserDataSnapshot>> users;

  ActivityHandler._fromLocalValues(this.ref, String name, DateTime time, Iterable<UserDataSnapshot> users) :
    name = ActivityValue.local(this, name),
    time = ActivityValue.local(this, time),
    users = ActivityValue.local(this, HashSet.from(users));

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
    _latestSnapshot = ActivitySnapshot(
      ref: ref,
      name: name.currentValue,
      time: time.currentValue,
      users: users.currentValue.toList()
    );

    notifyListeners();
  }

  void _startListen() {
    assert(!listeningToUpdates);

    _documentListener = ref.activityDocument.snapshots().listen((doc) {

    });
  }

  void _stopListen() {
    assert(listeningToUpdates);

    _documentListener.cancel();
    _documentListener = null;
  }
}

class ActivityValue<T> {
  final ActivityHandler _handler;

  T get currentValue => _hasLocalValue ? _localValue : _globalValue;
  bool get _hasLocalValue {
    if(_handler.listeningToUpdates) {
      assert(_globalValue != null);
      return _localValue != null;
    } else {
      assert(_localValue != null);
      return true;
    }
  }

  T _globalValue;
  T _localValue;

  ActivityValue.local(ActivityHandler handler, T value) :
        _handler = handler,
        _localValue = value;

  ActivityValue.global(ActivityHandler handler, T value) :
        _handler = handler,
        _globalValue = value,
        _localValue = value;

  void setGlobalValue(T value) {
    _globalValue = value;

    _handler.onActivityChanged();
  }

  void setLocalValue(T value) {
    _localValue = value;

    _handler.onActivityChanged();
  }

  void updateLocalValue(T Function (T val) modifier) {
    T res = modifier(_localValue);
    if (res != null) _localValue = res;

    _handler.onActivityChanged();
  }
}
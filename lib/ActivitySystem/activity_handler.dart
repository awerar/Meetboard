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
  final ActivityData _activityData;

  StreamSubscription _activityListener;
  bool get listeningToUpdates => _activityListener != null;

  ActivitySnapshot get currentSnapshot => _activityData.currentValue;

  ActivityHandler._(this.ref, this._activityData) {
    _activityData.linkParent(this);
  }

  ActivityHandler._fromActivityData(ActivityData activityData) : this._(activityData.currentValue.ref, activityData);

  static Future<ActivityHandler> fromExisting(ActivityReference ref) async {
    return ActivityHandler._fromActivityData(ActivityData.global(ActivitySnapshot.fromData(ref, (await ref.activityDocument.get()).data)));
  }

  static Future<ActivityHandler> create(String name, DateTime time) async {
    HttpsCallableResult result = await CloudFunctions.instance.getHttpsCallable(functionName: "createActivity").call({
      "name": name,
      "time": Timestamp.fromDate(time)
    });
    ActivityReference ref = ActivityReference(result.data as String);

    UserDataSnapshot creator = UserDataSnapshot.getDefaultCreateUser();
    return ActivityHandler._fromActivityData(ActivityData.local(ActivitySnapshot(ref: ref, name: name, time: time, users: [creator])));
  }

  static Future<ActivityHandler> join(ActivityReference ref) async {
    await CloudFunctions.instance.getHttpsCallable(functionName: "joinActivity").call({
      "id": ref.id
    });

    return await ActivityHandler.fromExisting(ref);
  }

  Future<void> write(void Function(ActivityDataWriter writer) writeFunc) {
    ActivityDataWriter writer = ActivityDataWriter(_activityData);
    writeFunc(writer);
    return writer.getChanges().apply();
  }

  void startListen() {
    assert(!listeningToUpdates);

    _activityListener = ref.activityDocument.snapshots().listen((doc) {
      _activityData.setGlobalValue(ActivitySnapshot.fromData(ref, doc.data));
    });
  }

  void stopListen() {
    assert(listeningToUpdates);

    _activityListener.cancel();
    _activityListener = null;
  }
}

typedef ActivityWriteFunc = void Function(ActivityDataWriter writer);

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
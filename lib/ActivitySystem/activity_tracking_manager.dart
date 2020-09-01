import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:meetboard/ActivitySystem/activity_handler.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/activity_snapshot.dart';
import 'package:meetboard/Models/user_model.dart';

typedef OnActivityChangeFunction = void Function(ActivitySnapshot snapshot);
typedef OnPreviewsChangeFunction = void Function(ActivitySnapshot snapshot);

class ActivityTrackingManager {
  static ActivityTrackingManager instance;
  static Completer<void> _completer = Completer();
  static Future<void> get initialized => _completer.future;

  Map<ActivityReference, StreamController<ActivitySnapshot>> _snapshotControllers = Map();
  Map<ActivityReference, ActivityHandler> _activityHandlers = Map();

  HashSet<ActivityReference> _trackedActivities = HashSet();
  HashSet<ActivityReference> _prevGlobalActivities = HashSet();

  static void initialize() {
    if (instance == null) {
      ActivityTrackingManager._();
      _completer.complete();
    }
  }

  ActivityTrackingManager._() {
    assert(instance == null);
    instance = this;

    ///TODO: Update when user changes
    UserModel.instance.userActivitiesDocument.snapshots().listen((document) {
      HashSet<ActivityReference> newGlobalActivities = (document.data["activities"] as List<String>).map((e) => ActivityReference(e));
      
      Iterable<ActivityReference> addedGlobalActivities = newGlobalActivities.where((element) => !_prevGlobalActivities.contains(element));
      Iterable<ActivityReference> removedGlobalActivities = _prevGlobalActivities.where((element) => !newGlobalActivities.contains(element));

      addedGlobalActivities.forEach((ref) {
        Future.microtask(() async {
          if (!_trackedActivities.contains(ref)) _startTrackActivity(ref, await ActivityHandler.fromExisting(ref));
        });
      });

      removedGlobalActivities.forEach((ref) {
        _stopTrackActivity(ref);
      });
    });
  }

  Stream<ActivitySnapshot> getActivityChangeStream(ActivityReference ref) {
    assert(_trackedActivities.contains(ref));

    return _snapshotControllers[ref].stream;
  }

  Future<void> write(ActivityReference ref, ActivityWriteFunc writeFunc) {
    assert(_trackedActivities.contains(ref));

    return _activityHandlers[ref].write(writeFunc);
  }

  Future<ActivityReference> createActivity(String name, DateTime time) async {
    ActivityHandler handler = await ActivityHandler.create(name, time);
    _startTrackActivity(handler.ref, handler);
    return handler.ref;
  }

  Future<Stream<ActivitySnapshot>> joinActivity(ActivityReference ref) async {
    _startTrackActivity(ref, await ActivityHandler.join(ref));
    return getActivityChangeStream(ref);
  }

  void _startTrackActivity(ActivityReference ref, ActivityHandler handler) {
    assert(!_trackedActivities.contains(ref));
    _trackedActivities.add(ref);

    _activityHandlers[ref] = handler;

    bool sendEvents = false;

    // ignore: close_sinks
    StreamController<ActivitySnapshot> controller = StreamController.broadcast(
      onListen: () {
        assert(sendEvents == false);
        sendEvents = true;
        _activityHandlers[ref].startListen();
      },
      onCancel: () {
        assert(sendEvents == true);
        sendEvents = false;
        _activityHandlers[ref].stopListen();
      },
    );

    _snapshotControllers[ref] = controller;
    handler.addListener(() {
      if (sendEvents) _snapshotControllers[ref].add(handler.latestSnapshot);
    });
  }

  void _stopTrackActivity(ActivityReference ref) {
    assert(_trackedActivities.contains(ref));
    _trackedActivities.remove(ref);

    (_activityHandlers..[ref].dispose()).remove(ref);
    (_snapshotControllers..[ref].close()).remove(ref);
  }
}
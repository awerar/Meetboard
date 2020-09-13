import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:meetboard/ActivitySystem/activity_handler.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/activity_snapshot.dart';
import 'package:meetboard/ActivitySystem/user_data_snapshot.dart';
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

  // ignore: close_sinks
  StreamController<List<ActivitySnapshot>> _allActivitiesStreamController;
  Stream<List<ActivitySnapshot>> get allActivitiesStream => _allActivitiesStreamController.stream;
  Map<ActivityReference, StreamSubscription> _allActivitiesSnapshotListeners = Map();
  bool get _listeningAll => _allActivitiesStreamController.hasListener;

  StreamSubscription _firestoreActivityListener;

  static void initialize() {
    if (instance == null) {
      ActivityTrackingManager._();
      _completer.complete();
    }
  }

  ActivityTrackingManager._() {
    assert(instance == null);
    instance = this;

    _allActivitiesStreamController = StreamController.broadcast(
      onListen: _startListenAll,
      onCancel: _stopListenAll
    );
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

  void _stopListenAll() {
    assert(_firestoreActivityListener != null && !_listeningAll);

    _trackedActivities.forEach((ref) => _stopListen(ref));

    _firestoreActivityListener.cancel();
    _firestoreActivityListener = null;
  }

  void _startListenAll() {
    assert(_firestoreActivityListener == null && _listeningAll);

    _trackedActivities.forEach((ref) => _startListen(ref));

    ///TODO: Update when user changes
    _firestoreActivityListener = UserModel.instance.user.userActivitiesDocument.snapshots().listen((document) {
      HashSet<ActivityReference> newGlobalActivities = HashSet.from((document.data["activities"] as List<dynamic>).cast<String>().map((e) => ActivityReference(e)));

      Iterable<ActivityReference> addedGlobalActivities = newGlobalActivities.where((element) => !_prevGlobalActivities.contains(element));
      Iterable<ActivityReference> removedGlobalActivities = _prevGlobalActivities.where((element) => !newGlobalActivities.contains(element));

      addedGlobalActivities.forEach((ref) {
        Future.microtask(() async {
          if (!_trackedActivities.contains(ref)){
            _startTrackActivity(ref, await ActivityHandler.fromExisting(ref, UserDataSnapshot.defaultUser));
          }
        });
      });

      removedGlobalActivities.forEach((ref) {
        _stopTrackActivity(ref);
      });
    });
  }

  void _startListen(ActivityReference ref) {
    assert(_listeningAll);

    _allActivitiesSnapshotListeners[ref] = _snapshotControllers[ref].stream.listen((snapshot) {
      _allActivitiesStreamController.add(_activityHandlers.entries.map((kv) => kv.value.currentSnapshot).toList());
    });
  }

  void _stopListen(ActivityReference ref) {
    assert(!_listeningAll);

    (_allActivitiesSnapshotListeners..[ref].cancel()).remove(ref);
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
      if (sendEvents) _snapshotControllers[ref].add(handler.currentSnapshot);
    });

    if (_listeningAll) _startListen(ref);
  }

  void _stopTrackActivity(ActivityReference ref) {
    assert(_trackedActivities.contains(ref));
    _trackedActivities.remove(ref);

    if (_listeningAll) _stopListen(ref);
    (_activityHandlers..[ref].dispose()).remove(ref);
    (_snapshotControllers..[ref].close()).remove(ref);
  }
}
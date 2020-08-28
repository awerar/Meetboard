import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:meetboard/ActivitySystem/activity_handler.dart';
import 'package:meetboard/ActivitySystem/activity_preview_snapshot.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/ActivitySnapshot.dart';
import 'package:meetboard/Models/user_model.dart';

typedef OnActivityChangeFunction = void Function(ActivitySnapshot snapshot);

class ActivityListModel {
  static ActivityListModel instance;

  Map<ActivityReference, ActivityPreviewSnapshot> _previews = Map();
  List<ActivityPreviewSnapshot> get previews => List<ActivityPreviewSnapshot>.unmodifiable(_previews.values);

  Map<ActivityReference, List<ActivitySubscription>> _activitySubscriptions = Map();
  Map<ActivityReference, ActivityHandler> _activityHandlers = Map();

  HashSet<ActivityReference> _trackedActivities = HashSet();

  ActivityListModel() {
    assert(instance == null);
    instance = this;

    UserModel.instance.userActivityCollection.snapshots().listen((querySnapshot) {
      querySnapshot.documentChanges.forEach((change) {
        ActivityReference ref = ActivityReference(change.document.documentID);

        if (change.document.exists) {
          //Added preview
          if (!_trackedActivities.contains(ref)) {
            _startTrackActivity(ref, ActivityHandler.fromDocumentSnapshot(ref, change.document));
          }
        } else {
          //Removed preview
          _stopTrackActivity(ref);
        }
      });
    });
  }

  ActivitySubscription listenForActivityChange(ActivityReference ref, OnActivityChangeFunction onChange, {bool startWithLatestSnapshot = true}) {
    assert(_trackedActivities.contains(ref));

    onChange(_activityHandlers[ref].latestSnapshot);
    ActivitySubscription subscription = ActivitySubscription((instance) => _activitySubscriptions[ref].remove(instance));
    _activitySubscriptions[ref].add(subscription);
    return subscription;
  }

  Stream<ActivitySnapshot> getActivitySnapshotStream(ActivityReference ref) {
    ActivitySubscription subscription;
    StreamController<ActivitySnapshot> controller;

    OnActivityChangeFunction onChange = (snapshot) {
      controller.add(snapshot);
    };

    controller = StreamController<ActivitySnapshot>(
      onPause: () {
        assert(subscription != null);

        subscription.unsubscribe();
        subscription = null;
      },
      onResume: () {
        assert(subscription == null);

        subscription = listenForActivityChange(ref, onChange);
      }
    );

    subscription = listenForActivityChange(ref, onChange);

    return controller.stream;
  }

  void _startTrackActivity(ActivityReference ref, ActivityHandler handler) {
    assert(!_trackedActivities.contains(ref));
    _trackedActivities.add(ref);

    _activityHandlers[ref] = handler;
    _activitySubscriptions[ref] = [];
    _previews[ref] = handler.latestSnapshot.getPreview();
    listenForActivityChange(ref, (snapshot) {
      _previews[ref] = snapshot.getPreview();
    });
  }

  void _stopTrackActivity(ActivityReference ref) {
    assert(_trackedActivities.contains(ref));
    _trackedActivities.remove(ref);

    _activityHandlers[ref].dispose();
    _activityHandlers.remove(ref);
    _activitySubscriptions[ref].toList().forEach((subscription) => subscription.unsubscribe());
    _previews.remove(ref);
  }
}

class ActivitySubscription {
  OnActivityChangeFunction onChange;

  bool _subscribed = true;
  final void Function(ActivitySubscription instance) _unsubscribe;

  ActivitySubscription(this._unsubscribe);

  void unsubscribe() {
    if (_subscribed) {
      _subscribed = false;
      _unsubscribe(this);
    }
  }
}
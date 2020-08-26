import 'dart:collection';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/ActivityListener.dart';
import 'package:meetboard/ActivitySystem/ActivityPreviewSnapshot.dart';
import 'package:meetboard/ActivitySystem/ActivityReference.dart';
import 'package:meetboard/ActivitySystem/ActivitySnapshot.dart';
import 'package:meetboard/Models/user_model.dart';

typedef OnActivityChangeFunction = void Function(ActivitySnapshot snapshot);

class ActivityListModel with ChangeNotifier {
  static ActivityListModel instance;

  Map<ActivityReference, ActivityPreviewSnapshot> _previews = Map();
  List<ActivityPreviewSnapshot> get previews => List<ActivityPreviewSnapshot>.unmodifiable(_previews.values);

  Map<ActivityReference, List<OnActivityChangeFunction>> _onChangeFunctions = Map();
  Map<ActivityReference, ActivityHandler> _activityListeners = Map();

  HashSet<ActivityReference> _globalActivities = HashSet(),
      _localAddedActivities = HashSet(),
      _localRemovedActivities = HashSet(),
      _trackedActivities = HashSet();
  HashSet<ActivityReference> get trackedActivities => HashSet.from(_trackedActivities);

  ActivityListModel() {
    UserModel.instance.userActivityCollection.snapshots().listen((querySnapshot) {
      querySnapshot.documentChanges.forEach((change) {
        ActivityReference ref = ActivityReference(change.document.documentID);

        if (change.document.exists) {
          //Added preview
          _globalActivities.add(ref);
          if(_localAddedActivities.contains(ref)) _localAddedActivities.remove(ref);
        } else {
          //Removed preview
          _globalActivities.remove(ActivityReference(change.document.documentID));
          if(_localRemovedActivities.contains(ref)) _localRemovedActivities.remove(ref);
        }
      });

      onTrackedActivitiesChanged();
    });
  }

  ActivitySubscription listenForActivityChange(ActivityReference ref, OnActivityChangeFunction onChange) {
    assert(trackedActivities.contains(ref));

    _onChangeFunctions[ref].add(onChange);
    return ActivitySubscription(() => _onChangeFunctions[ref].remove(onChange));
  }

  void onTrackedActivitiesChanged() {
    HashSet<ActivityReference> prevTrackedActivities = _trackedActivities;
    _trackedActivities = HashSet.from(_globalActivities)..removeAll(_localRemovedActivities)..addAll(_localAddedActivities);

    Iterable<ActivityReference> newActivities = _trackedActivities.where((ref) => !prevTrackedActivities.contains(ref));
    Iterable<ActivityReference> oldActivities = prevTrackedActivities.where((ref) => !trackedActivities.contains(ref));

    newActivities.forEach((ref) {

    });

    oldActivities.forEach((ref) {

    });

    notifyListeners();
  }
}

class ActivitySubscription {
  bool _hasStopped;

  final void Function() _stop;

  ActivitySubscription(this._stop);

  void stop() {
    if (!_hasStopped) {
      _hasStopped = true;
      _stop();
    }
  }
}
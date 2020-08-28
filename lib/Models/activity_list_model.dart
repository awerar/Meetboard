import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:meetboard/ActivitySystem/activity_handler.dart';
import 'package:meetboard/ActivitySystem/activity_preview_snapshot.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/ActivitySnapshot.dart';
import 'package:meetboard/Models/user_model.dart';

typedef OnActivityChangeFunction = void Function(ActivitySnapshot snapshot);
typedef OnPreviewsChangeFunction = void Function(ActivitySnapshot snapshot);

class ActivityListModel {
  static ActivityListModel instance;

  Map<ActivityReference, ActivityPreviewSnapshot> _previews = Map();
  List<ActivityPreviewSnapshot> get previews => List<ActivityPreviewSnapshot>.unmodifiable(_previews.values);

  StreamController<List<ActivityPreviewSnapshot>> _previewsController = StreamController.broadcast();
  Stream<List<ActivityPreviewSnapshot>> get previewsStream => _previewsController.stream;

  Map<ActivityReference, StreamController<ActivitySnapshot>> _snapshotControllers = Map();
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

  Stream<ActivitySnapshot> getActivityChangeStream(ActivityReference ref) {
    assert(_trackedActivities.contains(ref));

    return _snapshotControllers[ref].stream;
  }

  void _startTrackActivity(ActivityReference ref, ActivityHandler handler) {
    assert(!_trackedActivities.contains(ref));
    _trackedActivities.add(ref);

    _activityHandlers[ref] = handler;

    StreamController<ActivitySnapshot> controller = StreamController.broadcast();

    _snapshotControllers[ref] = controller;
    handler.addListener(() {
      _snapshotControllers[ref].add(handler.latestSnapshot);
    });

    _previews[ref] = handler.latestSnapshot.getPreview();
    _onPreviewsChange();

    controller.stream.listen((snapshot) {
      _previews[ref] = snapshot.getPreview();
      _onPreviewsChange();
    });
  }

  void _stopTrackActivity(ActivityReference ref) {
    assert(_trackedActivities.contains(ref));
    _trackedActivities.remove(ref);

    (_activityHandlers..[ref].dispose()).remove(ref);
    (_snapshotControllers..[ref].close()).remove(ref);
    _previews.remove(ref);
    _onPreviewsChange();
  }

  void _onPreviewsChange() {
    _previewsController.add(previews);
  }
}
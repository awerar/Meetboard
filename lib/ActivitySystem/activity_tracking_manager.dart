import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meetboard/ActivitySystem/activity_handler.dart';
import 'package:meetboard/ActivitySystem/activity_preview_snapshot.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/activity_snapshot.dart';
import 'package:meetboard/Models/user_model.dart';

typedef OnActivityChangeFunction = void Function(ActivitySnapshot snapshot);
typedef OnPreviewsChangeFunction = void Function(ActivitySnapshot snapshot);

class ActivityTrackingManager {
  static ActivityTrackingManager instance;

  Map<ActivityReference, ActivityPreviewSnapshot> _globalPreviews = Map();
  Map<ActivityReference, ActivityPreviewSnapshot> _previews = Map();
  List<ActivityPreviewSnapshot> get previews => List<ActivityPreviewSnapshot>.unmodifiable(_previews.values);

  StreamController<List<ActivityPreviewSnapshot>> _previewsController = StreamController.broadcast();
  Stream<List<ActivityPreviewSnapshot>> get previewsStream => _previewsController.stream;

  Map<ActivityReference, int> _onlineStreamListenerCount = Map();
  Map<ActivityReference, StreamController<ActivitySnapshot>> _snapshotControllers = Map();
  Map<ActivityReference, ActivityHandler> _activityHandlers = Map();

  HashSet<ActivityReference> _trackedActivities = HashSet();

  static void initialize() {
    if (instance == null) ActivityTrackingManager._();
  }

  ActivityTrackingManager._() {
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

          _globalPreviews[ref] = ActivityPreviewSnapshot(
              ref: ref,
              coming: change.document.data["coming"],
              time: (change.document.data["time"] as Timestamp).toDate(),
              name: change.document.data["name"]
          );
          _updatePreview(ref);
        } else {
          //Removed preview
          _stopTrackActivity(ref);
        }
      });
    });
  }

  Stream<ActivitySnapshot> getActivityChangeStream(ActivityReference ref) {
    assert(_trackedActivities.contains(ref));

    StreamController<ActivitySnapshot> parentController = _snapshotControllers[ref];
    StreamSubscription parentSubscription;

    StreamController<ActivitySnapshot> controller;
    controller = StreamController.broadcast(
        onListen: () {
          assert(parentController == null);

          if (_onlineStreamListenerCount == 0) _activityHandlers[ref].startListen();

          _onlineStreamListenerCount[ref]++;
          parentSubscription = parentController.stream.listen((event) {
            controller.add(event);
          });
        },
        onCancel: () {
          assert(parentController != null);

          _onlineStreamListenerCount[ref]--;
          parentSubscription.cancel();
          parentSubscription = null;

          if (_onlineStreamListenerCount == 0) _activityHandlers[ref].stopListen();
        }
    );

    return controller.stream;
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

    StreamController<ActivitySnapshot> controller = StreamController.broadcast();

    _onlineStreamListenerCount[ref] = 0;
    _snapshotControllers[ref] = controller;
    handler.addListener(() {
      _snapshotControllers[ref].add(handler.latestSnapshot);
    });

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

    _onlineStreamListenerCount.remove(ref);

    _previews.remove(ref);
    _globalPreviews.remove(ref);
    _onPreviewsChange();
  }

  void _updatePreview(ActivityReference ref) {
    _previews[ref] = _activityHandlers[ref].getCurrentPreview(_globalPreviews[ref]);
    _onPreviewsChange();
  }

  void _onPreviewsChange() {
    _previewsController.add(previews);
  }
}
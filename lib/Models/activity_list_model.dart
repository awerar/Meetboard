import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity_preview.dart';
import 'package:meetboard/Models/user_model.dart';
import 'package:meetboard/Models/activity.dart';

class ActivityListModel extends ChangeNotifier {
  final UserModel _userModel;

  bool _isLoadingPreviews = true;
  final Map<String, ActivityPreview> _activityPreviews = {};
  List<ValueReference<ActivityPreview>> _activityPreviewList = [];
  StreamSubscription _previewListener;

  final Map<String, StreamSubscription> _activityListeners = {};
  final Map<String, Activity> _latestActivitySnapshot = {};
  final Set<String> _activitiesListening = new Set();

  List<ValueReference<ActivityPreview>> get activityPreviews => _activityPreviewList;
  bool get isLoadingPreviews => _isLoadingPreviews;

  ActivityListModel(this._userModel) {
    _userModel.addListener(
      () {
        _activityPreviews.clear();
        _previewListener?.cancel();
        _previewListener = null;
        
        if (_userModel.user != null)  {
          _isLoadingPreviews = true;
          onActivityPreviewsChanged();

          Stream<QuerySnapshot> stream = _userModel.userActivityCollection.snapshots();
          _previewListener = stream.listen((snapshot) {
            _activityPreviews.clear();
            _activityPreviews.addEntries(snapshot.documents.map((doc) => MapEntry<String, ActivityPreview>(doc.documentID, ActivityPreview.fromDocument(doc))));
            if (_isLoadingPreviews) _isLoadingPreviews = false;
            onActivityPreviewsChanged();
          });
        } else onActivityPreviewsChanged();
      },
    );
  }

  void createActivity(ActivityPreview activity) async {
    if (activity.id == null || activity.id == "") {
      final String documentID = (await CloudFunctions.instance.getHttpsCallable(functionName: "createActivity").call(activity.encode())).data;
      activity = activity.copyWith(id: documentID);
    } else {
      _userModel.userActivityCollection.document(activity.id).setData(activity.encode());
    }

    _activityPreviews[activity.id] = activity;
    onActivityPreviewsChanged();
  }
  
  void onActivityPreviewsChanged() {
    List<ActivityPreview> previewList = _activityPreviews.values.toList(growable: false);
    previewList.sort((a, b) => a.time.millisecondsSinceEpoch - b.time.millisecondsSinceEpoch);
    _activityPreviewList = List.unmodifiable(previewList.map((v) => ValueReference(getter: () => _activityPreviews[v.id])));
    notifyListeners();
  }

  ValueReference<ActivityPreview> getActivityPreview(String id) {
    return ValueReference<ActivityPreview>(getter: () {
      return _activityPreviews[id];
    });
  }

  //Make sure the activity gets updated when the activity document gets updated
  Future<ValueReference<Activity>> beginListenForActivity(String id) async {
    _activitiesListening.add(id);

    if (!_activityListeners.values.contains(id)) {
      DocumentReference activityDoc = Firestore.instance.collection("activities").document(id);
      bool loadedOnce = false;
      _activityListeners[id] = activityDoc.snapshots().listen((snapshot) async {
        _latestActivitySnapshot[id] = await Activity.fromSnapshot(snapshot);
        loadedOnce = true;
        notifyListeners();

        if (!_activitiesListening.contains(id)) {
          _activityListeners[id].cancel();
          _activityListeners.remove(id);
        }
      });

      await Future.doWhile(() {
        return !loadedOnce;
      });
    }
    
    return ValueReference(getter: () {
      return _latestActivitySnapshot[id];
    });
  }

  void endListenForActivity(String id) {
    _activitiesListening.remove(id);
  }

  void updateActivity(Activity activity) async {
    await Firestore.instance.collection("activities").document(activity.id).updateData(activity.encode());
  }
}

class ValueReference<T> {
  T Function() _getValue;

  ValueReference({@required T Function() getter}) {
    _getValue = getter;
  }

  T get value {
   try {
     return _getValue();
   } catch(e) {
     return null;
   }
  }
}
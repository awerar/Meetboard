import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity_preview.dart';
import 'package:meetboard/Models/user_model.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:provider/provider.dart';

class ActivityListModel extends ChangeNotifier {
  final UserModel _userModel;

  bool _isLoadingPreviews = true;
  final Map<String, ActivityPreview> _activityPreviews = {};
  List<ValueReference<ActivityPreview>> _activityPreviewList = [];
  StreamSubscription _previewListener;

  final Map<String, StreamSubscription> _activityListeners = {};
  final Map<String, Activity> _latestActivitySnapshot = {};
  final Set<String> _activitiesListening = new Set();
  final Map<String, void Function()> _onActivityRemovedWhileListening = {};

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

  Future<Activity> createActivity({@required String name, @required DateTime time}) async {
    UserActivityData user = UserActivityData(
      coming: true,
      uid: _userModel.user.uid,
      role: ActivityRole.Owner
    );

    Activity activity = Activity(name: name, time: time, id: "", users: {
      user.uid:user
    });

    final String documentID = (await CloudFunctions.instance.getHttpsCallable(functionName: "createActivity").call({
      "name":activity.name,
      "time":activity.time.millisecondsSinceEpoch
    })).data;
    activity = activity.copyWith(id: documentID);

    return activity;
  }

  void onActivityPreviewsChanged() {
    List<ActivityPreview> previewList = _activityPreviews.values.toList();
    previewList.sort((a, b) => a.time.millisecondsSinceEpoch - b.time.millisecondsSinceEpoch);
    _activityPreviewList = List.unmodifiable(previewList.map((v) => ValueReference(getter: () => _activityPreviews[v.id])));
    notifyListeners();

    //Stop listening for all activities removed
    _activityListeners.keys.toList(growable: false).where((id) => previewList.where((preview) => preview.id == id).length == 0).forEach((id) {
      _activityListeners[id].cancel();
      _activityListeners.remove(id);

      if (_activitiesListening.contains(id)) {
        _activitiesListening.remove(id);

        if (_onActivityRemovedWhileListening.containsKey(id)) {
          _onActivityRemovedWhileListening[id]();
          _onActivityRemovedWhileListening.remove(id);
        }
      }
    });
  }

  ValueReference<ActivityPreview> getActivityPreview(String id) {
    return ValueReference<ActivityPreview>(getter: () {
      return _activityPreviews[id];
    });
  }

  //Make sure the activity gets updated when the activity document gets updated
  Future<ValueReference<Activity>> beginListenForActivity(String id, {void Function() onActivityRemoved}) async {
    _activitiesListening.add(id);

    //Manage callback
    if (onActivityRemoved != null) {
      if (_onActivityRemovedWhileListening.containsKey(id)) {
        void Function() prevCallBack = _onActivityRemovedWhileListening[id];
        _onActivityRemovedWhileListening[id] = () {
          prevCallBack();
          onActivityRemoved();
        };
      } else _onActivityRemovedWhileListening[id] = onActivityRemoved;
    }

    if (!_activityListeners.values.contains(id)) {
      DocumentReference activityDoc = Firestore.instance.collection("activities").document(id);

      //Map convert document data to activity
      Stream<Activity> activityStream = activityDoc.snapshots().map((snapshot) => Activity.fromSnapshot(snapshot));

      //Listen for activities and update state
      _activityListeners[id] = activityStream.listen((activity) {
        _latestActivitySnapshot[id] = activity;
        notifyListeners();

        if (!_activitiesListening.contains(id)) {
          _activityListeners[id].cancel();
          _activityListeners.remove(id);
        }
      });

      //Wait for initial activity
      await activityStream.first;
    }

    return ValueReference(getter: () {
      return _latestActivitySnapshot[id];
    });
  }

  void endListenForActivity(String id) {
    _activitiesListening.remove(id);
    _onActivityRemovedWhileListening.remove(id);
  }

  Future<void> updateActivity(Activity activity) async {
    await Firestore.instance.collection("activities").document(activity.id).updateData(activity.encode());
  }

  void updateUserData(Map<String, dynamic> updateData, String activityID) {
    DocumentReference docRef = Firestore.instance.collection("activities").document(activityID).collection("users").document(_userModel.user.uid);
    docRef.updateData(updateData);
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
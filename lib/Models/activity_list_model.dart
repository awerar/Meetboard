import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:meetboard/Models/user_model.dart';
import 'package:provider/provider.dart';

class ActivityListModel extends ChangeNotifier {
  final UserModel _userModel;
  bool _isLoading = true;
  final Map<String, Activity> _activities = {};
  List<Activity> _activityList = [];

  List<Activity> get activities => _activityList;
  bool get isLoading => _isLoading;

  ActivityListModel(this._userModel) {
    _userModel.addListener(
      () async {
        _activities.clear();
        _isLoading = true;
        onActivitiesChanged();
        
        if (_userModel.user != null)  {
          final query = await _userModel.userDocument.collection("Activities").getDocuments();
          _activities.addEntries(query.documents.map((doc) => MapEntry<String, Activity>(doc.documentID, Activity.fromDocument(doc))));
        }

        _isLoading = false;
        onActivitiesChanged();
      },
    );
  }

  void addActivity(Activity activity) async {
    final document = await _userModel.userDocument.collection("Activities").add(activity.encode());
    activity = activity.copyWith(id: document.documentID);

    _activities[activity.id] = activity;
    onActivitiesChanged();
  }
  
  void updateActivity(Activity activity) {
    _userModel.userDocument.collection("Activities").document(activity.id).updateData(activity.encode());
    _activities[activity.id] = activity;
    onActivitiesChanged();
  }
  
  void onActivitiesChanged() {
    List<Activity> activityList = _activities.values.toList(growable: false);
    activityList.sort((a, b) => a.time.millisecondsSinceEpoch - b.time.millisecondsSinceEpoch);
    _activityList = List<Activity>.unmodifiable(activityList);
    notifyListeners();
  }

  Activity getActivity(String id) {
    return _activities[id];
  }
}

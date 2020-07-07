import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/user_activity.dart';
import 'package:meetboard/Models/user_model.dart';
import 'package:provider/provider.dart';

class UserActivityListModel extends ChangeNotifier {
  final UserModel _userModel;
  bool _isLoading = true;
  final Map<String, UserActivity> _activities = {};
  List<UserActivity> _activityList = [];

  List<UserActivity> get activities => _activityList;
  bool get isLoading => _isLoading;

  UserActivityListModel(this._userModel) {
    _userModel.addListener(
      () async {
        _activities.clear();
        _isLoading = true;
        onActivitiesChanged();
        
        if (_userModel.user != null)  {
          final query = await _userModel.userDocument.collection("Activities").getDocuments();
          _activities.addEntries(query.documents.map((doc) => MapEntry<String, UserActivity>(doc.documentID, UserActivity.fromDocument(doc))));
        }

        _isLoading = false;
        onActivitiesChanged();
      },
    );
  }

  void addActivity(UserActivity activity) async {
    final document = await _userModel.userDocument.collection("Activities").add(activity.encode());
    activity = activity.copyWith(id: document.documentID);

    _activities[activity.id] = activity;
    onActivitiesChanged();
  }
  
  void updateActivity(UserActivity activity) {
    _userModel.userDocument.collection("Activities").document(activity.id).updateData(activity.encode());
    _activities[activity.id] = activity;
    onActivitiesChanged();
  }
  
  void onActivitiesChanged() {
    List<UserActivity> activityList = _activities.values.toList(growable: false);
    activityList.sort((a, b) => a.time.millisecondsSinceEpoch - b.time.millisecondsSinceEpoch);
    _activityList = List<UserActivity>.unmodifiable(activityList);
    notifyListeners();
  }

  UserActivity getActivity(String id) {
    return _activities[id];
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/user_data_snapshot.dart';
import 'package:meetboard/Models/user_model.dart';

class ActivitySnapshot {
  final ActivityReference ref;

  final String name;
  final DateTime time;
  final Map<String, UserDataSnapshot> users;

  UserDataSnapshot get currentUser => users[UserModel.instance.user.uid];

  ActivitySnapshot({@required this.ref, @required this.name, @required this.time, @required List<UserDataSnapshot> users}) : this.users = Map.fromIterable(users, key: (u) => u.uid);

  static ActivitySnapshot fromData(ActivityReference ref, Map<String, dynamic> data) {
    return ActivitySnapshot(
      ref: ref,
      name: data["name"],
      time: (data["time"] as Timestamp).toDate(),
      users: _parseUsers(data["users"])
    );
  }

  static List<UserDataSnapshot> _parseUsers(dynamic userData) {
    return Map<String, dynamic>.from(userData)
        .map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)))
        .entries.map((e) => UserDataSnapshot.fromData(e.key, e.value)).toList();
  }
}